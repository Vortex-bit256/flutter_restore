import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import 'package:flutter_restore/src/models/android_snapshot.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';

class ProjectScanner {
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
