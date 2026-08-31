import 'package:flutter_restore/flutter_restore.dart';
import 'package:test/test.dart';

void main() {
  test('scans legacy Flutter Android project facts', () {
    final snapshot = ProjectScanner().scan('test/fixtures/legacy_flutter');

    expect(snapshot.pubspecName, 'legacy_app');
    expect(snapshot.hasPubspecLock, isTrue);
    expect(snapshot.hasMetadata, isTrue);
    expect(snapshot.android.gradleVersion.toString(), '5.6.4');
    expect(snapshot.android.agpVersion.toString(), '3.5.4');
    expect(snapshot.android.kotlinVersion.toString(), '1.3.50');
    expect(snapshot.android.compileSdk, 35);
    expect(snapshot.android.minSdk, 21);
    expect(snapshot.android.targetSdk, 28);
    expect(snapshot.android.usesLegacyFlutterGradleApply, isTrue);
    expect(snapshot.android.hasFlutterPluginsFile, isTrue);
    expect(snapshot.android.usesAndroidV1Embedding, isTrue);
    expect(snapshot.android.usesPluginDsl, isFalse);
  });

  test('scans modern Flutter Android project facts', () {
    final snapshot = ProjectScanner().scan('test/fixtures/modern_flutter');

    expect(snapshot.pubspecName, 'modern_app');
    expect(snapshot.android.gradleVersion.toString(), '8.7.0');
    expect(snapshot.android.agpVersion.toString(), '8.5.2');
    expect(snapshot.android.kotlinVersion.toString(), '2.0.20');
    expect(snapshot.android.compileSdk, 35);
    expect(snapshot.android.minSdk, 23);
    expect(snapshot.android.targetSdk, 35);
    expect(snapshot.android.usesLegacyFlutterGradleApply, isFalse);
    expect(snapshot.android.hasFlutterPluginsFile, isFalse);
    expect(snapshot.android.usesAndroidV1Embedding, isFalse);
    expect(snapshot.android.usesPluginDsl, isTrue);
  });
}
