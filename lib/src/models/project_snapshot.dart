import 'android_snapshot.dart';
import 'ios_snapshot.dart';
import 'platform_snapshot.dart';
import 'scan_platform.dart';

/// Complete static snapshot of a Flutter project.
class ProjectSnapshot {
  /// Creates a project snapshot from already-scanned facts.
  const ProjectSnapshot({
    required this.rootPath,
    required this.hasPubspec,
    required this.hasPubspecLock,
    required this.hasMetadata,
    required this.pubspecName,
    required this.flutterRevision,
    required this.android,
    required this.ios,
    required this.linux,
    required this.windows,
    required this.web,
  });

  /// Absolute path that was scanned.
  final String rootPath;

  /// Whether `pubspec.yaml` exists.
  final bool hasPubspec;

  /// Whether `pubspec.lock` exists.
  final bool hasPubspecLock;

  /// Whether Flutter's `.metadata` file exists.
  final bool hasMetadata;

  /// Package name read from `pubspec.yaml`, when available.
  final String? pubspecName;

  /// Flutter revision read from `.metadata`, when available.
  final String? flutterRevision;

  /// Android-specific project facts.
  final AndroidSnapshot android;

  /// iOS-specific project facts.
  final IosSnapshot ios;

  /// Linux desktop project facts.
  final PlatformSnapshot linux;

  /// Windows desktop project facts.
  final PlatformSnapshot windows;

  /// Web project facts.
  final PlatformSnapshot web;

  /// Converts this snapshot to the JSON report shape.
  Map<String, Object?> toJson({
    Set<ScanPlatform> platforms = allScanPlatforms,
  }) => {
    'rootPath': rootPath,
    'hasPubspec': hasPubspec,
    'hasPubspecLock': hasPubspecLock,
    'hasMetadata': hasMetadata,
    'pubspecName': pubspecName,
    'flutterRevision': flutterRevision,
    if (platforms.contains(ScanPlatform.android)) 'android': android.toJson(),
    if (platforms.contains(ScanPlatform.ios)) 'ios': ios.toJson(),
    if (platforms.contains(ScanPlatform.linux)) 'linux': linux.toJson(),
    if (platforms.contains(ScanPlatform.windows)) 'windows': windows.toJson(),
    if (platforms.contains(ScanPlatform.web)) 'web': web.toJson(),
  };
}
