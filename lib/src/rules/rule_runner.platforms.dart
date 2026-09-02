part of 'rule_runner.dart';

abstract class _PlatformStructureRule extends CompatibilityRule {
  const _PlatformStructureRule({
    required this.platform,
    required this.title,
    required this.directory,
  });

  final ScanPlatform platform;
  final String title;
  final String directory;

  @override
  Set<ScanPlatform> get platforms => {platform};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final platformSnapshot = switch (platform) {
      ScanPlatform.linux => snapshot.linux,
      ScanPlatform.windows => snapshot.windows,
      ScanPlatform.web => snapshot.web,
      ScanPlatform.android || ScanPlatform.ios => throw StateError(
        'Unsupported platform structure rule: ${platform.label}',
      ),
    };

    if (!platformSnapshot.hasDirectory) {
      yield Finding(
        id: '${platform.label}-platform-directory-missing',
        severity: Severity.info,
        title: '$title target is not present',
        message:
            'The project does not contain a $directory directory, so this Flutter target has not been added yet.',
        location: directory,
        sourceFile: directory,
        recommendation:
            'Run flutter create --platforms=${platform.label} . if this target should be restored.',
      );
      return;
    }

    if (platformSnapshot.missingExpectedFiles.isNotEmpty) {
      yield Finding(
        id: '${platform.label}-runner-files-incomplete',
        severity: Severity.medium,
        title: '$title runner files look incomplete',
        message:
            'The $directory directory exists, but expected Flutter runner files are missing.',
        location: directory,
        sourceFile: directory,
        detectedValue: platformSnapshot.missingExpectedFiles.join(', '),
        recommendation:
            'Compare this target with a freshly generated Flutter $title runner and restore the missing files.',
      );
    }
  }
}

/// Checks Linux desktop target structure.
class LinuxProjectStructureRule extends _PlatformStructureRule {
  /// Creates a Linux target structure rule.
  const LinuxProjectStructureRule()
    : super(platform: ScanPlatform.linux, title: 'Linux', directory: 'linux');
}

/// Checks Windows desktop target structure.
class WindowsProjectStructureRule extends _PlatformStructureRule {
  /// Creates a Windows target structure rule.
  const WindowsProjectStructureRule()
    : super(
        platform: ScanPlatform.windows,
        title: 'Windows',
        directory: 'windows',
      );
}

/// Checks web target structure.
class WebProjectStructureRule extends _PlatformStructureRule {
  /// Creates a web target structure rule.
  const WebProjectStructureRule()
    : super(platform: ScanPlatform.web, title: 'Web', directory: 'web');
}

/// Checks Linux CMake setup against Flutter's generated runner baseline.
class LinuxCmakeRule extends CompatibilityRule {
  /// Creates a Linux CMake rule.
  const LinuxCmakeRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.linux};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final linux = snapshot.linux;
    if (!linux.hasDirectory) {
      return;
    }

    final cmake = linux.cmakeMinimumVersion;
    if (cmake != null && cmake < Version(3, 10, 0)) {
      yield Finding(
        id: 'linux-cmake-minimum-too-low',
        severity: Severity.high,
        title: 'Linux CMake minimum is below Flutter runner baseline',
        message:
            'linux/CMakeLists.txt requires CMake $cmake; current Flutter Linux runners expect at least CMake 3.10.',
        location: _location(
          linux.cmakeMinimumVersionSourceFile ?? 'linux/CMakeLists.txt',
          linux.cmakeMinimumVersionLine,
        ),
        sourceFile: linux.cmakeMinimumVersionSourceFile,
        line: linux.cmakeMinimumVersionLine,
        detectedValue: cmake.toString(),
        recommendation:
            'Regenerate or update the Linux runner CMake files before restoring this target.',
      );
    }

    if (!linux.hasGtkPkgConfig) {
      yield const Finding(
        id: 'linux-gtk-pkg-config-missing',
        severity: Severity.medium,
        title: 'Linux GTK pkg-config wiring not detected',
        message:
            'The Linux CMake file does not request GTK through pkg-config, which current Flutter Linux builds rely on.',
        location: 'linux/CMakeLists.txt',
        sourceFile: 'linux/CMakeLists.txt',
        recommendation:
            'Compare linux/CMakeLists.txt with a current Flutter Linux runner and restore the GTK pkg-config block.',
      );
    }
  }
}

