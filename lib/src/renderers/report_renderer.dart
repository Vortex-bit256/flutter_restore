import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';

/// Base class for scan report renderers.
abstract class ReportRenderer {
  /// Creates a report renderer.
  const ReportRenderer();

  /// Formats [snapshot] and [findings] for a target output.
  String render(ProjectSnapshot snapshot, List<Finding> findings);
}
