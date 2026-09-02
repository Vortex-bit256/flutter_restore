# Changelog

## 1.1.0

### Added

- Added `scan --platform all|android|ios|linux|windows|web` to scope reports
  and rule evaluation to one platform or every supported platform.
- Added Linux, Windows, and web project snapshots to `ProjectSnapshot`.
- Added Linux target structure checks for runner completeness, CMake minimum
  version, and GTK pkg-config wiring.
- Added Windows target checks for runner completeness, CMake minimum version,
  legacy run loop files, version metadata wiring, dark title bar support, and
  the Flutter 3.13 first-frame `ForceRedraw` migration.
- Added web target checks for runner completeness, current bootstrap wiring,
  `<base href>`, deprecated `loadEntrypoint`, deprecated
  `serviceWorkerVersion`, manual service worker registration, and incomplete
  custom `flutter_bootstrap.js` files.
- Added a desktop migration rule for obsolete
  `debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia` workarounds.
- Added fixture coverage for modern Linux, Windows, and web targets.
- Added legacy desktop/web fixtures that exercise the new platform migration
  rules.

### Changed

- Split `rule_runner.dart` into Dart `part` files for project-wide, Android,
  iOS, and platform-specific rules.
- Updated plain text and JSON reports so selected platforms are reflected in
  both output formats.
- Reworked the README into a structured pub.dev-oriented format with table of
  contents, usage, supported platform, rule, report, and development sections.

## 1.0.3

### Fixed

- Fixed the changelog so it references the current package versions.

## 1.0.2

### Added

- Added package documentation.

## 1.0.1

### Added

- Added an iOS project snapshot alongside the Android snapshot.
- Added iOS compatibility findings for deployment targets, Podfile platform
  baselines, CocoaPods-only projects, mixed CocoaPods and SwiftPM dependency
  management, SwiftPM opt-out flags, and local plugin deployment target
  conflicts.
- Added iOS runner migration signals for missing or incomplete UIScene setup,
  custom AppDelegate lifecycle code, manual `GeneratedPluginRegistrant` calls,
  legacy Flutter engine initialization, old Flutter build scripts, legacy
  Flutter.framework embedding, and legacy/custom Xcode build settings.
- Added fixture coverage for legacy CocoaPods, modern SwiftPM, mixed dependency
  management, old deployment targets, missing UIScene configuration, and custom
  legacy AppDelegate projects.

### Changed

- Included iOS facts in plain text and JSON scan reports.
- Updated package metadata and refreshed locked dev dependency versions for the
  pub.dev release.

## 1.0.0

Initial stable release.

### Added

- Added `flutter_restore scan <path>` CLI.
- Added plain text and JSON compatibility reports.
- Added static scanning for Flutter, pub, and Android project files.
- Added compatibility findings for Gradle, Android Gradle Plugin, Java, SDK,
  legacy Flutter Gradle integration, `.flutter-plugins`, and Android v1
  embedding signals.
- Added fixture-based scanner, rule, and CLI test coverage.
