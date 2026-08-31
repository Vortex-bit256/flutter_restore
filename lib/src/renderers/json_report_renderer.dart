import 'dart:convert';

import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';
import 'package:flutter_restore/src/renderers/report_renderer.dart';

class JsonReportRenderer extends ReportRenderer {
  const JsonReportRenderer();

  @override
  String render(ProjectSnapshot snapshot, List<Finding> findings) {
    return const JsonEncoder.withIndent('  ').convert({
      'snapshot': snapshot.toJson(),
      'findings': findings.map((finding) => finding.toJson()).toList(),
    });
  }
}
