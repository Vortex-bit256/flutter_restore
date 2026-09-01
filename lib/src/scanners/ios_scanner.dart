import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'package:flutter_restore/src/models/ios_snapshot.dart';

/// Reads iOS runner files and produces an [IosSnapshot].
class IosScanner {
  /// Creates an iOS scanner rooted at [rootPath].
  IosScanner(this.rootPath);

  /// Path to the Flutter project being scanned.
  final String rootPath;

  static const _pbxprojPath = 'ios/Runner.xcodeproj/project.pbxproj';
  static const _podfilePath = 'ios/Podfile';
  static const _podfileLockPath = 'ios/Podfile.lock';
  static const _infoPlistPath = 'ios/Runner/Info.plist';
  static const _swiftAppDelegatePath = 'ios/Runner/AppDelegate.swift';
  static const _objcAppDelegatePath = 'ios/Runner/AppDelegate.m';

  /// Scans iOS files without invoking Xcode or CocoaPods.
  IosSnapshot scan() {
    final iosDir = Directory(p.join(rootPath, 'ios'));
    if (!iosDir.existsSync()) {
      return const IosSnapshot();
    }

    final podfile = _readRelative(_podfilePath);
    final podfileLock = _readRelative(_podfileLockPath);
    final pbxproj = _readRelative(_pbxprojPath);
    final infoPlist = _readRelative(_infoPlistPath);
    final swiftAppDelegate = _readRelative(_swiftAppDelegatePath);
    final objcAppDelegate = _readRelative(_objcAppDelegatePath);
    final xcconfigs = _readFlutterXcconfigs();
    final podspecTargets = _scanPodspecTargets();
    final swiftPackageTargets = _scanSwiftPackageTargets();

    final buildTargets = _parseBuildConfigurationTargets(pbxproj);
    final usesSwiftPM =
        _hasSwiftPMReferences(pbxproj) || swiftPackageTargets.isNotEmpty;
    final usesCocoaPods = podfile.exists || podfileLock.exists;
    final appDelegate = _scanAppDelegate(swiftAppDelegate, objcAppDelegate);
    final hasSceneManifest = infoPlist.text.contains(
      '<key>UIApplicationSceneManifest</key>',
    );
    final hasSceneConfiguration =
        infoPlist.text.contains('<key>UISceneConfigurations</key>') &&
        infoPlist.text.contains('<key>UISceneConfigurationName</key>');

    return IosSnapshot(
      deploymentTarget: _lowestTarget(buildTargets),
      podfilePlatformTarget: _parsePodfilePlatformTarget(podfile),
      podfilePlatformLine: _podfilePlatformLine(podfile),
      deploymentTargetsByConfiguration: buildTargets,
      usesCocoaPods: usesCocoaPods,
      usesSwiftPM: usesSwiftPM,
      usesMixedDependencyManagement: usesCocoaPods && usesSwiftPM,
      hasPodfile: podfile.exists,
      hasPodfileLock: podfileLock.exists,
      swiftPackageManagerDisabled: _swiftPackageManagerDisabled([
        podfile.text,
        pbxproj.text,
        ...xcconfigs.map((file) => file.text),
      ]),
      uisceneLifecycleStatus: !hasSceneManifest
          ? UISceneLifecycleStatus.absent
          : hasSceneConfiguration
          ? UISceneLifecycleStatus.complete
          : UISceneLifecycleStatus.incomplete,
      appDelegateLifecycleStyle: appDelegate.sourceFile == null
          ? AppDelegateLifecycleStyle.absent
          : hasSceneManifest
          ? AppDelegateLifecycleStyle.sceneBased
          : AppDelegateLifecycleStyle.appDelegateOnly,
      appDelegate: appDelegate,
      nativePluginDeploymentTargets: [
        ...podspecTargets,
        ...swiftPackageTargets,
      ],
      legacyBuildSettings: _scanLegacyBuildSettings(pbxproj, xcconfigs),
      hasLegacyFlutterPodfileIntegration: _hasLegacyFlutterPodfileIntegration(
        podfile,
      ),
      hasPotentialCocoaPodsOnlyPlugins:
          podspecTargets.isNotEmpty && swiftPackageTargets.isEmpty,
      hasFlutterXcconfigReferences: _hasFlutterXcconfigReferences(
        pbxproj,
        xcconfigs,
      ),
      hasSuspiciousFlutterXcconfigReferences:
          !_hasFlutterXcconfigReferences(pbxproj, xcconfigs) ||
          _hasSuspiciousFlutterXcconfigs(xcconfigs),
      hasOldFlutterBuildScriptReferences: _hasOldFlutterBuildScripts(pbxproj),
      hasLegacyFlutterFrameworkEmbedding: _hasLegacyFrameworkEmbedding(pbxproj),
    );
  }

