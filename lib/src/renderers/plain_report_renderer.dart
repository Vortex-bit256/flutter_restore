import 'package:flutter_restore/src/models/finding.dart';
import 'package:flutter_restore/src/models/platform_snapshot.dart';
import 'package:flutter_restore/src/models/project_snapshot.dart';
import 'package:flutter_restore/src/models/scan_platform.dart';
import 'package:flutter_restore/src/renderers/report_renderer.dart';

/// Renders scan results as a human-readable terminal report.
class PlainReportRenderer extends ReportRenderer {
  /// Creates a plain text report renderer.
  const PlainReportRenderer({this.platforms = allScanPlatforms});

  /// Platforms included in the report.
  final Set<ScanPlatform> platforms;

  @override
  String render(ProjectSnapshot snapshot, List<Finding> findings) {
    final buffer = StringBuffer()
      ..writeln(_style('flutter_restore scan', _Ansi.bold))
      ..writeln('Project: ${snapshot.rootPath}');

    if (snapshot.pubspecName != null) {
      buffer.writeln('Package: ${snapshot.pubspecName}');
    }

    if (platforms.contains(ScanPlatform.android)) {
      final android = snapshot.android;
      buffer
        ..writeln('')
        ..writeln(_style('Android', _Ansi.bold))
        ..writeln('  Gradle: ${android.gradleVersion ?? 'unknown'}')
        ..writeln('  AGP: ${android.agpVersion ?? 'unknown'}')
        ..writeln('  Kotlin: ${android.kotlinVersion ?? 'unknown'}')
        ..writeln(
          '  SDK: compile=${android.compileSdk ?? 'unknown'}, min=${android.minSdk ?? 'unknown'}, target=${android.targetSdk ?? 'unknown'}',
        )
        ..writeln(
          '  Legacy flutter.gradle apply: ${android.usesLegacyFlutterGradleApply}',
        )
        ..writeln('  .flutter-plugins: ${android.hasFlutterPluginsFile}')
        ..writeln('  Android v1 embedding: ${android.usesAndroidV1Embedding}')
        ..writeln('  Plugin DSL: ${android.usesPluginDsl}');
    }

    if (platforms.contains(ScanPlatform.ios)) {
      final ios = snapshot.ios;
      buffer
        ..writeln('')
        ..writeln(_style('iOS', _Ansi.bold))
        ..writeln('  Deployment target: ${ios.deploymentTarget ?? 'unknown'}')
        ..writeln(
          '  Podfile platform: ${ios.podfilePlatformTarget ?? 'unknown'}',
        )
        ..writeln('  CocoaPods: ${ios.usesCocoaPods}')
        ..writeln('  SwiftPM: ${ios.usesSwiftPM}')
        ..writeln(
          '  Mixed dependency management: ${ios.usesMixedDependencyManagement}',
        )
        ..writeln('  UIScene lifecycle: ${ios.uisceneLifecycleStatus.label}')
        ..writeln(
          '  AppDelegate lifecycle: ${ios.appDelegateLifecycleStyle.label}',
        );
    }

    if (platforms.contains(ScanPlatform.linux)) {
      _writePlatformSnapshot(buffer, 'Linux', snapshot.linux);
    }
    if (platforms.contains(ScanPlatform.windows)) {
      _writePlatformSnapshot(buffer, 'Windows', snapshot.windows);
    }
    if (platforms.contains(ScanPlatform.web)) {
      _writePlatformSnapshot(buffer, 'Web', snapshot.web);
    }

    buffer
      ..writeln('')
      ..writeln(_style('Findings', _Ansi.bold));

    if (findings.isEmpty) {
      buffer.writeln('  ${_style('No compatibility findings.', _Ansi.green)}');
      return buffer.toString().trimRight();
    }

    for (final finding in findings) {
      final badge = _style(
        '[${finding.severity.label}]',
        _colorFor(finding.severity),
      );
      buffer.writeln('  $badge ${finding.title}');
      buffer.writeln('    ${finding.message}');
      if (finding.location != null) {
        buffer.writeln('    ${_style(finding.location!, _Ansi.dim)}');
      }
      if (finding.detectedValue != null) {
        buffer.writeln('    detected: ${finding.detectedValue}');
      }
      if (finding.recommendation != null) {
        buffer.writeln('    recommendation: ${finding.recommendation}');
      }
    }

    return buffer.toString().trimRight();
  }
}

void _writePlatformSnapshot(
  StringBuffer buffer,
  String title,
  PlatformSnapshot snapshot,
) {
  buffer
    ..writeln('')
    ..writeln(_style(title, _Ansi.bold))
    ..writeln('  Directory: ${snapshot.hasDirectory}')
    ..writeln(
      '  Detected files: ${snapshot.detectedFiles.isEmpty ? 'none' : snapshot.detectedFiles.join(', ')}',
    )
    ..writeln(
      '  Missing expected files: ${snapshot.missingExpectedFiles.isEmpty ? 'none' : snapshot.missingExpectedFiles.join(', ')}',
    );
}

// Цвет нужен только обычному отчету: JSON остается сухим и машинным.
String _style(String value, String color) => '$color$value${_Ansi.reset}';

String _colorFor(Severity severity) => switch (severity) {
  Severity.blocker => _Ansi.redBold,
  Severity.high => _Ansi.red,
  Severity.medium => _Ansi.yellow,
  Severity.info => _Ansi.blue,
};

abstract final class _Ansi {
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const dim = '\x1B[2m';
  static const red = '\x1B[31m';
  static const redBold = '\x1B[1;31m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const green = '\x1B[32m';
}
