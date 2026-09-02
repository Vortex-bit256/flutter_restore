import 'package:pub_semver/pub_semver.dart';

/// Basic facts discovered for a non-mobile Flutter target platform.
class PlatformSnapshot {
  /// Creates a platform snapshot.
  const PlatformSnapshot({
    required this.name,
    this.hasDirectory = false,
    this.detectedFiles = const [],
    this.missingExpectedFiles = const [],
    this.cmakeMinimumVersion,
    this.cmakeMinimumVersionSourceFile,
    this.cmakeMinimumVersionLine,
    this.hasGtkPkgConfig = false,
    this.usesLegacyWindowsRunLoop = false,
    this.legacyWindowsRunLoopSourceFile,
    this.legacyWindowsRunLoopLine,
    this.supportsWindowsDarkTitleBar = false,
    this.supportsWindowsVersionInfo = false,
    this.hasWindowsForceRedraw = false,
    this.usesLegacyTargetPlatformOverride = false,
    this.legacyTargetPlatformOverrideSourceFile,
    this.legacyTargetPlatformOverrideLine,
    this.webHasBootstrap = false,
    this.webHasBaseHref = false,
    this.webUsesDeprecatedServiceWorkerVersion = false,
    this.webDeprecatedServiceWorkerVersionLine,
    this.webManuallyRegistersServiceWorker = false,
    this.webManualServiceWorkerRegistrationLine,
    this.webUsesLegacyLoadEntrypoint = false,
    this.webLegacyLoadEntrypointLine,
    this.webHasCustomBootstrap = false,
    this.webCustomBootstrapHasFlutterJsToken = false,
    this.webCustomBootstrapHasBuildConfigToken = false,
    this.webCustomBootstrapCallsLoaderLoad = false,
  });

  /// Platform directory name.
  final String name;

  /// Whether the platform directory exists in the project.
  final bool hasDirectory;

  /// Expected files that were found.
  final List<String> detectedFiles;

  /// Expected files that were not found.
  final List<String> missingExpectedFiles;

  /// `cmake_minimum_required` value parsed from the platform CMake file.
  final Version? cmakeMinimumVersion;

  /// Relative file path where [cmakeMinimumVersion] was found.
  final String? cmakeMinimumVersionSourceFile;

  /// One-based line number for [cmakeMinimumVersion].
  final int? cmakeMinimumVersionLine;

  /// Whether the Linux CMake files request GTK through pkg-config.
  final bool hasGtkPkgConfig;

  /// Whether Windows runner still contains pre-2.5 `run_loop` files.
  final bool usesLegacyWindowsRunLoop;

  /// Relative file path where a legacy Windows run loop signal was found.
  final String? legacyWindowsRunLoopSourceFile;

  /// One-based line number where a legacy Windows run loop signal was found.
  final int? legacyWindowsRunLoopLine;

  /// Whether Windows runner contains dark title bar support.
  final bool supportsWindowsDarkTitleBar;

  /// Whether Windows resources use Flutter-provided version macros.
  final bool supportsWindowsVersionInfo;

  /// Whether Windows `flutter_window.cpp` forces redraw after first frame.
  final bool hasWindowsForceRedraw;

  /// Whether Dart code still overrides desktop target platforms to fuchsia.
  final bool usesLegacyTargetPlatformOverride;

  /// Relative Dart file path where the legacy platform override was found.
  final String? legacyTargetPlatformOverrideSourceFile;

  /// One-based line number where the legacy platform override was found.
  final int? legacyTargetPlatformOverrideLine;

  /// Whether web bootstrap wiring was found in `web/index.html`.
  final bool webHasBootstrap;

  /// Whether `web/index.html` contains a `<base href=...>` tag.
  final bool webHasBaseHref;

  /// Whether `web/index.html` uses the deprecated serviceWorkerVersion var.
  final bool webUsesDeprecatedServiceWorkerVersion;

  /// One-based line number where the deprecated service worker var was found.
  final int? webDeprecatedServiceWorkerVersionLine;

