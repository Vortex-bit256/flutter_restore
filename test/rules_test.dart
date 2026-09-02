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

  test('filters compatibility rules by selected platform', () {
    final snapshot = ProjectScanner().scan('test/fixtures/legacy_flutter');
    final findings = RuleRunner().evaluate(
      snapshot,
      platforms: const {ScanPlatform.ios},
    );
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, isNot(contains('gradle-java-17-unsupported')));
    expect(ids, isNot(contains('legacy-flutter-gradle-apply')));
  });

  test('reports missing desktop and web platform directories', () {
    final snapshot = ProjectScanner().scan('test/fixtures/legacy_flutter');
    final findings = RuleRunner().evaluate(
      snapshot,
      platforms: const {
        ScanPlatform.linux,
        ScanPlatform.windows,
        ScanPlatform.web,
      },
    );
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('linux-platform-directory-missing'));
    expect(ids, contains('windows-platform-directory-missing'));
    expect(ids, contains('web-platform-directory-missing'));
    expect(ids, isNot(contains('gradle-java-17-unsupported')));
  });

  test('accepts complete desktop and web platform structures', () {
    final snapshot = ProjectScanner().scan('test/fixtures/modern_flutter');
    final findings = RuleRunner().evaluate(
      snapshot,
      platforms: const {
        ScanPlatform.linux,
        ScanPlatform.windows,
        ScanPlatform.web,
      },
    );
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, isNot(contains('linux-runner-files-incomplete')));
    expect(ids, isNot(contains('windows-runner-files-incomplete')));
    expect(ids, isNot(contains('web-runner-files-incomplete')));
  });

  test('reports legacy Linux, Windows, and web migration findings', () {
    final snapshot = ProjectScanner().scan('test/fixtures/desktop_web_legacy');
    final findings = RuleRunner().evaluate(
      snapshot,
      platforms: const {
        ScanPlatform.linux,
        ScanPlatform.windows,
        ScanPlatform.web,
      },
    );
    final ids = findings.map((finding) => finding.id).toSet();

    expect(ids, contains('linux-cmake-minimum-too-low'));
    expect(ids, contains('linux-gtk-pkg-config-missing'));
    expect(ids, contains('windows-cmake-minimum-too-low'));
    expect(ids, contains('windows-legacy-run-loop'));
    expect(ids, contains('windows-version-info-not-tool-driven'));
    expect(ids, contains('windows-dark-title-bar-support-missing'));
    expect(ids, contains('windows-force-redraw-missing'));
    expect(ids, contains('web-base-href-missing'));
    expect(ids, contains('web-legacy-load-entrypoint'));
    expect(ids, contains('web-custom-bootstrap-incomplete'));
    expect(ids, contains('web-deprecated-service-worker-version'));
    expect(ids, contains('web-manual-service-worker-registration'));
    expect(ids, contains('desktop-legacy-target-platform-override'));
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
