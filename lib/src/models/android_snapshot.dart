import 'package:pub_semver/pub_semver.dart';

/// Android-specific facts discovered from a Flutter project.
class AndroidSnapshot {
  /// Creates an Android project snapshot.
  const AndroidSnapshot({
    this.gradleVersion,
    this.agpVersion,
    this.kotlinVersion,
    this.compileSdk,
    this.minSdk,
    this.targetSdk,
    this.usesLegacyFlutterGradleApply = false,
    this.hasFlutterPluginsFile = false,
    this.usesAndroidV1Embedding = false,
    this.usesPluginDsl = false,
  });

  /// Gradle wrapper version, when a wrapper file is present.
  final Version? gradleVersion;

  /// Android Gradle Plugin version declared by the project.
  final Version? agpVersion;

  /// Kotlin Gradle Plugin version declared by the project.
  final Version? kotlinVersion;

  /// Android compile SDK value from the app Gradle file.
  final int? compileSdk;

  /// Android minimum SDK value from the app Gradle file.
  final int? minSdk;

  /// Android target SDK value from the app Gradle file.
  final int? targetSdk;

  /// Whether the project applies Flutter's old `flutter.gradle` script.
  final bool usesLegacyFlutterGradleApply;

  /// Whether a legacy `.flutter-plugins` file exists.
  final bool hasFlutterPluginsFile;

  /// Whether Android sources use the v1 Flutter embedding.
  final bool usesAndroidV1Embedding;

  /// Whether Gradle's `plugins {}` DSL is used.
  final bool usesPluginDsl;

  /// Converts this snapshot to the JSON report shape.
  Map<String, Object?> toJson() => {
    'gradleVersion': gradleVersion?.toString(),
    'agpVersion': agpVersion?.toString(),
    'kotlinVersion': kotlinVersion?.toString(),
    'compileSdk': compileSdk,
    'minSdk': minSdk,
    'targetSdk': targetSdk,
    'usesLegacyFlutterGradleApply': usesLegacyFlutterGradleApply,
    'hasFlutterPluginsFile': hasFlutterPluginsFile,
    'usesAndroidV1Embedding': usesAndroidV1Embedding,
    'usesPluginDsl': usesPluginDsl,
  };
}
