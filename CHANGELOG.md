## 1.0.3

- Fixed the changelog so it references the current package versions.

## 1.0.2

- Added package documentation.

## 1.0.1

- Expanded the scanner beyond Android-only recovery checks with an iOS project
  snapshot.
- Added iOS compatibility findings for deployment targets, Podfile platform
  baselines, CocoaPods-only projects, mixed CocoaPods and SwiftPM dependency
  management, SwiftPM opt-out flags, and local plugin deployment target
  conflicts.
- Added iOS runner migration signals for missing or incomplete UIScene setup,
  custom AppDelegate lifecycle code, manual `GeneratedPluginRegistrant` calls,
  legacy Flutter engine initialization, old Flutter build scripts, legacy
  Flutter.framework embedding, and legacy/custom Xcode build settings.
- Included iOS facts in plain text and JSON scan reports.
- Added fixture coverage for legacy CocoaPods, modern SwiftPM, mixed dependency
  management, old deployment targets, missing UIScene configuration, and custom
  legacy AppDelegate projects.
- Updated package metadata and refreshed locked dev dependency versions for the
  pub.dev release.

## 1.0.0

Initial stable release.

- Added `flutter_restore scan <path>` CLI.
- Added plain text and JSON compatibility reports.
- Added static scanning for Flutter, pub, and Android project files.
- Added compatibility findings for Gradle, Android Gradle Plugin, Java, SDK,
  legacy Flutter Gradle integration, `.flutter-plugins`, and Android v1
  embedding signals.
- Added fixture-based scanner, rule, and CLI test coverage.