/// Checks Windows CMake setup against Flutter's generated runner baseline.
class WindowsCmakeRule extends CompatibilityRule {
  /// Creates a Windows CMake rule.
  const WindowsCmakeRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.windows};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final windows = snapshot.windows;
    if (!windows.hasDirectory) {
      return;
    }

    final cmake = windows.cmakeMinimumVersion;
    if (cmake != null && cmake < Version(3, 14, 0)) {
      yield Finding(
        id: 'windows-cmake-minimum-too-low',
        severity: Severity.high,
        title: 'Windows CMake minimum is below Flutter runner baseline',
        message:
            'windows/CMakeLists.txt requires CMake $cmake; current Flutter Windows runners expect at least CMake 3.14.',
        location: _location(
          windows.cmakeMinimumVersionSourceFile ?? 'windows/CMakeLists.txt',
          windows.cmakeMinimumVersionLine,
        ),
        sourceFile: windows.cmakeMinimumVersionSourceFile,
        line: windows.cmakeMinimumVersionLine,
        detectedValue: cmake.toString(),
        recommendation:
            'Regenerate or update the Windows runner CMake files before restoring this target.',
      );
    }
  }
}

/// Detects Windows runners that predate Flutter 2.5's message pump migration.
class WindowsRunLoopRule extends CompatibilityRule {
  /// Creates a Windows run loop migration rule.
  const WindowsRunLoopRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.windows};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final windows = snapshot.windows;
    if (!windows.hasDirectory || !windows.usesLegacyWindowsRunLoop) {
      return;
    }

    yield Finding(
      id: 'windows-legacy-run-loop',
      severity: Severity.high,
      title: 'Legacy Windows run loop detected',
      message:
          'This Windows runner still contains pre-Flutter 2.5 run loop files or references.',
      location: _location(
        windows.legacyWindowsRunLoopSourceFile ?? 'windows/runner/run_loop.h',
        windows.legacyWindowsRunLoopLine,
      ),
      sourceFile:
          windows.legacyWindowsRunLoopSourceFile ?? 'windows/runner/run_loop.h',
      line: windows.legacyWindowsRunLoopLine,
      detectedValue: 'run_loop',
      recommendation:
          'Regenerate windows/runner with flutter create --platforms=windows . and reapply any custom native changes.',
    );
  }
}

/// Checks whether Windows executable version metadata follows Flutter tooling.
class WindowsVersionInfoRule extends CompatibilityRule {
  /// Creates a Windows version info rule.
  const WindowsVersionInfoRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.windows};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final windows = snapshot.windows;
    if (!windows.hasDirectory || windows.supportsWindowsVersionInfo) {
      return;
    }

    yield const Finding(
      id: 'windows-version-info-not-tool-driven',
      severity: Severity.medium,
      title: 'Windows version metadata is not wired to Flutter build values',
      message:
          'Runner.rc does not reference Flutter version macros, so the executable version may ignore pubspec.yaml and build arguments.',
      location: 'windows/runner/Runner.rc',
      sourceFile: 'windows/runner/Runner.rc',
      recommendation:
          'Regenerate windows/runner/Runner.rc or add the Flutter version macro guards used by current Windows runners.',
    );
  }
}

