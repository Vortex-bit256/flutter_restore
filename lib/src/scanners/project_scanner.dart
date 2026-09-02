import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'package:flutter_restore/src/models/android_snapshot.dart';
import 'package:flutter_restore/src/models/platform_snapshot.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';
import 'package:flutter_restore/src/scanners/ios_scanner.dart';

/// Reads a Flutter project from disk and builds a static compatibility snapshot.
class ProjectScanner {
  /// Scans [rootPath] without invoking Flutter, Gradle, or platform tooling.
  ProjectSnapshot scan(String rootPath) {
    final normalizedRoot = p.normalize(Directory(rootPath).absolute.path);
    final pubspecFile = File(p.join(normalizedRoot, 'pubspec.yaml'));
    final lockFile = File(p.join(normalizedRoot, 'pubspec.lock'));
    final metadataFile = File(p.join(normalizedRoot, '.metadata'));

    return ProjectSnapshot(
      rootPath: normalizedRoot,
      hasPubspec: pubspecFile.existsSync(),
      hasPubspecLock: lockFile.existsSync(),
      hasMetadata: metadataFile.existsSync(),
      pubspecName: _readPubspecName(pubspecFile),
      flutterRevision: _readFlutterRevision(metadataFile),
      android: _AndroidScanner(normalizedRoot).scan(),
      ios: IosScanner(normalizedRoot).scan(),
      linux: _PlatformScanner(
        normalizedRoot,
        name: 'linux',
        expectedFiles: const [
          'linux/CMakeLists.txt',
          'linux/runner/CMakeLists.txt',
          'linux/runner/main.cc',
          'linux/runner/my_application.cc',
        ],
        desktopOverride: _scanLegacyTargetPlatformOverride(normalizedRoot),
      ).scan(),
      windows: _PlatformScanner(
        normalizedRoot,
        name: 'windows',
        expectedFiles: const [
          'windows/CMakeLists.txt',
          'windows/runner/CMakeLists.txt',
          'windows/runner/main.cpp',
          'windows/runner/flutter_window.cpp',
          'windows/runner/Runner.rc',
          'windows/runner/win32_window.cpp',
        ],
        desktopOverride: _scanLegacyTargetPlatformOverride(normalizedRoot),
      ).scan(),
      web: _PlatformScanner(
        normalizedRoot,
        name: 'web',
        expectedFiles: const [
          'web/index.html',
          'web/manifest.json',
          'web/favicon.png',
        ],
      ).scan(),
    );
  }

  String? _readPubspecName(File pubspecFile) {
    if (!pubspecFile.existsSync()) {
      return null;
    }
    final document = loadYaml(pubspecFile.readAsStringSync());
    if (document is YamlMap) {
      return document['name']?.toString();
    }
    return null;
  }

  String? _readFlutterRevision(File metadataFile) {
    if (!metadataFile.existsSync()) {
      return null;
    }
    final document = loadYaml(metadataFile.readAsStringSync());
    if (document is! YamlMap) {
      return null;
    }
    final version = document['version'];
    if (version is YamlMap) {
      return version['revision']?.toString();
    }
    return null;
  }

  _SourceSignal? _scanLegacyTargetPlatformOverride(String rootPath) {
    final libDir = Directory(p.join(rootPath, 'lib'));
    if (!libDir.existsSync()) {
      return null;
    }
    for (final file in libDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final scanned = _ScannedText(
        sourceFile: p.relative(file.path, from: rootPath),
        text: file.readAsStringSync(),
      );
      final line = scanned.lineOf(
        RegExp(
          r'debugDefaultTargetPlatformOverride\s*=\s*TargetPlatform\.fuchsia',
        ),
      );
      if (line != null) {
        return _SourceSignal(sourceFile: scanned.sourceFile, line: line);
      }
    }
    return null;
  }
}

class _PlatformScanner {
  _PlatformScanner(
    this.rootPath, {
    required this.name,
    required this.expectedFiles,
    this.desktopOverride,
  });

  final String rootPath;
  final String name;
  final List<String> expectedFiles;
  final _SourceSignal? desktopOverride;

