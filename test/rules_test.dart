import 'package:flutter_restore/flutter_restore.dart';
import 'package:test/test.dart';

void main() {
  test('reports legacy compatibility findings', () {
    final snapshot = ProjectScanner().scan('test/fixtures/legacy_flutter');
    final findings = RuleRunner().evaluate(snapshot);
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('gradle-java-17-unsupported'));
    expect(ids, contains('agp-compile-sdk-too-new'));
    expect(ids, contains('legacy-flutter-gradle-apply'));
    expect(ids, contains('flutter-plugins-file'));
    expect(ids, contains('android-v1-embedding'));
    expect(ids, contains('missing-plugin-dsl'));
  });

  test('keeps modern project mostly informational', () {
    final snapshot = ProjectScanner().scan('test/fixtures/modern_flutter');
    final findings = RuleRunner().evaluate(snapshot);

    expect(
      findings.where((finding) => finding.severity == Severity.high),
      isEmpty,
    );
    expect(
      findings.map((finding) => finding.id),
      contains('agp-java-requirement'),
    );
  });

  test('reports old iOS deployment target findings', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_old_deployment_target',
    );
    final findings = RuleRunner().evaluate(snapshot);
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('ios-deployment-target-too-low'));
    expect(ids, contains('ios-podfile-platform-too-low'));
    expect(
      findings
          .where((finding) => finding.id == 'ios-deployment-target-too-low')
          .map((finding) => finding.severity),
      everyElement(Severity.blocker),
    );
  });

  test('reports legacy CocoaPods migration findings', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_legacy_cocoapods',
    );
    final findings = RuleRunner().evaluate(snapshot);
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('ios-legacy-cocoapods-only'));
    expect(ids, contains('ios-legacy-flutter-podfile-integration'));
    expect(ids, contains('ios-potential-cocoapods-only-plugins'));
    expect(ids, contains('ios-plugin-deployment-target-too-low'));
    expect(ids, contains('ios-legacy-framework-embedding'));
  });

  test('reports missing UIScene custom lifecycle findings', () {
    final snapshot = ProjectScanner().scan('test/fixtures/ios_uiscene_missing');
    final findings = RuleRunner().evaluate(snapshot);
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('ios-custom-appdelegate-only-lifecycle'));
    expect(ids, contains('ios-custom-platform-integration-in-appdelegate'));
    expect(ids, contains('ios-legacy-flutter-engine-initialization'));
  });

  test('reports custom legacy AppDelegate findings', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_custom_legacy_appdelegate',
    );
    final findings = RuleRunner().evaluate(snapshot);
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('ios-manual-generated-plugin-registrant'));
    expect(ids, contains('ios-implicit-engine-lifecycle'));
    expect(ids, contains('ios-legacy-flutter-engine-initialization'));
    expect(ids, contains('ios-legacy-build-setting'));
  });

  test('keeps modern SwiftPM iOS fixture without high findings', () {
    final snapshot = ProjectScanner().scan('test/fixtures/ios_modern_swiftpm');
    final findings = RuleRunner().evaluate(snapshot);

    expect(
      findings.where((finding) => finding.severity == Severity.high),
      isEmpty,
    );
    expect(
      findings.where((finding) => finding.severity == Severity.blocker),
      isEmpty,
    );
  });

  test('reports mixed iOS dependency-management findings', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_mixed_dependency_management',
    );
    final findings = RuleRunner().evaluate(snapshot);
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('ios-mixed-dependency-management'));
    expect(ids, contains('ios-swiftpm-disabled'));
    expect(ids, contains('ios-uiscene-incomplete'));
    expect(ids, contains('ios-deployment-target-mismatch'));
    expect(ids, contains('ios-plugin-deployment-target-conflict'));
  });
}
