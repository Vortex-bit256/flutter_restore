part of 'rule_runner.dart';

/// Checks for project files required for reliable restoration analysis.
class RequiredFilesRule extends CompatibilityRule {
  /// Creates a required files rule.
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
