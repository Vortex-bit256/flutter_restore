# flutter_restore

`flutter_restore` is a static compatibility scanner for aging Flutter Android
projects.

It helps you answer the first hard question in any Flutter recovery job:

> What exactly is old, risky, or incompatible here before I try to run it?

The tool reads project files, builds a structured snapshot of the project, runs
compatibility rules against that snapshot, and prints a human-readable or JSON
report. It does **not** run Flutter, Gradle, Android Studio, or any build step.

That is the core idea: inspect the project before the toolchain gets involved.

## Why This Exists

Old Flutter projects often fail long before the app code becomes relevant.

The first failure is usually hidden somewhere in the Android build stack:
Gradle, Android Gradle Plugin, Kotlin, Java, `compileSdk`, legacy Flutter Gradle
integration, or the Android embedding version. These failures can be noisy,
slow, and difficult to untangle because modern tools try to execute a project
that was created for a very different ecosystem.

`flutter_restore` gives you a map before you start the climb.

It is designed for:

- restoring abandoned Flutter apps
- auditing projects before migration
- understanding why a project no longer builds
- estimating Android migration effort
- producing machine-readable compatibility reports for automation
- separating project facts from build-tool side effects

## Main Feature

The main feature of `flutter_restore` is **static compatibility analysis without
executing the project**.

Instead of asking Gradle or Flutter to evaluate old scripts, the scanner reads
files directly and extracts facts into a `ProjectSnapshot`. Compatibility rules
then analyze that snapshot and produce `Finding` objects with clear severity
levels.

This makes the tool useful even when:

- Flutter is not installed
- Gradle cannot start
- the Android project uses obsolete Gradle syntax
- dependencies are no longer resolvable
- the local Java version is incompatible with the old build
- CI should inspect repositories without running a full build

## MVP Scope

The current MVP supports:

- `flutter_restore scan <path>`
- `--json`
- reading `pubspec.yaml`
- reading `pubspec.lock`
- reading `.metadata`
- Android compatibility scanning
- plain terminal report
- JSON report
- fixture-based test coverage for legacy and modern Flutter Android projects

Android facts currently detected:

- Gradle version
- Android Gradle Plugin version
- Kotlin version
- `compileSdk`
- `minSdk`
- `targetSdk`
- legacy Flutter Gradle `apply from`
- `.flutter-plugins`
- Android v1 embedding
- Gradle Plugin DSL usage

Compatibility rules currently included:

- Java ↔ Gradle
- Android Gradle Plugin ↔ Gradle
- Android Gradle Plugin ↔ Java
- Android Gradle Plugin ↔ `compileSdk`
- legacy Flutter Android migration signals

## Installation

From the repository root:

```sh
dart pub get
```

Run directly:

```sh
dart run flutter_restore scan path/to/flutter/project
```

Or activate locally during development:

```sh
dart pub global activate --source path .
flutter_restore scan path/to/flutter/project
```

## Usage

Plain report:

```sh
dart run flutter_restore scan path/to/project
```

JSON report:

```sh
dart run flutter_restore scan --json path/to/project
```

The plain report is intended for humans and uses colored severity labels in the
terminal. The JSON report is intended for scripts, CI, dashboards, or future
automation.

## Example Output

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

  [HIGH] Legacy Flutter Gradle apply detected
    The Android project applies flutter.gradle with apply from, which is incompatible with newer Flutter Gradle integration.
    android/app/build.gradle
```

## JSON Report Shape

```json
{
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

## Severity Levels

`flutter_restore` reports findings using four severity levels:

- `BLOCKER`: the project cannot be analyzed as expected
- `HIGH`: likely build or migration failure
- `MEDIUM`: important migration risk or missing precision
- `INFO`: useful context for restoration planning

The scanner exits with code `2` when a `BLOCKER` finding is present. Otherwise,
it exits with code `0`, even if compatibility risks are found. This keeps the MVP
useful for audits where findings should be collected rather than treated as a
hard CI failure.

## Architecture

The project is intentionally split into small layers:

- scanners only read files and collect facts
- models represent the discovered project state
- compatibility data is stored separately from rule logic
- rules analyze a `ProjectSnapshot`
- renderers format output
- the CLI only wires the flow together

The main flow is:

```text
scan -> ProjectSnapshot -> CompatibilityRule -> Finding -> report
```

This structure matters because compatibility data changes over time. Keeping
tables separate from rules makes it easier to update Gradle, AGP, Java, and SDK
knowledge without rewriting the scanner.

## Project Model

`ProjectSnapshot` is the central data model. It contains high-level Flutter
project facts and an Android-specific snapshot.

`Finding` is the central result model. Each finding has:

- stable `id`
- `severity`
- short `title`
- explanatory `message`
- optional file `location`

These models are deliberately simple so they can be serialized, tested, and
used by other tools later.

## Problems It Can Reveal

`flutter_restore` can help identify issues such as:

- a Gradle wrapper too old for modern Java
- an Android Gradle Plugin version outside the expected Gradle range
- an AGP version that requires a newer Java version
- a `compileSdk` value too new for the detected AGP line
- old `buildscript`/`classpath` Android plugin setup
- missing Gradle Plugin DSL
- legacy `apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"`
- old `.flutter-plugins` registry file
- Android v1 embedding through `io.flutter.app.FlutterActivity`
- missing `pubspec.lock`
- missing Flutter `.metadata`

These are not cosmetic issues. They are often the difference between a clean
migration plan and hours of confusing build failures.

## What It Does Not Do

The MVP intentionally does not:

- modify project files
- auto-fix Gradle scripts
- run `flutter`
- run `gradle`
- resolve packages
- analyze iOS
- provide a web UI
- provide an IDE plugin

This restraint is part of the design. The scanner should be safe to run on old
or fragile repositories because it only reads files.

## Compatibility Data

Compatibility data lives outside the rule logic. The MVP includes practical
tables for common Gradle, Android Gradle Plugin, Java, and `compileSdk`
relationships.

These tables are meant to evolve. The scanner architecture is built so future
updates can improve compatibility coverage without changing the shape of
findings or the scanner pipeline.

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

The test suite includes:

- scanner unit tests
- rule unit tests
- CLI integration tests
- legacy Flutter Android fixtures
- modern Flutter Android fixtures

## Roadmap Ideas

Possible future work:

- richer compatibility tables
- more Gradle syntax variants
- plugin dependency analysis from `pubspec.lock`
- `.flutter-plugins-dependencies` support
- Android manifest analysis
- migration hints grouped by effort
- SARIF or GitHub Actions output
- optional suggested fixes without modifying files
- iOS analysis as a separate scanner layer

## Philosophy

Restoring an old Flutter project should start with observation, not panic.

`flutter_restore` is built around that idea. It gives you a readable, structured
view of the project before modern tools try to execute old assumptions. That
makes migrations calmer, audits faster, and recovery work easier to explain.
