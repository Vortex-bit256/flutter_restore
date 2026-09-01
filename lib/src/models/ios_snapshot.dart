import 'package:pub_semver/pub_semver.dart';

/// Status of the iOS UIScene lifecycle configuration.
enum UISceneLifecycleStatus {
  /// No UIScene configuration was found.
  absent,

  /// UIScene manifest and related lifecycle hooks appear complete.
  complete,

  /// UIScene configuration exists but appears incomplete.
  incomplete;

  /// Stable JSON label for the status.
  String get label => switch (this) {
    UISceneLifecycleStatus.absent => 'absent',
    UISceneLifecycleStatus.complete => 'complete',
    UISceneLifecycleStatus.incomplete => 'incomplete',
  };
}

/// AppDelegate lifecycle style detected in the iOS runner.
enum AppDelegateLifecycleStyle {
  /// No AppDelegate source file was found.
  absent,

  /// The app appears to use only AppDelegate lifecycle hooks.
  appDelegateOnly,

  /// The app appears to use scene-based lifecycle hooks.
  sceneBased;

  /// Stable JSON label for the lifecycle style.
  String get label => switch (this) {
    AppDelegateLifecycleStyle.absent => 'absent',
    AppDelegateLifecycleStyle.appDelegateOnly => 'appDelegateOnly',
    AppDelegateLifecycleStyle.sceneBased => 'sceneBased',
  };
}

/// iOS-specific facts discovered from a Flutter project.
class IosSnapshot {
  /// Creates an iOS project snapshot.
  const IosSnapshot({
    this.deploymentTarget,
    this.podfilePlatformTarget,
    this.podfilePlatformLine,
    this.deploymentTargetsByConfiguration = const [],
    this.usesCocoaPods = false,
    this.usesSwiftPM = false,
    this.usesMixedDependencyManagement = false,
    this.hasPodfile = false,
    this.hasPodfileLock = false,
    this.swiftPackageManagerDisabled = false,
    this.uisceneLifecycleStatus = UISceneLifecycleStatus.absent,
    this.appDelegateLifecycleStyle = AppDelegateLifecycleStyle.absent,
    this.appDelegate = const IosAppDelegateSnapshot(),
    this.nativePluginDeploymentTargets = const [],
    this.legacyBuildSettings = const [],
    this.hasLegacyFlutterPodfileIntegration = false,
    this.hasPotentialCocoaPodsOnlyPlugins = false,
    this.hasFlutterXcconfigReferences = false,
    this.hasSuspiciousFlutterXcconfigReferences = false,
    this.hasOldFlutterBuildScriptReferences = false,
    this.hasLegacyFlutterFrameworkEmbedding = false,
  });

  /// Lowest deployment target found across iOS project files.
  final Version? deploymentTarget;

  /// Platform target declared in `ios/Podfile`.
  final Version? podfilePlatformTarget;

  /// One-based line number of the Podfile platform declaration.
  final int? podfilePlatformLine;

  /// Deployment targets declared per Xcode build configuration.
  final List<IosBuildConfigurationDeploymentTarget>
  deploymentTargetsByConfiguration;

  /// Whether CocoaPods project files are present.
  final bool usesCocoaPods;

  /// Whether Swift Package Manager references are present.
  final bool usesSwiftPM;

  /// Whether both CocoaPods and SwiftPM integration signals are present.
  final bool usesMixedDependencyManagement;

  /// Whether `ios/Podfile` exists.
  final bool hasPodfile;

  /// Whether `ios/Podfile.lock` exists.
  final bool hasPodfileLock;

  /// Whether Swift Package Manager is explicitly disabled.
  final bool swiftPackageManagerDisabled;

  /// Detected UIScene lifecycle configuration status.
  final UISceneLifecycleStatus uisceneLifecycleStatus;

  /// Detected AppDelegate lifecycle style.
  final AppDelegateLifecycleStyle appDelegateLifecycleStyle;

  /// Facts collected from the iOS AppDelegate source file.
  final IosAppDelegateSnapshot appDelegate;

  /// Native plugin deployment targets found in podspecs or packages.
  final List<IosPluginDeploymentTarget> nativePluginDeploymentTargets;

  /// Legacy Xcode build settings detected in project files.
  final List<IosLegacyBuildSetting> legacyBuildSettings;

  /// Whether the Podfile uses old Flutter helper integration.
  final bool hasLegacyFlutterPodfileIntegration;

  /// Whether local plugin files suggest CocoaPods-only plugins.
  final bool hasPotentialCocoaPodsOnlyPlugins;