  _ScannedFile _readRelative(String relativePath) {
    final file = File(p.join(rootPath, relativePath));
    return _ScannedFile(
      relativePath: relativePath,
      exists: file.existsSync(),
      text: file.existsSync() ? file.readAsStringSync() : '',
    );
  }

  List<_ScannedFile> _readFlutterXcconfigs() {
    final dir = Directory(p.join(rootPath, 'ios', 'Flutter'));
    if (!dir.existsSync()) {
      return const [];
    }
    return dir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.xcconfig'))
        .map((file) {
          final relativePath = p.relative(file.path, from: rootPath);
          return _ScannedFile(
            relativePath: relativePath,
            exists: true,
            text: file.readAsStringSync(),
          );
        })
        .toList();
  }

  List<IosBuildConfigurationDeploymentTarget> _parseBuildConfigurationTargets(
    _ScannedFile pbxproj,
  ) {
    if (!pbxproj.exists) {
      return const [];
    }
    final entries = <IosBuildConfigurationDeploymentTarget>[];
    final lines = pbxproj.lines;

    var inConfig = false;
    var depth = 0;
    String? name;
    Version? target;
    int? targetLine;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!inConfig && line.contains('isa = XCBuildConfiguration;')) {
        inConfig = true;
        depth = 1;
        name = null;
        target = null;
        targetLine = null;
      }
      if (!inConfig) {
        continue;
      }

      final targetMatch = RegExp(
        r'IPHONEOS_DEPLOYMENT_TARGET\s*=\s*"?([^";]+)"?;',
      ).firstMatch(line);
      if (targetMatch != null) {
        target = _parseVersion(targetMatch.group(1));
        targetLine = i + 1;
      }

