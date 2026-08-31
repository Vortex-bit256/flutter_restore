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
}
