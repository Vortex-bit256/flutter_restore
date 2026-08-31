import 'dart:io';

import 'package:args/args.dart';

import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/renderers/json_report_renderer.dart';
import 'package:flutter_restore/src/renderers/plain_report_renderer.dart';
import 'package:flutter_restore/src/renderers/report_renderer.dart';
import 'package:flutter_restore/src/rules/rule_runner.dart';
import 'package:flutter_restore/src/scanners/project_scanner.dart';

Future<int> runFlutterRestore(
  List<String> arguments, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  final parser = ArgParser()
    ..addCommand(
      'scan',
      ArgParser()..addFlag(
        'json',
        negatable: false,
        help: 'Print machine-readable JSON.',
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

  // Тут вся вертикаль MVP: читаем факты, прогоняем правила, печатаем отчет.
  final snapshot = ProjectScanner().scan(command.rest.single);
  final findings = RuleRunner().evaluate(snapshot);
  final renderer = _renderer(json: command['json'] as bool);
  stdout.writeln(renderer.render(snapshot, findings));

  return findings.any((finding) => finding.severity == Severity.blocker)
      ? 2
      : 0;
}

ReportRenderer _renderer({required bool json}) {
  return json ? const JsonReportRenderer() : const PlainReportRenderer();
}

String _usage(ArgParser parser) {
  return 'Usage: flutter_restore scan [--json] <path>\n\n${parser.usage}';
}