      final nameMatch = RegExp(r'name\s*=\s*"?([^";]+)"?;').firstMatch(line);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim();
      }

      depth += '{'.allMatches(line).length;
      depth -= '}'.allMatches(line).length;
      if (depth <= 0) {
        if (target != null) {
          entries.add(
            IosBuildConfigurationDeploymentTarget(
              configuration: name ?? 'unknown',
              target: target,
              sourceFile: pbxproj.relativePath,
              line: targetLine,
            ),
          );
        }
        inConfig = false;
      }
    }

    return entries;
  }

  Version? _parsePodfilePlatformTarget(_ScannedFile podfile) {
    if (!podfile.exists) {
      return null;
    }
    return _parseVersion(
      RegExp(
        r'''^\s*platform\s+:ios\s*,\s*['"]([^'"]+)['"]''',
        multiLine: true,
      ).firstMatch(podfile.text)?.group(1),
    );
  }

  int? _podfilePlatformLine(_ScannedFile podfile) {
    if (!podfile.exists) {
      return null;
    }
    return podfile.lineOf(
      RegExp(r'''^\s*platform\s+:ios\s*,\s*['"]([^'"]+)['"]'''),
    );
  }

  List<IosPluginDeploymentTarget> _scanPodspecTargets() {
    final iosDir = Directory(p.join(rootPath, 'ios'));
    if (!iosDir.existsSync()) {
      return const [];
    }
    final targets = <IosPluginDeploymentTarget>[];
    for (final file in iosDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.podspec')) {
        continue;
      }
      final relativePath = p.relative(file.path, from: rootPath);
      final scanned = _ScannedFile(
        relativePath: relativePath,
        exists: true,
        text: file.readAsStringSync(),
      );
      for (var i = 0; i < scanned.lines.length; i++) {
        final match = RegExp(
          r'''ios\.deployment_target\s*=\s*['"]([^'"]+)['"]''',
        ).firstMatch(scanned.lines[i]);
        final target = _parseVersion(match?.group(1));
        if (target != null) {
          targets.add(
            IosPluginDeploymentTarget(
              name: p.basenameWithoutExtension(file.path),
              target: target,
              sourceFile: relativePath,
              sourceKind: 'podspec',
              line: i + 1,
            ),
          );
        }
      }
    }
    return targets;
  }

  List<IosPluginDeploymentTarget> _scanSwiftPackageTargets() {
    final targets = <IosPluginDeploymentTarget>[];
    for (final file in Directory(
      rootPath,
    ).listSync(recursive: true).whereType<File>()) {
      final basename = p.basename(file.path);
      if (basename != 'Package.swift') {
        continue;
      }
      final relativePath = p.relative(file.path, from: rootPath);
      final scanned = _ScannedFile(
        relativePath: relativePath,
        exists: true,
        text: file.readAsStringSync(),
      );
      for (var i = 0; i < scanned.lines.length; i++) {
        final line = scanned.lines[i];
        final match = RegExp(
          r'''(?:\.iOS|\.ios)\s*\(\s*\.v([0-9]+(?:\.[0-9]+)?)\s*\)''',
        ).firstMatch(line);
        final target = _parseVersion(match?.group(1));
        if (target != null) {
          targets.add(
            IosPluginDeploymentTarget(
              name: p.basename(p.dirname(file.path)),
              target: target,
              sourceFile: relativePath,
              sourceKind: 'swiftpm',
              line: i + 1,
            ),
          );
        }
      }
    }
    return targets;
  }

  IosAppDelegateSnapshot _scanAppDelegate(
    _ScannedFile swiftAppDelegate,
    _ScannedFile objcAppDelegate,
  ) {
    final file = swiftAppDelegate.exists ? swiftAppDelegate : objcAppDelegate;
    if (!file.exists) {
      return const IosAppDelegateSnapshot();
    }
    final text = file.text;
    final didFinishLine = file.lineOf('didFinishLaunching');
    final registrantLine =
        file.lineOf('GeneratedPluginRegistrant.register') ??
        file.lineOf('GeneratedPluginRegistrant registerWithRegistry');
    final implicitDelegateLine = file.lineOf('FlutterImplicitEngineDelegate');
    final didInitializeLine = file.lineOf('didInitializeImplicitFlutterEngine');
    final legacyEngineLine =
        file.lineOf(RegExp(r'FlutterEngine\s*(?:\*|\()')) ??
        file.lineOf('runWithEntrypoint') ??
        file.lineOf('FlutterViewController');
    final customIntegrationLine = file.lineOf(
      RegExp(
        r'FlutterMethodChannel|FlutterEventChannel|registrar\(|registerViewFactory|addMethodCallDelegate|setMethodCallHandler',
      ),
    );

    return IosAppDelegateSnapshot(
      sourceFile: file.relativePath,
      didFinishLaunchingLine: didFinishLine,
      isCustom:
          customIntegrationLine != null ||
          implicitDelegateLine != null ||
          didInitializeLine != null ||
          legacyEngineLine != null,
      manualGeneratedPluginRegistrant: registrantLine != null,
      generatedPluginRegistrantLine: registrantLine,
      registersPluginsInDidFinishLaunching:
          registrantLine != null && didFinishLine != null,
      customPlatformIntegration: customIntegrationLine != null,
      customPlatformIntegrationLine: customIntegrationLine,
      usesFlutterImplicitEngineDelegate: implicitDelegateLine != null,
      flutterImplicitEngineDelegateLine: implicitDelegateLine,
      hasDidInitializeImplicitFlutterEngine: didInitializeLine != null,
      didInitializeImplicitFlutterEngineLine: didInitializeLine,
      usesLegacyFlutterEngineInitialization: legacyEngineLine != null,
      legacyFlutterEngineInitializationLine: legacyEngineLine,
      usesObjectiveCLegacyIntegration:
          file.relativePath.endsWith('.m') &&
          text.contains('@import Flutter') &&
          text.contains('GeneratedPluginRegistrant'),
    );
  }

  List<IosLegacyBuildSetting> _scanLegacyBuildSettings(
    _ScannedFile pbxproj,
    List<_ScannedFile> xcconfigs,
  ) {
    final settings = <IosLegacyBuildSetting>[];
    for (final file in [pbxproj, ...xcconfigs].where((file) => file.exists)) {
      for (var i = 0; i < file.lines.length; i++) {
        final match = RegExp(
          r'\b(VALID_ARCHS|ENABLE_BITCODE|ONLY_ACTIVE_ARCH|SWIFT_VERSION|ARCHS|EXCLUDED_ARCHS(?:\[[^\]]+\])?)\s*=\s*([^;]+);?',
        ).firstMatch(file.lines[i]);
        if (match == null) {
          continue;
        }
        final key = match.group(1)!.trim();
        final value = match.group(2)!.trim().replaceAll('"', '');
        if (key == 'SWIFT_VERSION' &&
            !value.startsWith('3') &&
            !value.startsWith('4')) {
          continue;
        }
        settings.add(
          IosLegacyBuildSetting(
            key: key,
            value: value,
            sourceFile: file.relativePath,
            line: i + 1,
          ),
        );
      }
    }
    return settings;
  }

  bool _hasSwiftPMReferences(_ScannedFile pbxproj) {
    return pbxproj.text.contains('XCRemoteSwiftPackageReference') ||
        pbxproj.text.contains('XCSwiftPackageProductDependency') ||
        File(p.join(rootPath, 'ios', 'Package.resolved')).existsSync() ||
        File(
          p.join(
            rootPath,
            'ios',
            'Runner.xcodeproj',
            'project.xcworkspace',
            'xcshareddata',
            'swiftpm',
            'Package.resolved',
          ),
        ).existsSync();
  }

  bool _swiftPackageManagerDisabled(List<String> texts) {
    return texts.any(
      (text) => RegExp(
        r'(--no-swift-package-manager|disable-swift-package-manager|SWIFT_PACKAGE_MANAGER_INTEGRATION\s*=\s*NO|FLUTTER_SWIFT_PACKAGE_MANAGER\s*=\s*(NO|false|0))',
        caseSensitive: false,
      ).hasMatch(text),
    );
  }

  bool _hasLegacyFlutterPodfileIntegration(_ScannedFile podfile) {
    if (!podfile.exists) {
      return false;
    }
    return RegExp(r'''pod\s+['"]Flutter['"]''').hasMatch(podfile.text) ||
        podfile.text.contains('.symlinks/flutter') ||
        podfile.text.contains('Flutter.framework');
  }

  bool _hasFlutterXcconfigReferences(
    _ScannedFile pbxproj,
    List<_ScannedFile> xcconfigs,
  ) {
    return pbxproj.text.contains('Generated.xcconfig') ||
        pbxproj.text.contains('Debug.xcconfig') ||
        pbxproj.text.contains('Release.xcconfig') ||
        xcconfigs.any((file) => file.text.contains('Generated.xcconfig'));
  }

  bool _hasSuspiciousFlutterXcconfigs(List<_ScannedFile> xcconfigs) {
    if (xcconfigs.isEmpty) {
      return true;
    }
    return xcconfigs.any(
      (file) =>
          file.relativePath.endsWith('Debug.xcconfig') &&
          !file.text.contains('Generated.xcconfig'),
    );
  }

  bool _hasOldFlutterBuildScripts(_ScannedFile pbxproj) {
    return pbxproj.text.contains('xcode_backend.sh\\" build') ||
        pbxproj.text.contains('xcode_backend.sh build') ||
        pbxproj.text.contains('xcode_backend.sh\\" thin') ||
        pbxproj.text.contains('xcode_backend.sh thin');
  }

  bool _hasLegacyFrameworkEmbedding(_ScannedFile pbxproj) {
    return pbxproj.text.contains('Flutter.framework') ||
        pbxproj.text.contains('App.framework');
  }

  Version? _lowestTarget(List<IosBuildConfigurationDeploymentTarget> targets) {
    if (targets.isEmpty) {
      return null;
    }
    return targets
        .map((target) => target.target)
        .reduce((a, b) => a < b ? a : b);
  }

  Version? _parseVersion(String? value) {
    if (value == null) {
      return null;
    }
    final clean = value.trim().replaceAll('"', '');
    if (clean.isEmpty) {
      return null;
    }
    final parts = clean.split('.');
    final normalized = switch (parts.length) {
      1 => '$clean.0.0',
      2 => '$clean.0',
      _ => clean,
    };
    try {
      return Version.parse(normalized);
    } on FormatException {
      return null;
    }
  }
}

class _ScannedFile {
  const _ScannedFile({
    required this.relativePath,
    required this.exists,
    required this.text,
  });

  final String relativePath;
  final bool exists;
  final String text;

  List<String> get lines => text.split('\n');

  int? lineOf(Object pattern) {
    final allLines = lines;
    for (var i = 0; i < allLines.length; i++) {
      final line = allLines[i];
      final found = switch (pattern) {
        String value => line.contains(value),
        RegExp value => value.hasMatch(line),
        _ => false,
      };
      if (found) {
        return i + 1;
      }
    }
    return null;
  }
}
