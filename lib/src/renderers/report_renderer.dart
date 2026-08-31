import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';

abstract class ReportRenderer {
  const ReportRenderer();

  String render(ProjectSnapshot snapshot, List<Finding> findings);
}
