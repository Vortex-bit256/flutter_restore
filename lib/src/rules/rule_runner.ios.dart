part of 'rule_runner.dart';

abstract class _IosCompatibilityRule extends CompatibilityRule {
  const _IosCompatibilityRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.ios};
}

/// Checks iOS deployment targets against the supported Flutter baseline.
class IosDeploymentTargetRule extends _IosCompatibilityRule {
  /// Creates an iOS deployment target rule.
  const IosDeploymentTargetRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final ios = snapshot.ios;
    final minimum = data.minimumSupportedIos;

    for (final target in ios.deploymentTargetsByConfiguration) {
      if (target.target < minimum) {
        yield Finding(
          id: 'ios-deployment-target-too-low',
          severity: Severity.blocker,
          title: 'iOS deployment target is below ${minimum.major}',
          message:
              '${target.configuration} sets IPHONEOS_DEPLOYMENT_TARGET to ${target.target}; current Flutter supports iOS ${minimum.major}+.',
          location: _location(target.sourceFile, target.line),
          sourceFile: target.sourceFile,
          line: target.line,
          detectedValue: target.target.toString(),
          recommendation:
              'Raise every iOS build configuration to at least ${minimum.major}.0 before migrating the toolchain.',
        );
      }
    }

    final podfileTarget = ios.podfilePlatformTarget;
    if (podfileTarget != null && podfileTarget < minimum) {
      yield Finding(
        id: 'ios-podfile-platform-too-low',
        severity: Severity.high,
        title: 'Podfile iOS platform is below ${minimum.major}',
        message:
            'Podfile platform :ios is $podfileTarget; CocoaPods will resolve pods against an unsupported iOS baseline.',
        location: _location('ios/Podfile', ios.podfilePlatformLine),
        sourceFile: 'ios/Podfile',
        line: ios.podfilePlatformLine,
        detectedValue: podfileTarget.toString(),
        recommendation:
            'Set platform :ios to ${minimum.major}.0 or higher and align it with the Xcode project target.',
      );
    }

    final distinctTargets = ios.deploymentTargetsByConfiguration
        .map((target) => target.target.toString())
        .toSet();
    if (distinctTargets.length > 1) {
      yield Finding(
        id: 'ios-deployment-target-mismatch',
        severity: Severity.high,
        title: 'iOS deployment targets differ between configurations',
        message:
            'Debug/Profile/Release do not agree on one IPHONEOS_DEPLOYMENT_TARGET value.',
        location: 'ios/Runner.xcodeproj/project.pbxproj',
        sourceFile: 'ios/Runner.xcodeproj/project.pbxproj',
        detectedValue: distinctTargets.join(', '),
        recommendation:
            'Choose a single iOS deployment target, preferably ${minimum.major}.0 or higher, across all build configurations.',
      );
    }

    final appTarget = ios.deploymentTarget;
    if (appTarget == null) {
      return;
    }
    for (final plugin in ios.nativePluginDeploymentTargets) {
      if (plugin.target > appTarget) {
        yield Finding(
          id: 'ios-plugin-deployment-target-conflict',
          severity: Severity.blocker,
          title: 'Plugin requires a higher iOS deployment target',
          message:
              '${plugin.name} declares iOS ${plugin.target}, but the app minimum is $appTarget.',
          location: _location(plugin.sourceFile, plugin.line),
          sourceFile: plugin.sourceFile,
          line: plugin.line,
          detectedValue: plugin.target.toString(),
          recommendation:
              'Raise the app deployment target or use a plugin version that supports the app baseline.',
        );
      } else if (plugin.target < minimum) {
        yield Finding(
          id: 'ios-plugin-deployment-target-too-low',
          severity: Severity.high,
          title: 'Plugin declares an iOS target below ${minimum.major}',
          message:
              '${plugin.name} declares iOS ${plugin.target}; that local native metadata was authored for an older iOS baseline.',
          location: _location(plugin.sourceFile, plugin.line),
          sourceFile: plugin.sourceFile,
          line: plugin.line,
          detectedValue: plugin.target.toString(),
          recommendation:
              'Review or update the local plugin metadata for iOS ${minimum.major}+ compatibility.',
        );
      }
    }
  }
}

