import 'package:flutter_restore/src/compatibility/compatibility_data.dart';
import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';
import 'package:flutter_restore/src/rules/compatibility_rule.dart';

class RuleRunner {
  RuleRunner({CompatibilityData? data, List<CompatibilityRule>? rules})
    : data = data ?? CompatibilityData.defaults(),
      rules = rules ?? defaultRules;

  final CompatibilityData data;
  final List<CompatibilityRule> rules;

  static const defaultRules = <CompatibilityRule>[
    // Держим порядок от базовой формы проекта к Android-совместимости.
    RequiredFilesRule(),
    JavaGradleRule(),
    AgpGradleRule(),
    AgpJavaRule(),
    AgpCompileSdkRule(),
    FlutterAndroidMigrationRule(),
  ];

  List<Finding> evaluate(ProjectSnapshot snapshot) {
    final findings = [
      for (final rule in rules) ...rule.evaluate(snapshot, data),
    ];
    findings.sort(
      (a, b) => _severityRank(a.severity).compareTo(_severityRank(b.severity)),
    );
    return findings;
  }

  int _severityRank(Severity severity) => switch (severity) {
    Severity.blocker => 0,
    Severity.high => 1,
    Severity.medium => 2,
    Severity.info => 3,
  };
}

class RequiredFilesRule extends CompatibilityRule {
  const RequiredFilesRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    if (!snapshot.hasPubspec) {
      yield const Finding(
        id: 'missing-pubspec',
        severity: Severity.blocker,
        title: 'pubspec.yaml not found',
        message: 'The path does not look like a Flutter/Dart project root.',
        location: 'pubspec.yaml',
      );
    }
    if (!snapshot.hasPubspecLock) {
      yield const Finding(
        id: 'missing-pubspec-lock',
        severity: Severity.medium,
        title: 'pubspec.lock not found',
        message:
            'Dependency versions cannot be inspected exactly without pubspec.lock.',
        location: 'pubspec.lock',
      );
    }
    if (!snapshot.hasMetadata) {
      yield const Finding(
        id: 'missing-metadata',
        severity: Severity.info,
        title: '.metadata not found',
        message: 'Flutter channel/revision metadata is unavailable.',
        location: '.metadata',
      );
    }
  }
}

class JavaGradleRule extends CompatibilityRule {
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
      // Java 17 - частая точка боли при восстановлении старого Android проекта.
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

class AgpGradleRule extends CompatibilityRule {
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
      // AGP и Gradle ходят парой; несовпадение обычно ломает build сразу.
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

class AgpJavaRule extends CompatibilityRule {
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

class AgpCompileSdkRule extends CompatibilityRule {
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
      // compileSdk легко поднять руками, но старый AGP такое не всегда переваривает.
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

class FlutterAndroidMigrationRule extends CompatibilityRule {
  const FlutterAndroidMigrationRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final android = snapshot.android;
    if (android.usesLegacyFlutterGradleApply) {
      // Старый Flutter Gradle apply - прямой сигнал, что миграция Android части нужна.
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