/// Checks Windows dark title bar support introduced for Flutter 3.7 runners.
class WindowsDarkTitleBarRule extends CompatibilityRule {
  /// Creates a Windows dark title bar rule.
  const WindowsDarkTitleBarRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.windows};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final windows = snapshot.windows;
    if (!windows.hasDirectory || windows.supportsWindowsDarkTitleBar) {
      return;
    }

    yield const Finding(
      id: 'windows-dark-title-bar-support-missing',
      severity: Severity.medium,
      title: 'Windows dark title bar support not detected',
      message:
          'The Windows runner lacks the native dark-title-bar integration added for Flutter 3.7-era projects.',
      location: 'windows/runner/win32_window.cpp',
      sourceFile: 'windows/runner/win32_window.cpp',
      recommendation:
          'Regenerate windows/runner/win32_window.cpp and windows/runner/CMakeLists.txt, then reapply local changes.',
    );
  }
}

/// Checks Windows first-frame redraw migration from Flutter 3.13.
class WindowsShowWindowRule extends CompatibilityRule {
  /// Creates a Windows show-window migration rule.
  const WindowsShowWindowRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.windows};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final windows = snapshot.windows;
    if (!windows.hasDirectory || windows.hasWindowsForceRedraw) {
      return;
    }

    yield const Finding(
      id: 'windows-force-redraw-missing',
      severity: Severity.medium,
      title: 'Windows first-frame ForceRedraw call not detected',
      message:
          'Modified Windows runners from Flutter 3.7/3.10 can fail to show the window without the post-callback ForceRedraw migration.',
      location: 'windows/runner/flutter_window.cpp',
      sourceFile: 'windows/runner/flutter_window.cpp',
      recommendation:
          'Check flutter_window.cpp against the Flutter 3.13 show-window migration and add flutter_controller_->ForceRedraw() when needed.',
    );
  }
}

/// Checks Flutter web initialization files for deprecated bootstrap patterns.
class WebBootstrapRule extends CompatibilityRule {
  /// Creates a web bootstrap rule.
  const WebBootstrapRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.web};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final web = snapshot.web;
    if (!web.hasDirectory) {
      return;
    }

    if (!web.webHasBootstrap) {
      yield const Finding(
        id: 'web-bootstrap-missing',
        severity: Severity.high,
        title: 'Flutter web bootstrap not detected',
        message:
            'web/index.html does not reference flutter_bootstrap.js, inline {{flutter_bootstrap_js}}, or the current Flutter loader.',
        location: 'web/index.html',
        sourceFile: 'web/index.html',
        recommendation:
            'Update web/index.html to use flutter_bootstrap.js or the documented Flutter web bootstrap tokens.',
      );
    }

    if (!web.webHasBaseHref) {
      yield const Finding(
        id: 'web-base-href-missing',
        severity: Severity.medium,
        title: 'Web base href is missing',
        message:
            'web/index.html does not contain a base href tag, which controls how Flutter web resolves routes and assets.',
        location: 'web/index.html',
        sourceFile: 'web/index.html',
        recommendation:
            'Add <base href="/"> or set it to the subpath where the app is hosted.',
      );
    }

    if (web.webUsesLegacyLoadEntrypoint) {
      yield Finding(
        id: 'web-legacy-load-entrypoint',
        severity: Severity.medium,
        title: 'Deprecated Flutter web loadEntrypoint API detected',
        message:
            'web/index.html still calls _flutter.loader.loadEntrypoint instead of _flutter.loader.load.',
        location: _location('web/index.html', web.webLegacyLoadEntrypointLine),
        sourceFile: 'web/index.html',
        line: web.webLegacyLoadEntrypointLine,
        detectedValue: '_flutter.loader.loadEntrypoint',
        recommendation:
            'Migrate custom initialization to _flutter.loader.load() and the current bootstrap template tokens.',
      );
    }

    if (web.webHasCustomBootstrap &&
        (!web.webCustomBootstrapHasFlutterJsToken ||
            !web.webCustomBootstrapHasBuildConfigToken ||
            !web.webCustomBootstrapCallsLoaderLoad)) {
      yield const Finding(
        id: 'web-custom-bootstrap-incomplete',
        severity: Severity.high,
        title: 'Custom Flutter web bootstrap is incomplete',
        message:
            'web/flutter_bootstrap.js exists but does not contain all required Flutter bootstrap tokens and loader call.',
        location: 'web/flutter_bootstrap.js',
        sourceFile: 'web/flutter_bootstrap.js',
        recommendation:
            'Ensure custom bootstrap includes {{flutter_js}}, {{flutter_build_config}}, and _flutter.loader.load().',
      );
    }
  }
}

