import 'package:pub_semver/pub_semver.dart';

class AndroidSnapshot {
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

  final Version? gradleVersion;
  final Version? agpVersion;
  final Version? kotlinVersion;
  final int? compileSdk;
  final int? minSdk;
  final int? targetSdk;
  final bool usesLegacyFlutterGradleApply;
  final bool hasFlutterPluginsFile;
  final bool usesAndroidV1Embedding;
  final bool usesPluginDsl;

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