  /// Whether Flutter xcconfig files are referenced by the Xcode project.
  final bool hasFlutterXcconfigReferences;

  /// Whether Flutter xcconfig references look stale or suspicious.
  final bool hasSuspiciousFlutterXcconfigReferences;

  /// Whether old Flutter build script references were found.
  final bool hasOldFlutterBuildScriptReferences;

  /// Whether legacy Flutter framework embedding references were found.
  final bool hasLegacyFlutterFrameworkEmbedding;

  /// Converts this snapshot to the JSON report shape.
  Map<String, Object?> toJson() => {
    'deploymentTarget': deploymentTarget?.toString(),
    'podfilePlatformTarget': podfilePlatformTarget?.toString(),
    if (podfilePlatformLine != null) 'podfilePlatformLine': podfilePlatformLine,
    'deploymentTargetsByConfiguration': deploymentTargetsByConfiguration
        .map((target) => target.toJson())
        .toList(),
    'usesCocoaPods': usesCocoaPods,
    'usesSwiftPM': usesSwiftPM,
    'usesMixedDependencyManagement': usesMixedDependencyManagement,
    'hasPodfile': hasPodfile,
    'hasPodfileLock': hasPodfileLock,
    'swiftPackageManagerDisabled': swiftPackageManagerDisabled,
    'uisceneLifecycleStatus': uisceneLifecycleStatus.label,
    'appDelegateLifecycleStyle': appDelegateLifecycleStyle.label,
    'appDelegate': appDelegate.toJson(),
    'nativePluginDeploymentTargets': nativePluginDeploymentTargets
        .map((target) => target.toJson())
        .toList(),
    'legacyBuildSettings': legacyBuildSettings
        .map((setting) => setting.toJson())
        .toList(),
    'hasLegacyFlutterPodfileIntegration': hasLegacyFlutterPodfileIntegration,
    'hasPotentialCocoaPodsOnlyPlugins': hasPotentialCocoaPodsOnlyPlugins,
    'hasFlutterXcconfigReferences': hasFlutterXcconfigReferences,
    'hasSuspiciousFlutterXcconfigReferences':
        hasSuspiciousFlutterXcconfigReferences,
    'hasOldFlutterBuildScriptReferences': hasOldFlutterBuildScriptReferences,
    'hasLegacyFlutterFrameworkEmbedding': hasLegacyFlutterFrameworkEmbedding,
  };
}

/// iOS deployment target declared for one Xcode build configuration.
class IosBuildConfigurationDeploymentTarget {
  /// Creates a build-configuration deployment target entry.
  const IosBuildConfigurationDeploymentTarget({
    required this.configuration,
    required this.target,
    required this.sourceFile,
    this.line,
  });

  /// Xcode build configuration name.
  final String configuration;

  /// Deployment target declared for the configuration.
  final Version target;

  /// Relative file path where the target was found.
  final String sourceFile;

  /// One-based line number where the target was found.
  final int? line;

  /// Converts this entry to the JSON report shape.
  Map<String, Object?> toJson() => {
    'configuration': configuration,
    'target': target.toString(),
    'sourceFile': sourceFile,
    if (line != null) 'line': line,
  };
}

/// iOS deployment target declared by a native plugin.
class IosPluginDeploymentTarget {
  /// Creates a native plugin deployment target entry.
  const IosPluginDeploymentTarget({
    required this.name,
    required this.target,
    required this.sourceFile,
    required this.sourceKind,
    this.line,
  });

  /// Plugin or package name.
  final String name;

  /// Deployment target declared by the plugin.
  final Version target;

  /// Relative file path where the target was found.
  final String sourceFile;

  /// Kind of source file, such as podspec or Swift package.
  final String sourceKind;

  /// One-based line number where the target was found.
  final int? line;

  /// Converts this entry to the JSON report shape.
  Map<String, Object?> toJson() => {
    'name': name,
    'target': target.toString(),
    'sourceFile': sourceFile,
    'sourceKind': sourceKind,
    if (line != null) 'line': line,
  };
}

/// Legacy iOS build setting detected in a project file.
class IosLegacyBuildSetting {
  /// Creates a legacy build setting entry.
  const IosLegacyBuildSetting({
    required this.key,
    required this.value,
    required this.sourceFile,
    this.line,
  });

  /// Build setting key.
  final String key;

  /// Build setting value.
  final String value;

  /// Relative file path where the setting was found.
  final String sourceFile;

