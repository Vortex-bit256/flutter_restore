import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('prints plain scan report', () async {
    final result = await Process.run('dart', [
      'run',
      'flutter_restore',
      'scan',
      'test/fixtures/legacy_flutter',
    ]);

    expect(result.exitCode, 0);
    final output = result.stdout as String;
    expect(output, contains('\x1B[31m[HIGH]\x1B[0m'));
    expect(_stripAnsi(output), contains('flutter_restore scan'));
    expect(
      _stripAnsi(output),
      contains('[HIGH] Legacy Flutter Gradle apply detected'),
    );
  });

  test('prints JSON scan report', () async {
    final result = await Process.run('dart', [
      'run',
      'flutter_restore',
      'scan',
      '--json',
      'test/fixtures/modern_flutter',
    ]);

    expect(result.exitCode, 0);
    final report = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(report['snapshot']['pubspecName'], 'modern_app');
    expect(report['snapshot']['android']['usesPluginDsl'], isTrue);
    expect(report['findings'], isA<List<dynamic>>());
  });

  test('prints selected platform report only', () async {
    final result = await Process.run('dart', [
      'run',
      'flutter_restore',
      'scan',
      '--platform',
      'web',
      'test/fixtures/modern_flutter',
    ]);

    expect(result.exitCode, 0);
    final output = _stripAnsi(result.stdout as String);
    expect(output, contains('Web'));
    expect(output, isNot(contains('Android')));
    expect(output, isNot(contains('iOS')));
  });

  test('prints selected JSON platform only', () async {
    final result = await Process.run('dart', [
      'run',
      'flutter_restore',
      'scan',
      '--json',
      '--platform',
      'linux',
      'test/fixtures/modern_flutter',
    ]);

    expect(result.exitCode, 0);
    final report = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(report['platforms'], ['linux']);
    expect(report['snapshot'], containsPair('linux', isA<Map>()));
    expect(report['snapshot'], isNot(contains('android')));
    expect(report['snapshot'], isNot(contains('web')));
  });
}

String _stripAnsi(String value) {
  return value.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
}