  PlatformSnapshot scan() {
    final hasDirectory = Directory(p.join(rootPath, name)).existsSync();
    final detectedFiles = [
      for (final relativePath in expectedFiles)
        if (File(p.join(rootPath, relativePath)).existsSync()) relativePath,
    ];
    final cmake = _readRelative('$name/CMakeLists.txt');
    final runnerCmake = _readRelative('$name/runner/CMakeLists.txt');
    final cmakeMinimum = _cmakeMinimumVersion(cmake);
    final indexHtml = _readRelative('web/index.html');
    final customBootstrap = _readRelative('web/flutter_bootstrap.js');
    final windowsRunnerRc = _readRelative('windows/runner/Runner.rc');
    final windowsFlutterWindow = _readRelative(
      'windows/runner/flutter_window.cpp',
    );
    final legacyRunLoop = _legacyWindowsRunLoop();

    return PlatformSnapshot(
      name: name,
      hasDirectory: hasDirectory,
      detectedFiles: detectedFiles,
      missingExpectedFiles: [
        for (final relativePath in expectedFiles)
          if (!detectedFiles.contains(relativePath)) relativePath,
      ],
      cmakeMinimumVersion: cmakeMinimum,
      cmakeMinimumVersionSourceFile: cmakeMinimum == null
          ? null
          : cmake.sourceFile,
      cmakeMinimumVersionLine: cmakeMinimum == null
          ? null
          : cmake.lineOf(RegExp(r'\bcmake_minimum_required\b')),
      hasGtkPkgConfig: _hasGtkPkgConfig([cmake, runnerCmake]),
      usesLegacyWindowsRunLoop: legacyRunLoop != null,
      legacyWindowsRunLoopSourceFile: legacyRunLoop?.sourceFile,
      legacyWindowsRunLoopLine: legacyRunLoop?.line,
      supportsWindowsDarkTitleBar: _supportsWindowsDarkTitleBar(),
      supportsWindowsVersionInfo: _supportsWindowsVersionInfo(windowsRunnerRc),
      hasWindowsForceRedraw: windowsFlutterWindow.text.contains(
        'ForceRedraw()',
      ),
      usesLegacyTargetPlatformOverride: desktopOverride != null,
      legacyTargetPlatformOverrideSourceFile: desktopOverride?.sourceFile,
      legacyTargetPlatformOverrideLine: desktopOverride?.line,
      webHasBootstrap: _hasWebBootstrap(indexHtml),
      webHasBaseHref: RegExp(
        r'''<base\s+[^>]*href\s*='[^']+'|<base\s+[^>]*href\s*="[^"]+"''',
        caseSensitive: false,
      ).hasMatch(indexHtml.text),
      webUsesDeprecatedServiceWorkerVersion: RegExp(
        r'\b(?:const|var|let)\s+serviceWorkerVersion\s*=',
      ).hasMatch(indexHtml.text),
      webDeprecatedServiceWorkerVersionLine: indexHtml.lineOf(
        RegExp(r'\b(?:const|var|let)\s+serviceWorkerVersion\s*='),
      ),
      webManuallyRegistersServiceWorker: indexHtml.text.contains(
        'navigator.serviceWorker.register',
      ),
      webManualServiceWorkerRegistrationLine: indexHtml.lineOf(
        RegExp(r'navigator\.serviceWorker\.register'),
      ),
      webUsesLegacyLoadEntrypoint: indexHtml.text.contains(
        '_flutter.loader.loadEntrypoint',
      ),
      webLegacyLoadEntrypointLine: indexHtml.lineOf(
        RegExp(r'_flutter\.loader\.loadEntrypoint'),
      ),
      webHasCustomBootstrap: customBootstrap.exists,
      webCustomBootstrapHasFlutterJsToken: customBootstrap.text.contains(
        '{{flutter_js}}',
      ),
      webCustomBootstrapHasBuildConfigToken: customBootstrap.text.contains(
        '{{flutter_build_config}}',
      ),
      webCustomBootstrapCallsLoaderLoad: customBootstrap.text.contains(
        '_flutter.loader.load(',
      ),
    );
  }

  _ScannedText _readRelative(String relativePath) {
    final file = File(p.join(rootPath, relativePath));
    return _ScannedText(
      sourceFile: relativePath,
      exists: file.existsSync(),
      text: file.existsSync() ? file.readAsStringSync() : '',
    );
  }

  Version? _cmakeMinimumVersion(_ScannedText cmake) {
    return _parseVersion(
      RegExp(
        r'\bcmake_minimum_required\s*\(\s*VERSION\s+([0-9]+(?:\.[0-9]+){1,2})',
        caseSensitive: false,
      ).firstMatch(cmake.text)?.group(1),
    );
  }

  bool _hasGtkPkgConfig(List<_ScannedText> cmakeFiles) {
    return RegExp(
      r'pkg_check_modules\s*\(\s*GTK\s+REQUIRED\b',
      caseSensitive: false,
    ).hasMatch(cmakeFiles.map((file) => file.text).join('\n'));
  }

  _SourceSignal? _legacyWindowsRunLoop() {
    final runLoopHeader = File(p.join(rootPath, 'windows/runner/run_loop.h'));
    if (runLoopHeader.existsSync()) {
      return const _SourceSignal(
        sourceFile: 'windows/runner/run_loop.h',
        line: 1,
      );
    }
    final flutterWindow = _readRelative('windows/runner/flutter_window.cpp');
    final line = flutterWindow.lineOf(RegExp(r'\bRunLoop::'));
    return line == null
        ? null
        : _SourceSignal(sourceFile: flutterWindow.sourceFile, line: line);
  }

  bool _supportsWindowsDarkTitleBar() {
    final win32Window = _readRelative('windows/runner/win32_window.cpp');
    final runnerCmake = _readRelative('windows/runner/CMakeLists.txt');
    return win32Window.text.contains('DWMWA_USE_IMMERSIVE_DARK_MODE') ||
        win32Window.text.contains('DwmSetWindowAttribute') ||
        runnerCmake.text.contains('dwmapi.lib');
  }

