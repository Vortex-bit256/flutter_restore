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

  test('scans old iOS deployment target facts', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_old_deployment_target',
    );

    expect(snapshot.ios.hasPodfile, isTrue);
    expect(snapshot.ios.hasPodfileLock, isTrue);
    expect(snapshot.ios.usesCocoaPods, isTrue);
    expect(snapshot.ios.deploymentTarget.toString(), '12.0.0');
    expect(snapshot.ios.podfilePlatformTarget.toString(), '12.0.0');
    expect(snapshot.ios.deploymentTargetsByConfiguration, hasLength(3));
    expect(
      snapshot.ios.uisceneLifecycleStatus,
      UISceneLifecycleStatus.complete,
    );
  });

  test('scans legacy CocoaPods-only iOS project facts', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_legacy_cocoapods',
    );

    expect(snapshot.ios.usesCocoaPods, isTrue);
    expect(snapshot.ios.usesSwiftPM, isFalse);
    expect(snapshot.ios.hasLegacyFlutterPodfileIntegration, isTrue);
    expect(snapshot.ios.hasPotentialCocoaPodsOnlyPlugins, isTrue);
    expect(
      snapshot.ios.nativePluginDeploymentTargets.single.name,
      'LegacyLocalPlugin',
    );
  });

  test('scans missing UIScene and custom AppDelegate facts', () {
    final snapshot = ProjectScanner().scan('test/fixtures/ios_uiscene_missing');

    expect(snapshot.ios.uisceneLifecycleStatus, UISceneLifecycleStatus.absent);
    expect(
      snapshot.ios.appDelegateLifecycleStyle,
      AppDelegateLifecycleStyle.appDelegateOnly,
    );
    expect(snapshot.ios.appDelegate.customPlatformIntegration, isTrue);
    expect(snapshot.ios.appDelegate.isCustom, isTrue);
  });

  test('scans custom legacy Objective-C AppDelegate facts', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_custom_legacy_appdelegate',
    );

    expect(snapshot.ios.appDelegate.usesFlutterImplicitEngineDelegate, isTrue);
    expect(
      snapshot.ios.appDelegate.hasDidInitializeImplicitFlutterEngine,
      isTrue,
    );
    expect(
      snapshot.ios.appDelegate.usesLegacyFlutterEngineInitialization,
      isTrue,
    );
    expect(snapshot.ios.appDelegate.usesObjectiveCLegacyIntegration, isTrue);
    expect(
      snapshot.ios.legacyBuildSettings.map((setting) => setting.key),
      contains('ENABLE_BITCODE'),
    );
  });

  test('scans modern SwiftPM iOS project facts', () {
    final snapshot = ProjectScanner().scan('test/fixtures/ios_modern_swiftpm');

    expect(snapshot.ios.usesSwiftPM, isTrue);
    expect(snapshot.ios.usesCocoaPods, isFalse);
    expect(snapshot.ios.usesMixedDependencyManagement, isFalse);
    expect(
      snapshot.ios.nativePluginDeploymentTargets.single.sourceKind,
      'swiftpm',
    );
    expect(
      snapshot.ios.uisceneLifecycleStatus,
      UISceneLifecycleStatus.complete,
    );
  });

  test('scans mixed iOS dependency-management facts', () {
    final snapshot = ProjectScanner().scan(
      'test/fixtures/ios_mixed_dependency_management',
    );

    expect(snapshot.ios.usesCocoaPods, isTrue);
    expect(snapshot.ios.usesSwiftPM, isTrue);
    expect(snapshot.ios.usesMixedDependencyManagement, isTrue);
    expect(snapshot.ios.swiftPackageManagerDisabled, isTrue);
    expect(
      snapshot.ios.uisceneLifecycleStatus,
      UISceneLifecycleStatus.incomplete,
    );
  });
}
