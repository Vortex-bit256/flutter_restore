# flutter_restore

Static compatibility scanner for restoring and auditing old Flutter projects.

`flutter_restore` reads project files, builds a structured snapshot, runs
compatibility rules, and prints a plain text or JSON report. It does not run
Flutter, Gradle, Xcode, CMake, package resolution, or any build step.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Supported Platforms](#supported-platforms)
- [Rules](#rules)
- [Reports](#reports)
- [Exit Codes](#exit-codes)
- [Architecture](#architecture)
- [Development](#development)
- [Maintainers](#maintainers)

## Overview

Old Flutter projects often fail before application code is reached. The usual
failure points are stale runner files, obsolete Gradle or CMake setup, old web
bootstrap templates, deprecated platform integration, and native build settings
that modern tooling no longer expects.

`flutter_restore` helps answer:

```text
What is old, risky, or incompatible here before I try to run it?
```

The scanner is designed for:

- restoring abandoned Flutter applications
- auditing projects before migration
- estimating native migration effort
- producing machine-readable compatibility reports
- inspecting fragile repositories without executing old build scripts

## Installation

From this repository:

```sh
dart pub get
```

Run directly:

```sh
dart run flutter_restore scan path/to/flutter/project
```

Activate locally during development:

```sh
dart pub global activate --source path .
flutter_restore scan path/to/flutter/project
```

## Usage

Run a plain text scan:

```sh
dart run flutter_restore scan path/to/project
```

Run a JSON scan:

```sh
dart run flutter_restore scan --json path/to/project
```

Scan every supported platform:

```sh
dart run flutter_restore scan --platform all path/to/project
```

Scan a single platform:

```sh
dart run flutter_restore scan --platform android path/to/project
dart run flutter_restore scan --platform ios path/to/project
dart run flutter_restore scan --platform linux path/to/project
dart run flutter_restore scan --platform windows path/to/project
dart run flutter_restore scan --platform web path/to/project
```

## Supported Platforms

| Platform | Static Facts | Compatibility Rules |
| --- | --- | --- |
| Android | Gradle, AGP, Kotlin, SDK levels, Flutter Gradle integration, embedding | Java/Gradle, AGP/Gradle, AGP/Java, AGP/SDK, legacy Flutter Android migration |
| iOS | deployment targets, Podfile, SwiftPM, CocoaPods, AppDelegate, Xcode project settings | deployment target, dependency management, lifecycle, AppDelegate, Xcode project consistency |
| Linux | runner files, CMake baseline, GTK pkg-config wiring | target presence, runner completeness, CMake minimum, GTK pkg-config |
| Windows | runner files, CMake baseline, run loop, version metadata, title bar, first-frame redraw | target presence, runner completeness, CMake minimum, run loop, version info, dark title bar, ForceRedraw |
| Web | index template, manifest, favicon, bootstrap, service worker wiring, base href | target presence, runner completeness, bootstrap, loader API, service worker, base href |

## Rules

Rules emit `Finding` objects with stable ids, severity, location, detected
value, and recommendation fields when useful.

Project-wide rules:

- `missing-pubspec`
- `missing-pubspec-lock`
- `missing-metadata`

Android rules:

- `gradle-java-17-unsupported`
- `missing-gradle-version`
- `missing-agp-version`
- `unknown-agp-gradle-range`
- `agp-gradle-mismatch`
- `agp-java-requirement`
- `agp-compile-sdk-too-new`
- `legacy-flutter-gradle-apply`
- `flutter-plugins-file`
- `android-v1-embedding`
- `missing-plugin-dsl`

iOS rules:

- `ios-deployment-target-too-low`
- `ios-podfile-platform-too-low`
- `ios-deployment-target-mismatch`
- `ios-plugin-deployment-target-conflict`
- `ios-plugin-deployment-target-too-low`
- `ios-swiftpm-disabled`
- `ios-legacy-cocoapods-only`
- `ios-mixed-dependency-management`
- `ios-legacy-flutter-podfile-integration`
- `ios-potential-cocoapods-only-plugins`
- `ios-uiscene-incomplete`
- `ios-custom-appdelegate-only-lifecycle`
- `ios-manual-generated-plugin-registrant`
- `ios-custom-platform-integration-in-appdelegate`
- `ios-implicit-engine-lifecycle`
- `ios-legacy-flutter-engine-initialization`
- `ios-suspicious-flutter-xcconfig`
- `ios-old-flutter-build-script`
- `ios-legacy-framework-embedding`
- `ios-legacy-build-setting`

Linux rules:

- `linux-platform-directory-missing`
- `linux-runner-files-incomplete`
- `linux-cmake-minimum-too-low`
- `linux-gtk-pkg-config-missing`

Windows rules:

- `windows-platform-directory-missing`
- `windows-runner-files-incomplete`
- `windows-cmake-minimum-too-low`
- `windows-legacy-run-loop`
- `windows-version-info-not-tool-driven`
- `windows-dark-title-bar-support-missing`
- `windows-force-redraw-missing`

Web rules:

- `web-platform-directory-missing`
- `web-runner-files-incomplete`
- `web-bootstrap-missing`
- `web-base-href-missing`
- `web-legacy-load-entrypoint`
- `web-custom-bootstrap-incomplete`
- `web-deprecated-service-worker-version`
- `web-manual-service-worker-registration`

Desktop rules:

- `desktop-legacy-target-platform-override`

## Reports

Plain text output is intended for humans and uses colored severity labels.

```text
flutter_restore scan
Project: /projects/legacy_app
Package: legacy_app

Android
  Gradle: 5.6.4
  AGP: 3.5.4
  Kotlin: 1.3.50
  SDK: compile=35, min=21, target=28
  Legacy flutter.gradle apply: true
  .flutter-plugins: true
  Android v1 embedding: true
  Plugin DSL: false

Findings
  [HIGH] Gradle 5.6.4 is too old for Java 17
    This Gradle line supports Java up to 16; modern Android builds commonly use Java 17.
    android/gradle/wrapper/gradle-wrapper.properties
```

JSON output is intended for scripts, CI, dashboards, and later automation.

```json
{
  "platforms": ["android"],
  "snapshot": {
    "rootPath": "/projects/legacy_app",
    "hasPubspec": true,
    "hasPubspecLock": true,
    "hasMetadata": true,
    "pubspecName": "legacy_app",
    "flutterRevision": "0123456789abcdef",
    "android": {
      "gradleVersion": "5.6.4",
      "agpVersion": "3.5.4",
      "kotlinVersion": "1.3.50",
      "compileSdk": 35,
      "minSdk": 21,
      "targetSdk": 28,
      "usesLegacyFlutterGradleApply": true,
      "hasFlutterPluginsFile": true,
      "usesAndroidV1Embedding": true,
      "usesPluginDsl": false
    }
  },
  "findings": [
    {
      "id": "legacy-flutter-gradle-apply",
      "severity": "HIGH",
      "title": "Legacy Flutter Gradle apply detected",
      "message": "The Android project applies flutter.gradle with apply from, which is incompatible with newer Flutter Gradle integration.",
      "location": "android/app/build.gradle"
    }
  ]
}
```

Severity levels:

- `BLOCKER`: analysis cannot continue as expected, or migration is blocked
- `HIGH`: likely build or migration failure
- `MEDIUM`: important migration risk or missing precision
- `INFO`: useful context for restoration planning

## Exit Codes

| Code | Meaning |
| --- | --- |
| `0` | scan completed without blocker findings |
| `2` | scan completed and at least one blocker finding was reported |
| `64` | command line usage error |

## Architecture

The project is split into small layers:

- scanners read files and collect facts
- models represent discovered project state
- compatibility data lives separately from rule logic
- rules analyze a `ProjectSnapshot`
- renderers format output
- the CLI wires the flow together

```text
scan -> ProjectSnapshot -> CompatibilityRule -> Finding -> report
```

The rule runner is split with Dart `part` files:

- `rule_runner.project.dart`
- `rule_runner.android.dart`
- `rule_runner.ios.dart`
- `rule_runner.platforms.dart`

## Development

Install dependencies:

```sh
dart pub get
```

Run tests:

```sh
dart test
```

Run static analysis:

```sh
dart analyze
```

Format code:

```sh
dart format .
```

The test suite includes scanner tests, rule tests, CLI integration tests, and
fixtures for legacy and modern Flutter project layouts.

## Maintainers

- Vortex-bit256
