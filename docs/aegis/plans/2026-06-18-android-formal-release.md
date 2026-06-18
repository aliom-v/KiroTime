# Android Formal Release Plan

## Goal

Prepare KiroTime for a more formal Android APK distribution:

- Change Android package id from `<old-placeholder-package>` to `com.kirotime.app`.
- Change Android app label from `kiro_time` to `KiroTime`.
- Bump app version from `0.1.0+1` to `0.1.1+2`.
- Configure release signing with a local release keystore.
- Add settings actions for clearing all local timetable data and restoring a blank state.
- Add an About/version dialog.
- Build fresh release APKs and verify APK metadata.

## Architecture

- Android release identity is owned by `android/app/build.gradle.kts`, `AndroidManifest.xml`, and Kotlin package paths.
- Version source remains `pubspec.yaml`.
- Release signing uses `android/key.properties`, which is intentionally untracked.
- Keystore file is generated locally under `android/app/kirotime-release.jks` and intentionally untracked.
- Settings UI remains owned by `SettingsCenterDialog`.
- `KiroTimeDatabase` remains the canonical owner for clearing persisted Isar data.

## Tech Stack

- Flutter / Dart
- Android Gradle Kotlin DSL
- Android keystore via `keytool`
- Isar
- Riverpod

## Baseline/Authority Refs

- `pubspec.yaml`: version name/code source for Flutter.
- `android/app/build.gradle.kts`: application id, namespace, signing config.
- `android/app/src/main/AndroidManifest.xml`: app label and activity package resolution.
- `android/app/src/main/kotlin/com/example/kiro_time/MainActivity.kt`: Android native channel owner.
- `lib/core/database/isar_database.dart`: local persistence owner.
- `lib/features/settings/presentation/settings_center_dialog.dart`: settings UI owner.

## Compatibility Boundary

- Changing package id creates a new Android app install. Existing data in `<old-placeholder-package>` will not automatically migrate to `com.kirotime.app`.
- Users should export JSON before switching package id if they need to preserve existing courses.
- The generated keystore and passwords must not be committed.
- Release APKs must be signed by the release keystore, not the debug key.
- Existing timetable JSON import/export format remains unchanged.

## Verification

- `flutter analyze`
- `flutter test`
- `flutter build apk --release --split-per-abi`
- `aapt dump badging build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Confirm:
  - package name is `com.kirotime.app`,
  - versionName is `0.1.1`,
  - app label is `KiroTime`,
  - release APK files are generated.
- `git status --short` should show no tracked work after commit; `android/key.properties` and `android/app/kirotime-release.jks` must remain untracked/ignored.

## Tasks

### Task 1: Release Identity

Files:

- `pubspec.yaml`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- move `android/app/src/main/kotlin/com/example/kiro_time/MainActivity.kt`

Steps:

1. Change version to `0.1.1+2`.
2. Change namespace/application id to `com.kirotime.app`.
3. Change app label to `KiroTime`.
4. Move Kotlin package to `com.kirotime.app` and update package declaration.
5. Verify with `flutter analyze`.

### Task 2: Release Signing

Files:

- `.gitignore`
- `android/app/build.gradle.kts`
- local untracked `android/key.properties`
- local untracked `android/app/kirotime-release.jks`

Steps:

1. Add `android/key.properties` and `android/app/*.jks` to `.gitignore`.
2. Generate local keystore if missing.
3. Create local `android/key.properties`.
4. Update Gradle to read release signing config from `key.properties`.
5. Build release APK.

### Task 3: Clear All Data

Files:

- `lib/core/database/isar_database.dart`
- `lib/features/import_export/application/import_export_providers.dart`
- `lib/features/settings/presentation/settings_center_dialog.dart`
- tests

Steps:

1. Add database helper to clear courses, metas, semesters, and app settings, then recreate a blank fallback semester.
2. Add settings provider/action.
3. Add destructive confirmation in settings.
4. Verify tests.

### Task 4: About Dialog

Files:

- `lib/features/settings/presentation/settings_center_dialog.dart`
- test/widget coverage

Steps:

1. Add About action under settings.
2. Show app name, version `0.1.1`, package `com.kirotime.app`, and local-first note.
3. Verify widget test.

## Repair Track

- Repaired object: Android release identity and distribution readiness.
- Action: replace placeholder package/signing/version metadata and add local data reset/about affordances.
- Verification: APK metadata and release build.

## Retirement Track

- Retired object: placeholder `<old-placeholder-package>`, `kiro_time` app label, debug signing for release.
- Retained boundary: old package remains only on devices where already installed; no automatic data migration.
- Future trigger: once users move to `com.kirotime.app`, old package can be uninstalled after JSON export/import.

## Risks

- The generated release keystore is locally stored. Losing it prevents future upgrades of `com.kirotime.app`.
- Changing package id installs as a separate app and starts with a new empty database.
- If the generated keystore password is not recorded securely outside git, future release builds may be blocked.