/// Detects risky or inconsistent iOS dependency management setups.
class IosDependencyManagementRule extends _IosCompatibilityRule {
  /// Creates an iOS dependency management rule.
  const IosDependencyManagementRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final ios = snapshot.ios;
    if (ios.swiftPackageManagerDisabled) {
      yield const Finding(
        id: 'ios-swiftpm-disabled',
        severity: Severity.high,
        title: 'Swift Package Manager appears to be disabled',
        message:
            'The iOS project contains settings or flags that disable SwiftPM integration.',
        location: 'ios',
        sourceFile: 'ios',
        recommendation:
            'Remove explicit SwiftPM opt-out flags before adopting Flutter 3.44 defaults.',
      );
    }
    if (ios.usesCocoaPods && !ios.usesSwiftPM) {
      yield const Finding(
        id: 'ios-legacy-cocoapods-only',
        severity: Severity.medium,
        title: 'iOS dependencies are CocoaPods-only',
        message:
            'CocoaPods is still usable, but Flutter 3.44 uses SwiftPM by default and CocoaPods is a migration risk.',
        location: 'ios/Podfile',
        sourceFile: 'ios/Podfile',
        recommendation:
            'Plan a dependency-management migration path and verify whether plugins support SwiftPM.',
      );
    }
    if (ios.usesMixedDependencyManagement) {
      yield const Finding(
        id: 'ios-mixed-dependency-management',
        severity: Severity.medium,
        title: 'CocoaPods and SwiftPM are both present',
        message:
            'Mixed iOS dependency management can produce duplicate native dependencies or conflicting build settings.',
        location: 'ios',
        sourceFile: 'ios',
        recommendation:
            'Audit which plugins are resolved by CocoaPods versus SwiftPM and keep ownership explicit during migration.',
      );
    }
    if (ios.hasLegacyFlutterPodfileIntegration) {
      yield const Finding(
        id: 'ios-legacy-flutter-podfile-integration',
        severity: Severity.medium,
        title: 'Legacy Flutter Podfile integration detected',
        message:
            'The Podfile references Flutter as a manual pod/framework instead of relying only on generated Flutter tooling hooks.',
        location: 'ios/Podfile',
        sourceFile: 'ios/Podfile',
        recommendation:
            'Regenerate or modernize the iOS Podfile integration before moving to the current toolchain.',
      );
    }
    if (ios.hasPotentialCocoaPodsOnlyPlugins) {
      yield const Finding(
        id: 'ios-potential-cocoapods-only-plugins',
        severity: Severity.medium,
        title: 'Local plugins appear to have CocoaPods metadata only',
        message:
            'Local .podspec files were found, but no local SwiftPM platform metadata was detected.',
        location: 'ios',
        sourceFile: 'ios',
        recommendation:
            'Check whether these plugins have SwiftPM support or must stay on CocoaPods during migration.',
      );
    }
  }
}

/// Checks whether iOS scene lifecycle files are internally consistent.
class IosSceneLifecycleRule extends _IosCompatibilityRule {
  /// Creates an iOS scene lifecycle rule.
  const IosSceneLifecycleRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final ios = snapshot.ios;
    if (ios.uisceneLifecycleStatus == UISceneLifecycleStatus.incomplete) {
      yield const Finding(
        id: 'ios-uiscene-incomplete',
        severity: Severity.high,
        title: 'UIScene manifest is incomplete',
        message:
            'Info.plist contains UIApplicationSceneManifest without a complete scene configuration.',
        location: 'ios/Runner/Info.plist',
        sourceFile: 'ios/Runner/Info.plist',
        recommendation:
            'Add a complete scene configuration or regenerate the iOS runner files for the target Flutter version.',
      );
    }
    if (ios.uisceneLifecycleStatus == UISceneLifecycleStatus.absent &&
        ios.appDelegateLifecycleStyle ==
            AppDelegateLifecycleStyle.appDelegateOnly &&
        ios.appDelegate.isCustom) {
      yield Finding(
        id: 'ios-custom-appdelegate-only-lifecycle',
        severity: Severity.high,
        title: 'Custom AppDelegate-only lifecycle detected',
        message:
            'The project has no UIScene manifest and AppDelegate contains custom Flutter/native lifecycle code.',
        location: _location(
          ios.appDelegate.sourceFile ?? 'ios/Runner/AppDelegate',
          ios.appDelegate.didFinishLaunchingLine,
        ),
        sourceFile: ios.appDelegate.sourceFile,
        line: ios.appDelegate.didFinishLaunchingLine,
        recommendation:
            'Migrate custom launch code carefully while adopting a modern iOS lifecycle structure.',
      );
    }
  }
}