  /// Whether `web/index.html` manually registers Flutter's service worker.
  final bool webManuallyRegistersServiceWorker;

  /// One-based line number where manual service worker registration was found.
  final int? webManualServiceWorkerRegistrationLine;

  /// Whether web bootstrap still calls deprecated `loadEntrypoint`.
  final bool webUsesLegacyLoadEntrypoint;

  /// One-based line number where `loadEntrypoint` was found.
  final int? webLegacyLoadEntrypointLine;

  /// Whether `web/flutter_bootstrap.js` exists.
  final bool webHasCustomBootstrap;

  /// Whether custom bootstrap contains the `{{flutter_js}}` token.
  final bool webCustomBootstrapHasFlutterJsToken;

  /// Whether custom bootstrap contains the `{{flutter_build_config}}` token.
  final bool webCustomBootstrapHasBuildConfigToken;

  /// Whether custom bootstrap calls `_flutter.loader.load()`.
  final bool webCustomBootstrapCallsLoaderLoad;

  /// Converts this snapshot to the JSON report shape.
  Map<String, Object?> toJson() => {
    'hasDirectory': hasDirectory,
    'detectedFiles': detectedFiles,
    'missingExpectedFiles': missingExpectedFiles,
    if (cmakeMinimumVersion != null)
      'cmakeMinimumVersion': cmakeMinimumVersion.toString(),
    if (cmakeMinimumVersionSourceFile != null)
      'cmakeMinimumVersionSourceFile': cmakeMinimumVersionSourceFile,
    if (cmakeMinimumVersionLine != null)
      'cmakeMinimumVersionLine': cmakeMinimumVersionLine,
    'hasGtkPkgConfig': hasGtkPkgConfig,
    'usesLegacyWindowsRunLoop': usesLegacyWindowsRunLoop,
    if (legacyWindowsRunLoopSourceFile != null)
      'legacyWindowsRunLoopSourceFile': legacyWindowsRunLoopSourceFile,
    if (legacyWindowsRunLoopLine != null)
      'legacyWindowsRunLoopLine': legacyWindowsRunLoopLine,
    'supportsWindowsDarkTitleBar': supportsWindowsDarkTitleBar,
    'supportsWindowsVersionInfo': supportsWindowsVersionInfo,
    'hasWindowsForceRedraw': hasWindowsForceRedraw,
    'usesLegacyTargetPlatformOverride': usesLegacyTargetPlatformOverride,
    if (legacyTargetPlatformOverrideSourceFile != null)
      'legacyTargetPlatformOverrideSourceFile':
          legacyTargetPlatformOverrideSourceFile,
    if (legacyTargetPlatformOverrideLine != null)
      'legacyTargetPlatformOverrideLine': legacyTargetPlatformOverrideLine,
    'webHasBootstrap': webHasBootstrap,
    'webHasBaseHref': webHasBaseHref,
    'webUsesDeprecatedServiceWorkerVersion':
        webUsesDeprecatedServiceWorkerVersion,
    if (webDeprecatedServiceWorkerVersionLine != null)
      'webDeprecatedServiceWorkerVersionLine':
          webDeprecatedServiceWorkerVersionLine,
    'webManuallyRegistersServiceWorker': webManuallyRegistersServiceWorker,
    if (webManualServiceWorkerRegistrationLine != null)
      'webManualServiceWorkerRegistrationLine':
          webManualServiceWorkerRegistrationLine,
    'webUsesLegacyLoadEntrypoint': webUsesLegacyLoadEntrypoint,
    if (webLegacyLoadEntrypointLine != null)
      'webLegacyLoadEntrypointLine': webLegacyLoadEntrypointLine,
    'webHasCustomBootstrap': webHasCustomBootstrap,
    'webCustomBootstrapHasFlutterJsToken': webCustomBootstrapHasFlutterJsToken,
    'webCustomBootstrapHasBuildConfigToken':
        webCustomBootstrapHasBuildConfigToken,
    'webCustomBootstrapCallsLoaderLoad': webCustomBootstrapCallsLoaderLoad,
  };
}
