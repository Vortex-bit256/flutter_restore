import 'package:pub_semver/pub_semver.dart';

/// Supported Gradle version range for a line of Android Gradle Plugin releases.
class AgpGradleRange {
  /// Creates an AGP-to-Gradle compatibility range.
  const AgpGradleRange({
    required this.agp,
    required this.minGradle,
    required this.maxGradle,
  });

  /// AGP versions covered by this range.
  final VersionConstraint agp;

  /// Oldest Gradle version supported by the AGP range.
  final Version minGradle;

  /// Newest Gradle version supported by the AGP range.
  final Version maxGradle;
}

/// Minimum Java version required by an Android Gradle Plugin range.
class AgpJavaRequirement {
  /// Creates an AGP-to-Java requirement.
  const AgpJavaRequirement({required this.agp, required this.requiredJava});

  /// AGP versions covered by this requirement.
  final VersionConstraint agp;

  /// Minimum Java major version required by the AGP range.
  final int requiredJava;
}

/// Maximum compile SDK known to be supported by an AGP range.
class AgpCompileSdkLimit {
  /// Creates an AGP-to-compile-SDK limit.
  const AgpCompileSdkLimit({required this.agp, required this.maxCompileSdk});

  /// AGP versions covered by this limit.
  final VersionConstraint agp;

  /// Highest compile SDK expected to work with the AGP range.
  final int maxCompileSdk;
}

/// Maximum Java version supported by a Gradle range.
class GradleJavaSupport {
  /// Creates a Gradle-to-Java compatibility entry.
  const GradleJavaSupport({required this.gradle, required this.maxJava});

  /// Gradle versions covered by this support entry.
  final VersionConstraint gradle;

  /// Highest Java major version supported by the Gradle range.
  final int maxJava;
}

/// Compatibility tables used by the built-in rules.
class CompatibilityData {
  /// Creates a compatibility data set.
  const CompatibilityData({
    required this.agpGradleRanges,
    required this.agpJavaRequirements,
    required this.agpCompileSdkLimits,
    required this.gradleJavaSupport,
    required this.minimumSupportedIos,
  });

  /// Returns the package's built-in compatibility tables.
  factory CompatibilityData.defaults() {
    return CompatibilityData(
      agpGradleRanges: [
        AgpGradleRange(
          agp: VersionConstraint.parse('>=3.0.0 <4.0.0'),
          minGradle: Version.parse('4.1.0'),
          maxGradle: Version.parse('5.6.4'),
        ),
        AgpGradleRange(
          agp: VersionConstraint.parse('>=4.0.0 <4.2.0'),
          minGradle: Version.parse('6.1.1'),
          maxGradle: Version.parse('6.7.1'),
        ),
        AgpGradleRange(
          agp: VersionConstraint.parse('>=4.2.0 <7.0.0'),
          minGradle: Version.parse('6.7.1'),
          maxGradle: Version.parse('6.9.4'),
        ),
        AgpGradleRange(
          agp: VersionConstraint.parse('>=7.0.0 <7.3.0'),
          minGradle: Version.parse('7.0.0'),
          maxGradle: Version.parse('7.4.2'),
        ),
        AgpGradleRange(
          agp: VersionConstraint.parse('>=7.3.0 <8.0.0'),
          minGradle: Version.parse('7.4.0'),
          maxGradle: Version.parse('7.6.4'),
        ),
        AgpGradleRange(
          agp: VersionConstraint.parse('>=8.0.0 <8.2.0'),
          minGradle: Version.parse('8.0.0'),
          maxGradle: Version.parse('8.3.0'),
        ),
        AgpGradleRange(
          agp: VersionConstraint.parse('>=8.2.0 <8.4.0'),
          minGradle: Version.parse('8.2.0'),
          maxGradle: Version.parse('8.6.0'),
        ),
        AgpGradleRange(
          agp: VersionConstraint.parse('>=8.4.0 <8.6.0'),
          minGradle: Version.parse('8.6.0'),
          maxGradle: Version.parse('8.8.0'),
        ),
      ],
      agpJavaRequirements: [
        AgpJavaRequirement(
          agp: VersionConstraint.parse('>=7.0.0 <8.0.0'),
          requiredJava: 11,
        ),
        AgpJavaRequirement(
          agp: VersionConstraint.parse('>=8.0.0 <9.0.0'),
          requiredJava: 17,
        ),
      ],
      agpCompileSdkLimits: [
        AgpCompileSdkLimit(
          agp: VersionConstraint.parse('>=3.0.0 <4.2.0'),
          maxCompileSdk: 30,
        ),
        AgpCompileSdkLimit(
          agp: VersionConstraint.parse('>=4.2.0 <7.1.0'),
          maxCompileSdk: 31,
        ),
        AgpCompileSdkLimit(
          agp: VersionConstraint.parse('>=7.1.0 <7.3.0'),
          maxCompileSdk: 32,
        ),
        AgpCompileSdkLimit(
          agp: VersionConstraint.parse('>=7.3.0 <8.0.0'),
          maxCompileSdk: 33,
        ),
        AgpCompileSdkLimit(
          agp: VersionConstraint.parse('>=8.0.0 <8.3.0'),
          maxCompileSdk: 34,
        ),
        AgpCompileSdkLimit(
          agp: VersionConstraint.parse('>=8.3.0 <8.6.0'),
          maxCompileSdk: 35,
        ),
      ],
      gradleJavaSupport: [
        GradleJavaSupport(
          gradle: VersionConstraint.parse('>=0.0.0 <7.3.0'),
          maxJava: 16,
        ),
        GradleJavaSupport(
          gradle: VersionConstraint.parse('>=7.3.0 <8.5.0'),
          maxJava: 20,
        ),
        GradleJavaSupport(
          gradle: VersionConstraint.parse('>=8.5.0 <9.0.0'),
          maxJava: 21,
        ),
      ],
      minimumSupportedIos: Version.parse('13.0.0'),
    );
  }

  /// Known AGP-to-Gradle compatibility ranges.
  final List<AgpGradleRange> agpGradleRanges;

  /// Known Java requirements for AGP versions.
  final List<AgpJavaRequirement> agpJavaRequirements;

  /// Known compile SDK limits for AGP versions.
  final List<AgpCompileSdkLimit> agpCompileSdkLimits;

  /// Known Java support ranges for Gradle versions.
  final List<GradleJavaSupport> gradleJavaSupport;

  /// Minimum iOS deployment target expected for restored Flutter projects.
  final Version minimumSupportedIos;

  /// Finds the Gradle range for [agp], or `null` when unknown.
  AgpGradleRange? agpGradleRangeFor(Version agp) {
    return agpGradleRanges.where((range) => range.agp.allows(agp)).firstOrNull;
  }

  /// Finds the Java requirement for [agp], or `null` when unknown.
  AgpJavaRequirement? agpJavaRequirementFor(Version agp) {
    return agpJavaRequirements
        .where((requirement) => requirement.agp.allows(agp))
        .firstOrNull;
  }

  /// Finds the compile SDK limit for [agp], or `null` when unknown.
  AgpCompileSdkLimit? agpCompileSdkLimitFor(Version agp) {
    return agpCompileSdkLimits
        .where((limit) => limit.agp.allows(agp))
        .firstOrNull;
  }

  /// Finds the Java support entry for [gradle], or `null` when unknown.
  GradleJavaSupport? gradleJavaSupportFor(Version gradle) {
    return gradleJavaSupport
        .where((support) => support.gradle.allows(gradle))
        .firstOrNull;
  }
}
