import 'package:flutter_restore/src/compatibility/compatibility_data.dart';
import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';

/// Base class for a static compatibility rule.
abstract class CompatibilityRule {
  /// Creates a compatibility rule.
  const CompatibilityRule();

  /// Evaluates [snapshot] using [data] and returns any findings.
  Iterable<Finding> evaluate(ProjectSnapshot snapshot, CompatibilityData data);
}
