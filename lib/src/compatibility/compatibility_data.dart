import 'package:pub_semver/pub_semver.dart';

class AgpGradleRange {
  const AgpGradleRange({
    required this.agp,
    required this.minGradle,
    required this.maxGradle,
  });

  final VersionConstraint agp;
  final Version minGradle;
  final Version maxGradle;
}

class AgpJavaRequirement {
  const AgpJavaRequirement({required this.agp, required this.requiredJava});

  final VersionConstraint agp;
  final int requiredJava;
}

class AgpCompileSdkLimit {
  const AgpCompileSdkLimit({required this.agp, required this.maxCompileSdk});

  final VersionConstraint agp;
  final int maxCompileSdk;
}

class GradleJavaSupport {
  const GradleJavaSupport({required this.gradle, required this.maxJava});

  final VersionConstraint gradle;
  final int maxJava;
}

class CompatibilityData {
  const CompatibilityData({
    required this.agpGradleRanges,
    required this.agpJavaRequirements,
    required this.agpCompileSdkLimits,
    required this.gradleJavaSupport,
  });

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
    );
  }

  final List<AgpGradleRange> agpGradleRanges;
  final List<AgpJavaRequirement> agpJavaRequirements;
  final List<AgpCompileSdkLimit> agpCompileSdkLimits;
  final List<GradleJavaSupport> gradleJavaSupport;

  AgpGradleRange? agpGradleRangeFor(Version agp) {
    return agpGradleRanges.where((range) => range.agp.allows(agp)).firstOrNull;
  }

  AgpJavaRequirement? agpJavaRequirementFor(Version agp) {
    return agpJavaRequirements
        .where((requirement) => requirement.agp.allows(agp))
        .firstOrNull;
  }

  AgpCompileSdkLimit? agpCompileSdkLimitFor(Version agp) {
    return agpCompileSdkLimits
        .where((limit) => limit.agp.allows(agp))
        .firstOrNull;
  }

  GradleJavaSupport? gradleJavaSupportFor(Version gradle) {
    return gradleJavaSupport
        .where((support) => support.gradle.allows(gradle))
        .firstOrNull;
  }
}