/// Detects legacy or custom iOS AppDelegate integration patterns.
class IosAppDelegateLegacyRule extends _IosCompatibilityRule {
  /// Creates an iOS AppDelegate legacy rule.
  const IosAppDelegateLegacyRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final appDelegate = snapshot.ios.appDelegate;
    if (appDelegate.manualGeneratedPluginRegistrant) {
      yield Finding(
        id: 'ios-manual-generated-plugin-registrant',
        severity: Severity.medium,
        title: 'Manual GeneratedPluginRegistrant registration detected',
        message:
            'AppDelegate calls GeneratedPluginRegistrant directly, a common legacy Flutter iOS pattern.',
        location: _location(
          appDelegate.sourceFile ?? 'ios/Runner/AppDelegate',
          appDelegate.generatedPluginRegistrantLine,
        ),
        sourceFile: appDelegate.sourceFile,
        line: appDelegate.generatedPluginRegistrantLine,
        detectedValue: 'GeneratedPluginRegistrant.register',
        recommendation:
            'Verify plugin registration against the generated iOS runner for the Flutter version being adopted.',
      );
    }
    if (appDelegate.customPlatformIntegration) {
      yield Finding(
        id: 'ios-custom-platform-integration-in-appdelegate',
        severity: Severity.high,
        title: 'Custom platform integration in AppDelegate',
        message:
            'AppDelegate appears to contain custom method channel, event channel, plugin, or platform view registration code.',
        location: _location(
          appDelegate.sourceFile ?? 'ios/Runner/AppDelegate',
          appDelegate.customPlatformIntegrationLine,
        ),
        sourceFile: appDelegate.sourceFile,
        line: appDelegate.customPlatformIntegrationLine,
        recommendation:
            'Move or revalidate custom native integration against the current Flutter iOS embedding.',
      );
    }
    if (appDelegate.usesFlutterImplicitEngineDelegate ||
        appDelegate.hasDidInitializeImplicitFlutterEngine) {
      yield Finding(
        id: 'ios-implicit-engine-lifecycle',
        severity: Severity.high,
        title: 'Implicit Flutter engine lifecycle hooks detected',
        message:
            'AppDelegate uses FlutterImplicitEngineDelegate or didInitializeImplicitFlutterEngine.',
        location: _location(
          appDelegate.sourceFile ?? 'ios/Runner/AppDelegate',
          appDelegate.flutterImplicitEngineDelegateLine ??
              appDelegate.didInitializeImplicitFlutterEngineLine,
        ),
        sourceFile: appDelegate.sourceFile,
        line:
            appDelegate.flutterImplicitEngineDelegateLine ??
            appDelegate.didInitializeImplicitFlutterEngineLine,
        recommendation:
            'Review engine initialization and plugin registration when migrating the iOS runner.',
      );
    }
    if (appDelegate.usesLegacyFlutterEngineInitialization ||
        appDelegate.usesObjectiveCLegacyIntegration) {
      yield Finding(
        id: 'ios-legacy-flutter-engine-initialization',
        severity: Severity.high,
        title: 'Legacy Flutter engine initialization detected',
        message:
            'AppDelegate contains explicit FlutterEngine/FlutterViewController initialization or Objective-C legacy integration.',
        location: _location(
          appDelegate.sourceFile ?? 'ios/Runner/AppDelegate',
          appDelegate.legacyFlutterEngineInitializationLine,
        ),
        sourceFile: appDelegate.sourceFile,
        line: appDelegate.legacyFlutterEngineInitializationLine,
        recommendation:
            'Compare this runner against a freshly generated current Flutter iOS runner before migration.',
      );
    }
  }
}

/// Detects stale Flutter references in iOS Xcode project files.
class IosXcodeProjectConsistencyRule extends _IosCompatibilityRule {
  /// Creates an iOS Xcode project consistency rule.
  const IosXcodeProjectConsistencyRule();

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final ios = snapshot.ios;
    if (ios.hasSuspiciousFlutterXcconfigReferences) {
      yield const Finding(
        id: 'ios-suspicious-flutter-xcconfig',
        severity: Severity.medium,
        title: 'Flutter xcconfig references look incomplete',
        message:
            'The iOS project is missing expected Flutter xcconfig references or local xcconfig files do not include Generated.xcconfig.',
        location: 'ios/Flutter',
        sourceFile: 'ios/Flutter',
        recommendation:
            'Regenerate or repair Debug/Profile/Release xcconfig references before opening the project in a modern Xcode toolchain.',
      );
    }
    if (ios.hasOldFlutterBuildScriptReferences) {
      yield const Finding(
        id: 'ios-old-flutter-build-script',
        severity: Severity.medium,
        title: 'Old Flutter xcode_backend.sh script reference detected',
        message:
            'The Xcode project references older Flutter build script invocations.',
        location: 'ios/Runner.xcodeproj/project.pbxproj',
        sourceFile: 'ios/Runner.xcodeproj/project.pbxproj',
        detectedValue: 'xcode_backend.sh build/thin',
        recommendation:
            'Refresh the Flutter build phases from a current generated iOS runner.',
      );
    }
    if (ios.hasLegacyFlutterFrameworkEmbedding) {
      yield const Finding(
        id: 'ios-legacy-framework-embedding',
        severity: Severity.high,
        title: 'Manual Flutter/App framework embedding detected',
        message:
            'project.pbxproj references Flutter.framework or App.framework, which often indicates an older integration strategy.',
        location: 'ios/Runner.xcodeproj/project.pbxproj',
        sourceFile: 'ios/Runner.xcodeproj/project.pbxproj',
        detectedValue: 'Flutter.framework/App.framework',
        recommendation:
            'Let current Flutter tooling manage framework embedding and remove stale manual references during migration.',
      );
    }
    for (final setting in ios.legacyBuildSettings) {
      yield Finding(
        id: 'ios-legacy-build-setting',
        severity: Severity.medium,
        title: 'Legacy or custom iOS build setting detected',
        message:
            '${setting.key} is set to ${setting.value}; this can conflict with modern Xcode defaults.',
        location: _location(setting.sourceFile, setting.line),
        sourceFile: setting.sourceFile,
        line: setting.line,
        detectedValue: '${setting.key}=${setting.value}',
        recommendation:
            'Review whether this build setting is still needed after regenerating the iOS runner.',
      );
    }
  }
}
