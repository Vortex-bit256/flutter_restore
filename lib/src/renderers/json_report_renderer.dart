import 'dart:convert';

import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';
import 'package:flutter_restore/src/models/scan_platform.dart';
import 'package:flutter_restore/src/renderers/report_renderer.dart';

/// Renders scan results as stable, indented JSON.
class JsonReportRenderer extends ReportRenderer {
  /// Creates a JSON report renderer.
  const JsonReportRenderer({this.platforms = allScanPlatforms});

  /// Platforms included in the report.
  final Set<ScanPlatform> platforms;

  @override
  String render(ProjectSnapshot snapshot, List<Finding> findings) {
    return const JsonEncoder.withIndent('  ').convert({
      'platforms': platforms.map((platform) => platform.label).toList(),
      'snapshot': snapshot.toJson(platforms: platforms),
      'findings': findings.map((finding) => finding.toJson()).toList(),
    });
  }
}
