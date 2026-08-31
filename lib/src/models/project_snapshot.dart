import 'android_snapshot.dart';
import 'ios_snapshot.dart';

class ProjectSnapshot {
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

  final String rootPath;
  final bool hasPubspec;
  final bool hasPubspecLock;
  final bool hasMetadata;
  final String? pubspecName;
  final String? flutterRevision;
  final AndroidSnapshot android;
  final IosSnapshot ios;

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
