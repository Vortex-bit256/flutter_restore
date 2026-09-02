import 'dart:io';

import 'package:args/args.dart';

import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/scan_platform.dart';
import 'package:flutter_restore/src/renderers/json_report_renderer.dart';
import 'package:flutter_restore/src/renderers/plain_report_renderer.dart';
import 'package:flutter_restore/src/renderers/report_renderer.dart';
import 'package:flutter_restore/src/rules/rule_runner.dart';
import 'package:flutter_restore/src/scanners/project_scanner.dart';

/// Runs the `flutter_restore` command-line interface.
Future<int> runFlutterRestore(
  List<String> arguments, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  final parser = ArgParser()
    ..addCommand(
      'scan',
      ArgParser()
        ..addFlag(
          'json',
          negatable: false,
          help: 'Print machine-readable JSON.',
        )
        ..addOption(
          'platform',
          defaultsTo: 'all',
          allowed: [
            'all',
            ...ScanPlatform.values.map((platform) => platform.label),
          ],
          help: 'Print and evaluate one platform, or all platforms.',
          allowedHelp: {
            'all': 'Include every supported platform.',
            for (final platform in ScanPlatform.values)
              platform.label: 'Include ${platform.label}.',
          },
        ),
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage(parser));
    return 64;
  }

  if (results.command?.name != 'scan') {
    stderr.writeln(_usage(parser));
    return 64;
  }

  final command = results.command!;
  if (command.rest.length != 1) {
    stderr.writeln('Expected exactly one project path.');
    stderr.writeln(_usage(parser));
    return 64;
  }

  // Read project facts, run compatibility rules, and print the selected report.
  final platforms = parseScanPlatforms(command['platform'] as String)!;
  final snapshot = ProjectScanner().scan(command.rest.single);
  final findings = RuleRunner().evaluate(snapshot, platforms: platforms);
  final renderer = _renderer(
    json: command['json'] as bool,
    platforms: platforms,
  );
  stdout.writeln(renderer.render(snapshot, findings));

  return findings.any((finding) => finding.severity == Severity.blocker)
      ? 2
      : 0;
}

ReportRenderer _renderer({
  required bool json,
  required Set<ScanPlatform> platforms,
}) {
  return json
      ? JsonReportRenderer(platforms: platforms)
      : PlainReportRenderer(platforms: platforms);
}

String _usage(ArgParser parser) {
  return 'Usage: flutter_restore scan [--json] [--platform <platform|all>] <path>\n\n${parser.usage}';
}
