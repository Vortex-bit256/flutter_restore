import 'package:flutter_restore/src/compatibility/compatibility_data.dart';
import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/ios_snapshot.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';
import 'package:flutter_restore/src/models/scan_platform.dart';
import 'package:flutter_restore/src/rules/compatibility_rule.dart';
import 'package:pub_semver/pub_semver.dart';

part 'rule_runner.android.dart';
part 'rule_runner.ios.dart';
part 'rule_runner.platforms.dart';
part 'rule_runner.project.dart';

/// Runs a set of compatibility rules against a project snapshot.
class RuleRunner {
  /// Creates a runner with optional custom compatibility [data] and [rules].
  RuleRunner({CompatibilityData? data, List<CompatibilityRule>? rules})
    : data = data ?? CompatibilityData.defaults(),
      rules = rules ?? defaultRules;

  /// Compatibility tables supplied to rules.
  final CompatibilityData data;

  /// Rules evaluated by this runner.
  final List<CompatibilityRule> rules;

  /// Default rules used by the command-line scanner.
  static const defaultRules = <CompatibilityRule>[
    RequiredFilesRule(),
    JavaGradleRule(),
    AgpGradleRule(),
    AgpJavaRule(),
    AgpCompileSdkRule(),
    FlutterAndroidMigrationRule(),
    IosDeploymentTargetRule(),
    IosDependencyManagementRule(),
    IosSceneLifecycleRule(),
    IosAppDelegateLegacyRule(),
    IosXcodeProjectConsistencyRule(),
    LinuxProjectStructureRule(),
    LinuxCmakeRule(),
    WindowsProjectStructureRule(),
    WindowsCmakeRule(),
    WindowsRunLoopRule(),
    WindowsVersionInfoRule(),
    WindowsDarkTitleBarRule(),
    WindowsShowWindowRule(),
    WebProjectStructureRule(),
    WebBootstrapRule(),
    WebServiceWorkerRule(),
    DesktopTargetPlatformOverrideRule(),
  ];

  /// Evaluates configured rules for the selected [platforms].
  List<Finding> evaluate(
    ProjectSnapshot snapshot, {
    Set<ScanPlatform> platforms = allScanPlatforms,
  }) {
    final findings = [
      for (final rule in rules)
        if (_appliesTo(rule, platforms)) ...rule.evaluate(snapshot, data),
    ];
    findings.sort(
      (a, b) => _severityRank(a.severity).compareTo(_severityRank(b.severity)),
    );
    return findings;
  }

  bool _appliesTo(CompatibilityRule rule, Set<ScanPlatform> platforms) {
    return rule.platforms.isEmpty ||
        rule.platforms.any((platform) => platforms.contains(platform));
  }

  int _severityRank(Severity severity) => switch (severity) {
    Severity.blocker => 0,
    Severity.high => 1,
    Severity.medium => 2,
    Severity.info => 3,
  };
}

String _location(String sourceFile, int? line) {
  return line == null ? sourceFile : '$sourceFile:$line';
}
