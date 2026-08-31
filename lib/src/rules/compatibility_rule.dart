import 'package:flutter_restore/src/compatibility/compatibility_data.dart';
import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';

abstract class CompatibilityRule {
  const CompatibilityRule();

  Iterable<Finding> evaluate(ProjectSnapshot snapshot, CompatibilityData data);
}