  bool _supportsWindowsVersionInfo(_ScannedText runnerRc) {
    return runnerRc.text.contains('FLUTTER_VERSION') ||
        runnerRc.text.contains('FLUTTER_BUILD_NAME') ||
        runnerRc.text.contains('FLUTTER_BUILD_NUMBER');
  }

  bool _hasWebBootstrap(_ScannedText indexHtml) {
    return indexHtml.text.contains('flutter_bootstrap.js') ||
        indexHtml.text.contains('{{flutter_bootstrap_js}}') ||
        indexHtml.text.contains('{{flutter_js}}') ||
        indexHtml.text.contains('_flutter.loader.load(');
  }

  Version? _parseVersion(String? value) {
    if (value == null) {
      return null;
    }
    final parts = value.split('.');
    final normalized = parts.length == 2 ? '$value.0' : value;
    return Version.parse(normalized);
  }
}

class _AndroidScanner {
  _AndroidScanner(this.rootPath);

  final String rootPath;

  AndroidSnapshot scan() {
    final androidPath = p.join(rootPath, 'android');
    final androidDir = Directory(androidPath);
    if (!androidDir.existsSync()) {
      return AndroidSnapshot(
        hasFlutterPluginsFile: File(
          p.join(rootPath, '.flutter-plugins'),
        ).existsSync(),
      );
    }

    final gradleWrapper = _readIfExists(
      p.join(androidPath, 'gradle', 'wrapper', 'gradle-wrapper.properties'),
    );
    final rootGradle = _readIfExists(p.join(androidPath, 'build.gradle'));
    final settingsGradle = _readIfExists(
      p.join(androidPath, 'settings.gradle'),
    );
    final appGradle = _readIfExists(p.join(androidPath, 'app', 'build.gradle'));
    final allGradleText = [rootGradle, settingsGradle, appGradle].join('\n');

    return AndroidSnapshot(
      gradleVersion: _parseVersion(
        _firstMatch(
          gradleWrapper,
          RegExp(r'gradle-([0-9]+(?:\.[0-9]+){1,2})-(?:all|bin)\.zip'),
        ),
      ),
      agpVersion: _parseVersion(
        _firstMatch(
          allGradleText,
          RegExp(
            r'''(?:com\.android\.tools\.build:gradle:|id\s+['"]com\.android\.(?:application|library)['"]\s+version\s+['"])([0-9]+(?:\.[0-9]+){1,2})''',
          ),
        ),
      ),
      kotlinVersion: _parseVersion(
        _firstMatch(
          allGradleText,
          RegExp(
            r'''(?:kotlin_version\s*=\s*['"]|kotlin-gradle-plugin:|id\s+['"]org\.jetbrains\.kotlin\.android['"]\s+version\s+['"])([0-9]+(?:\.[0-9]+){1,2})''',
          ),
        ),
      ),
      compileSdk: _parseInt(
        _firstMatch(
          appGradle,
          RegExp(r'\bcompileSdk(?:Version)?\s*(?:=|\s)\s*([0-9]+)'),
        ),
      ),
      minSdk: _parseInt(
        _firstMatch(
          appGradle,
          RegExp(r'\bminSdk(?:Version)?\s*(?:=|\s)\s*([0-9]+)'),
        ),
      ),
      targetSdk: _parseInt(
        _firstMatch(
          appGradle,
          RegExp(r'\btargetSdk(?:Version)?\s*(?:=|\s)\s*([0-9]+)'),
        ),
      ),
      usesLegacyFlutterGradleApply: allGradleText.contains(
        'packages/flutter_tools/gradle/flutter.gradle',
      ),
      hasFlutterPluginsFile: File(
        p.join(rootPath, '.flutter-plugins'),
      ).existsSync(),
      usesAndroidV1Embedding: _detectAndroidV1Embedding(androidDir),
      usesPluginDsl: RegExp(
        r'^\s*plugins\s*\{',
        multiLine: true,
      ).hasMatch(allGradleText),
    );
  }

  bool _detectAndroidV1Embedding(Directory androidDir) {
    return androidDir
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) => file.path.endsWith('.java') || file.path.endsWith('.kt'),
        )
        .any(
          (file) => file.readAsStringSync().contains(
            'io.flutter.app.FlutterActivity',
          ),
        );
  }

  String _readIfExists(String path) {
    final file = File(path);
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  String? _firstMatch(String text, RegExp expression) {
    return expression.firstMatch(text)?.group(1);
  }

  Version? _parseVersion(String? value) {
    if (value == null) {
      return null;
    }
    final parts = value.split('.');
    final normalized = parts.length == 2 ? '$value.0' : value;
    return Version.parse(normalized);
  }

  int? _parseInt(String? value) => value == null ? null : int.parse(value);
}

class _SourceSignal {
  const _SourceSignal({required this.sourceFile, required this.line});

  final String sourceFile;
  final int line;
}

class _ScannedText {
  const _ScannedText({
    required this.sourceFile,
    this.exists = false,
    this.text = '',
  });

  final String sourceFile;
  final bool exists;
  final String text;

  int? lineOf(RegExp expression) {
    final lines = text.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (expression.hasMatch(lines[i])) {
        return i + 1;
      }
    }
    return null;
  }
}
