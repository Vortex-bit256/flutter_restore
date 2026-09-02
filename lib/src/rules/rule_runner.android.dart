part of 'rule_runner.dart';

abstract class _AndroidCompatibilityRule extends CompatibilityRule {
  const _AndroidCompatibilityRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.android};
}

/// Checks whether the Gradle version is compatible with modern Java.
class JavaGradleRule extends _AndroidCompatibilityRule {
  /// Creates a Java-to-Gradle compatibility rule.
  const JavaGradleRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final gradle = snapshot.android.gradleVersion;
    if (gradle == null) {
      yield const Finding(
        id: 'missing-gradle-version',
        severity: Severity.medium,
        title: 'Gradle version not detected',
        message:
            'android/gradle/wrapper/gradle-wrapper.properties was not found or could not be parsed.',
        location: 'android/gradle/wrapper/gradle-wrapper.properties',
      );
      return;
    }

    final support = data.gradleJavaSupportFor(gradle);
    if (support != null && support.maxJava < 17) {
      yield Finding(
        id: 'gradle-java-17-unsupported',
        severity: Severity.high,
        title: 'Gradle $gradle is too old for Java 17',
        message:
            'This Gradle line supports Java up to ${support.maxJava}; modern Android builds commonly use Java 17.',
        location: 'android/gradle/wrapper/gradle-wrapper.properties',
      );
    }
  }
}

/// Checks whether Android Gradle Plugin and Gradle versions are compatible.
class AgpGradleRule extends _AndroidCompatibilityRule {
  /// Creates an AGP-to-Gradle compatibility rule.
  const AgpGradleRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final agp = snapshot.android.agpVersion;
    final gradle = snapshot.android.gradleVersion;
    if (agp == null) {
      yield const Finding(
        id: 'missing-agp-version',
        severity: Severity.medium,
        title: 'Android Gradle Plugin version not detected',
        message: 'AGP version was not found in Android Gradle files.',
        location: 'android/build.gradle',
      );
      return;
    }
    if (gradle == null) {
      return;
    }

    final range = data.agpGradleRangeFor(agp);
    if (range == null) {
      yield Finding(
        id: 'unknown-agp-gradle-range',
        severity: Severity.info,
        title: 'No AGP/Gradle compatibility data for AGP $agp',
        message:
            'The scanner has no compatibility table entry for this Android Gradle Plugin version.',
        location: 'android/build.gradle',
      );
      return;
    }

    if (gradle < range.minGradle || gradle > range.maxGradle) {
      yield Finding(
        id: 'agp-gradle-mismatch',
        severity: Severity.high,
        title: 'AGP $agp and Gradle $gradle are incompatible',
        message:
            'AGP $agp expects Gradle ${range.minGradle} through ${range.maxGradle}.',
        location: 'android/build.gradle',
      );
    }
  }
}

/// Checks whether Android Gradle Plugin has the Java version it requires.
class AgpJavaRule extends _AndroidCompatibilityRule {
  /// Creates an AGP-to-Java compatibility rule.
  const AgpJavaRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final agp = snapshot.android.agpVersion;
    if (agp == null) {
      return;
    }
    final requirement = data.agpJavaRequirementFor(agp);
    if (requirement != null) {
      yield Finding(
        id: 'agp-java-requirement',
        severity: Severity.info,
        title: 'AGP $agp requires Java ${requirement.requiredJava}',
        message:
            'Use this Java level when restoring the project on a modern machine.',
        location: 'android/build.gradle',
      );
    }
  }
}

/// Checks whether `compileSdk` is supported by the detected AGP version.
class AgpCompileSdkRule extends _AndroidCompatibilityRule {
  /// Creates an AGP-to-compile-SDK compatibility rule.
  const AgpCompileSdkRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final agp = snapshot.android.agpVersion;
    final compileSdk = snapshot.android.compileSdk;
    if (agp == null || compileSdk == null) {
      return;
    }
    final limit = data.agpCompileSdkLimitFor(agp);
    if (limit != null && compileSdk > limit.maxCompileSdk) {
      yield Finding(
        id: 'agp-compile-sdk-too-new',
        severity: Severity.high,
        title: 'compileSdk $compileSdk is too new for AGP $agp',
        message:
            'Known compatibility data caps this AGP line at compileSdk ${limit.maxCompileSdk}.',
        location: 'android/app/build.gradle',
      );
    }
  }
}

/// Detects old Android Flutter integration patterns.
class FlutterAndroidMigrationRule extends _AndroidCompatibilityRule {
  /// Creates a Flutter Android migration rule.
  const FlutterAndroidMigrationRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final android = snapshot.android;
    if (android.usesLegacyFlutterGradleApply) {
      yield const Finding(
        id: 'legacy-flutter-gradle-apply',
        severity: Severity.high,
        title: 'Legacy Flutter Gradle apply detected',
        message:
            'The Android project applies flutter.gradle with apply from, which is incompatible with newer Flutter Gradle integration.',
        location: 'android/app/build.gradle',
      );
    }
    if (android.hasFlutterPluginsFile) {
      yield const Finding(
        id: 'flutter-plugins-file',
        severity: Severity.medium,
        title: '.flutter-plugins file detected',
        message:
            'Old Flutter projects used this generated plugin registry file; modern projects use .flutter-plugins-dependencies.',
        location: '.flutter-plugins',
      );
    }
    if (android.usesAndroidV1Embedding) {
      yield const Finding(
        id: 'android-v1-embedding',
        severity: Severity.high,
        title: 'Android v1 embedding detected',
        message:
            'MainActivity imports io.flutter.app.FlutterActivity; migrate to the v2 embedding before using current Flutter.',
        location: 'android/app/src/main',
      );
    }
    if (!android.usesPluginDsl) {
      yield const Finding(
        id: 'missing-plugin-dsl',
        severity: Severity.info,
        title: 'Gradle Plugin DSL not detected',
        message:
            'The Android build still appears to use legacy buildscript/classpath style plugin configuration.',
        location: 'android/build.gradle',
      );
    }
  }
}