/// Checks Flutter web service worker patterns deprecated by current tooling.
class WebServiceWorkerRule extends CompatibilityRule {
  /// Creates a web service worker rule.
  const WebServiceWorkerRule();

  @override
  Set<ScanPlatform> get platforms => const {ScanPlatform.web};

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final web = snapshot.web;
    if (!web.hasDirectory) {
      return;
    }

    if (web.webUsesDeprecatedServiceWorkerVersion) {
      yield Finding(
        id: 'web-deprecated-service-worker-version',
        severity: Severity.medium,
        title: 'Deprecated serviceWorkerVersion variable detected',
        message:
            'web/index.html declares serviceWorkerVersion manually; current Flutter web templates use the service worker template token for custom service worker flows.',
        location: _location(
          'web/index.html',
          web.webDeprecatedServiceWorkerVersionLine,
        ),
        sourceFile: 'web/index.html',
        line: web.webDeprecatedServiceWorkerVersionLine,
        detectedValue: 'serviceWorkerVersion',
        recommendation:
            'Remove the local variable and use {{flutter_service_worker_version}} only if you maintain a custom service worker.',
      );
    }

    if (web.webManuallyRegistersServiceWorker) {
      yield Finding(
        id: 'web-manual-service-worker-registration',
        severity: Severity.medium,
        title: 'Manual Flutter service worker registration detected',
        message:
            'Flutter no longer generates or manages a service worker by default, so old manual flutter_service_worker.js registration is a migration risk.',
        location: _location(
          'web/index.html',
          web.webManualServiceWorkerRegistrationLine,
        ),
        sourceFile: 'web/index.html',
        line: web.webManualServiceWorkerRegistrationLine,
        detectedValue: 'navigator.serviceWorker.register',
        recommendation:
            'Remove old generated service worker wiring or replace it with an explicit custom service worker strategy.',
      );
    }
  }
}

/// Detects obsolete Linux/Windows TargetPlatform override workarounds.
class DesktopTargetPlatformOverrideRule extends CompatibilityRule {
  /// Creates a desktop platform override rule.
  const DesktopTargetPlatformOverrideRule();

  @override
  Set<ScanPlatform> get platforms => const {
    ScanPlatform.linux,
    ScanPlatform.windows,
  };

  @override
  Iterable<Finding> evaluate(
    ProjectSnapshot snapshot,
    CompatibilityData data,
  ) sync* {
    final sourceFile =
        snapshot.linux.legacyTargetPlatformOverrideSourceFile ??
        snapshot.windows.legacyTargetPlatformOverrideSourceFile;
    final line =
        snapshot.linux.legacyTargetPlatformOverrideLine ??
        snapshot.windows.legacyTargetPlatformOverrideLine;
    if (sourceFile == null) {
      return;
    }

    yield Finding(
      id: 'desktop-legacy-target-platform-override',
      severity: Severity.medium,
      title: 'Legacy desktop TargetPlatform override detected',
      message:
          'Dart code still overrides Linux/Windows to TargetPlatform.fuchsia, a workaround that became obsolete after Flutter added native TargetPlatform.linux and TargetPlatform.windows values.',
      location: _location(sourceFile, line),
      sourceFile: sourceFile,
      line: line,
      detectedValue:
          'debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia',
      recommendation:
          'Remove the override and handle TargetPlatform.linux and TargetPlatform.windows explicitly where needed.',
    );
  }
}
