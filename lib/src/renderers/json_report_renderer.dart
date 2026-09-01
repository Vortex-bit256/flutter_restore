import 'dart:convert';

import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';
import 'package:flutter_restore/src/renderers/report_renderer.dart';

/// Renders scan results as stable, indented JSON.
class JsonReportRenderer extends ReportRenderer {
  /// Creates a JSON report renderer.
  const JsonReportRenderer();

  @override
  String render(ProjectSnapshot snapshot, List<Finding> findings) {
    return const JsonEncoder.withIndent('  ').convert({
      'snapshot': snapshot.toJson(),
      'findings': findings.map((finding) => finding.toJson()).toList(),
    });
  }
}
