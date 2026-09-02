/// Static compatibility scanner for legacy Flutter projects.
///
/// The public library exposes the scanner, compatibility rules, result models,
/// report renderers, and CLI entry point used by the `flutter_restore`
/// executable.
library;

export 'src/cli.dart';
export 'src/compatibility/compatibility_data.dart';
export 'src/models/android_snapshot.dart';
export 'src/models/finding.dart';
export 'src/models/ios_snapshot.dart';
export 'src/models/platform_snapshot.dart';
export 'src/models/project_snapshot.dart';
export 'src/models/scan_platform.dart';
export 'src/renderers/json_report_renderer.dart';
export 'src/renderers/plain_report_renderer.dart';
export 'src/renderers/report_renderer.dart';
export 'src/rules/compatibility_rule.dart';
export 'src/rules/rule_runner.dart';
export 'src/scanners/ios_scanner.dart';
export 'src/scanners/project_scanner.dart';