  /// One-based line number where the setting was found.
  final int? line;

  /// Converts this entry to the JSON report shape.
  Map<String, Object?> toJson() => {
    'key': key,
    'value': value,
    'sourceFile': sourceFile,
    if (line != null) 'line': line,
  };
}

/// Facts detected in an iOS AppDelegate source file.
class IosAppDelegateSnapshot {
  /// Creates an AppDelegate snapshot.
  const IosAppDelegateSnapshot({
    this.sourceFile,
    this.didFinishLaunchingLine,
    this.isCustom = false,
    this.manualGeneratedPluginRegistrant = false,
    this.generatedPluginRegistrantLine,
    this.registersPluginsInDidFinishLaunching = false,
    this.customPlatformIntegration = false,
    this.customPlatformIntegrationLine,
    this.usesFlutterImplicitEngineDelegate = false,
    this.flutterImplicitEngineDelegateLine,
    this.hasDidInitializeImplicitFlutterEngine = false,
    this.didInitializeImplicitFlutterEngineLine,
    this.usesLegacyFlutterEngineInitialization = false,
    this.legacyFlutterEngineInitializationLine,
    this.usesObjectiveCLegacyIntegration = false,
  });

  /// Relative AppDelegate source file path.
  final String? sourceFile;

  /// Line where `didFinishLaunching` appears.
  final int? didFinishLaunchingLine;

  /// Whether the AppDelegate contains custom integration code.
  final bool isCustom;

  /// Whether plugins are manually registered.
  final bool manualGeneratedPluginRegistrant;

  /// Line where manual plugin registration appears.
  final int? generatedPluginRegistrantLine;

  /// Whether plugin registration happens in `didFinishLaunching`.
  final bool registersPluginsInDidFinishLaunching;

  /// Whether custom platform integration code was detected.
  final bool customPlatformIntegration;

  /// Line where custom platform integration was detected.
  final int? customPlatformIntegrationLine;

  /// Whether `FlutterImplicitEngineDelegate` is referenced.
  final bool usesFlutterImplicitEngineDelegate;

  /// Line where `FlutterImplicitEngineDelegate` is referenced.
  final int? flutterImplicitEngineDelegateLine;

  /// Whether `didInitializeImplicitFlutterEngine` is implemented.
  final bool hasDidInitializeImplicitFlutterEngine;

  /// Line where `didInitializeImplicitFlutterEngine` appears.
  final int? didInitializeImplicitFlutterEngineLine;

  /// Whether legacy Flutter engine initialization code was detected.
  final bool usesLegacyFlutterEngineInitialization;

  /// Line where legacy engine initialization was detected.
  final int? legacyFlutterEngineInitializationLine;

  /// Whether Objective-C legacy integration was detected.
  final bool usesObjectiveCLegacyIntegration;

  /// Converts this snapshot to the JSON report shape.
  Map<String, Object?> toJson() => {
    if (sourceFile != null) 'sourceFile': sourceFile,
    if (didFinishLaunchingLine != null)
      'didFinishLaunchingLine': didFinishLaunchingLine,
    'isCustom': isCustom,
    'manualGeneratedPluginRegistrant': manualGeneratedPluginRegistrant,
    if (generatedPluginRegistrantLine != null)
      'generatedPluginRegistrantLine': generatedPluginRegistrantLine,
    'registersPluginsInDidFinishLaunching':
        registersPluginsInDidFinishLaunching,
    'customPlatformIntegration': customPlatformIntegration,
    if (customPlatformIntegrationLine != null)
      'customPlatformIntegrationLine': customPlatformIntegrationLine,
    'usesFlutterImplicitEngineDelegate': usesFlutterImplicitEngineDelegate,
    if (flutterImplicitEngineDelegateLine != null)
      'flutterImplicitEngineDelegateLine': flutterImplicitEngineDelegateLine,
    'hasDidInitializeImplicitFlutterEngine':
        hasDidInitializeImplicitFlutterEngine,
    if (didInitializeImplicitFlutterEngineLine != null)
      'didInitializeImplicitFlutterEngineLine':
          didInitializeImplicitFlutterEngineLine,
    'usesLegacyFlutterEngineInitialization':
        usesLegacyFlutterEngineInitialization,
    if (legacyFlutterEngineInitializationLine != null)
      'legacyFlutterEngineInitializationLine':
          legacyFlutterEngineInitializationLine,
    'usesObjectiveCLegacyIntegration': usesObjectiveCLegacyIntegration,
  };
}
