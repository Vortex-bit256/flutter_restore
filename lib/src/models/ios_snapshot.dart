import 'package:pub_semver/pub_semver.dart';

enum UISceneLifecycleStatus {
  absent,
  complete,
  incomplete;

  String get label => switch (this) {
    UISceneLifecycleStatus.absent => 'absent',
    UISceneLifecycleStatus.complete => 'complete',
    UISceneLifecycleStatus.incomplete => 'incomplete',
  };
}

enum AppDelegateLifecycleStyle {
  absent,
  appDelegateOnly,
  sceneBased;

  String get label => switch (this) {
    AppDelegateLifecycleStyle.absent => 'absent',
    AppDelegateLifecycleStyle.appDelegateOnly => 'appDelegateOnly',
    AppDelegateLifecycleStyle.sceneBased => 'sceneBased',
  };
}

class IosSnapshot {
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

  final Version? deploymentTarget;
  final Version? podfilePlatformTarget;
  final int? podfilePlatformLine;
  final List<IosBuildConfigurationDeploymentTarget>
  deploymentTargetsByConfiguration;
  final bool usesCocoaPods;
  final bool usesSwiftPM;
  final bool usesMixedDependencyManagement;
  final bool hasPodfile;
  final bool hasPodfileLock;
  final bool swiftPackageManagerDisabled;
  final UISceneLifecycleStatus uisceneLifecycleStatus;
  final AppDelegateLifecycleStyle appDelegateLifecycleStyle;
  final IosAppDelegateSnapshot appDelegate;
  final List<IosPluginDeploymentTarget> nativePluginDeploymentTargets;
  final List<IosLegacyBuildSetting> legacyBuildSettings;
  final bool hasLegacyFlutterPodfileIntegration;
  final bool hasPotentialCocoaPodsOnlyPlugins;
  final bool hasFlutterXcconfigReferences;
  final bool hasSuspiciousFlutterXcconfigReferences;
  final bool hasOldFlutterBuildScriptReferences;
  final bool hasLegacyFlutterFrameworkEmbedding;

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

class IosBuildConfigurationDeploymentTarget {
  const IosBuildConfigurationDeploymentTarget({
    required this.configuration,
    required this.target,
    required this.sourceFile,
    this.line,
  });

  final String configuration;
  final Version target;
  final String sourceFile;
  final int? line;

  Map<String, Object?> toJson() => {
    'configuration': configuration,
    'target': target.toString(),
    'sourceFile': sourceFile,
    if (line != null) 'line': line,
  };
}

class IosPluginDeploymentTarget {
  const IosPluginDeploymentTarget({
    required this.name,
    required this.target,
    required this.sourceFile,
    required this.sourceKind,
    this.line,
  });

  final String name;
  final Version target;
  final String sourceFile;
  final String sourceKind;
  final int? line;

  Map<String, Object?> toJson() => {
    'name': name,
    'target': target.toString(),
    'sourceFile': sourceFile,
    'sourceKind': sourceKind,
    if (line != null) 'line': line,
  };
}

class IosLegacyBuildSetting {
  const IosLegacyBuildSetting({
    required this.key,
    required this.value,
    required this.sourceFile,
    this.line,
  });

  final String key;
  final String value;
  final String sourceFile;
  final int? line;

  Map<String, Object?> toJson() => {
    'key': key,
    'value': value,
    'sourceFile': sourceFile,
    if (line != null) 'line': line,
  };
}

class IosAppDelegateSnapshot {
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

  final String? sourceFile;
  final int? didFinishLaunchingLine;
  final bool isCustom;
  final bool manualGeneratedPluginRegistrant;
  final int? generatedPluginRegistrantLine;
  final bool registersPluginsInDidFinishLaunching;
  final bool customPlatformIntegration;
  final int? customPlatformIntegrationLine;
  final bool usesFlutterImplicitEngineDelegate;
  final int? flutterImplicitEngineDelegateLine;
  final bool hasDidInitializeImplicitFlutterEngine;
  final int? didInitializeImplicitFlutterEngineLine;
  final bool usesLegacyFlutterEngineInitialization;
  final int? legacyFlutterEngineInitializationLine;
  final bool usesObjectiveCLegacyIntegration;

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
