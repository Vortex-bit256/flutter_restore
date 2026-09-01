import 'android_snapshot.dart';
import 'ios_snapshot.dart';

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

  /// Converts this snapshot to the JSON report shape.
  Map<String, Object?> toJson() => {
    'rootPath': rootPath,
    'hasPubspec': hasPubspec,
    'hasPubspecLock': hasPubspecLock,
    'hasMetadata': hasMetadata,
    'pubspecName': pubspecName,
    'flutterRevision': flutterRevision,
    'android': android.toJson(),
    'ios': ios.toJson(),
  };
}
