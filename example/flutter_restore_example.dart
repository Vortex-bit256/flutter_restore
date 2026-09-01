import 'package:flutter_restore/flutter_restore.dart';

void main(List<String> arguments) {
  final projectPath = arguments.isEmpty ? '.' : arguments.single;
  final snapshot = ProjectScanner().scan(projectPath);
  final findings = RuleRunner().evaluate(snapshot);
  final report = PlainReportRenderer().render(snapshot, findings);

  print(report);
}
