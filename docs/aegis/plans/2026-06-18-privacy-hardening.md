# Privacy Hardening Plan

## Goal

Improve KiroTime's privacy posture before public distribution:

- Add an in-app privacy notice from the About dialog.
- Default WebView login-state retention to off.
- Keep full HTML diagnostics opt-in and off by default.
- Add an export warning that JSON backups contain complete timetable data.
- Document network permission and local-first behavior in README.
- Bump Android app version for this privacy update and build fresh release APKs.

## Architecture

- Import privacy defaults are owned by `ImportPreferences`.
- Settings and About UI are owned by `SettingsCenterDialog`.
- JSON backup warnings belong in the export filename dialog because that is the last step before writing a public file.
- Public privacy documentation is owned by `README.md`.
- Version identity remains owned by `pubspec.yaml`.

## Tech Stack

- Flutter / Dart
- Riverpod
- Isar
- Android WebView
- Android scoped storage / MediaStore

## Baseline/Authority Refs

- `lib/features/settings/domain/import_preferences.dart`
- `lib/features/settings/presentation/settings_center_dialog.dart`
- `lib/features/import/presentation/course_import_page.dart`
- `lib/features/import_export/domain/timetable_json_codec.dart`
- `android/app/src/main/AndroidManifest.xml`
- `README.md`
- `pubspec.yaml`

## Compatibility Boundary

- No backend or analytics SDK is introduced.
- Existing users who already saved `keepWebViewLoginState: true` keep their preference; only fresh defaults change.
- Existing JSON backup format stays version 1.
- Existing local import/export behavior remains unchanged except for additional warning text.
- WebView import remains user-initiated and local parsing only.

## Verification

- `flutter analyze`
- `flutter test`
- `flutter build apk --release --split-per-abi`
- `git grep`/`rg` scan for removed school/local identifiers and default privacy values.
- Confirm release APKs are regenerated after the version bump.

## Tasks

### Task 1: Plan And Baseline Release

Files:

- Add `docs/aegis/plans/2026-06-18-privacy-hardening.md`
- Modify `docs/aegis/INDEX.md`

Why:

Keep the privacy slice explicit and separate from prior release-identity work.

Impact/Compatibility:

- Documentation-only.

Steps:

1. Build the current sanitized release baseline with:
   - `flutter build apk --release --split-per-abi`
2. Save this plan.
3. Update the Aegis index.

Verification:

- Release APKs exist under `build/app/outputs/flutter-apk/`.
- `git diff --check`.

### Task 2: Privacy Defaults

Files:

- Modify `lib/features/settings/domain/import_preferences.dart`
- Modify `test/features/settings/domain/settings_models_test.dart`

Why:

Fresh installs should not retain教务系统 WebView cookie/session unless the user chooses that convenience.

Impact/Compatibility:

- Existing persisted settings still win after bootstrap.
- Only `ImportPreferences.defaults()` changes.

Steps:

1. Add/adjust test asserting defaults:
   - `academicSystemUrl == ''`
   - `semesterApiPath == ''`
   - `keepWebViewLoginState == false`
   - `keepHtmlDiagnostics == false`
2. Verify RED if the default is still true.
3. Change `keepWebViewLoginState` default to false.
4. Verify GREEN with:
   - `flutter test test/features/settings/domain/settings_models_test.dart`

Repair Track:

- Repaired object: privacy default retaining WebView login state.
- Action: default to not retaining login state.
- Verification: settings model test.

Retirement Track:

- Retired object: convenience-first fresh default.
- Retained boundary: users can still enable retention manually.

### Task 3: In-App Privacy Notice

Files:

- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

Users should be able to read what data is stored and where it goes without leaving the app.

Impact/Compatibility:

- Adds an About dialog action only.
- Does not change storage or import behavior.

Steps:

1. Add widget test:
   - Open settings.
   - Open About.
   - Tap privacy notice.
   - Assert local-only, no developer server upload, WebView local parsing, Downloads/KiroTime export, and network permission purpose text appears.
2. Verify RED.
3. Add a `隐私说明` action to About.
4. Add a centered privacy dialog using existing `_SimpleDialogFrame`.
5. Verify GREEN with:
   - `flutter test test/widget/timetable_page_test.dart`

Repair Track:

- Repaired object: privacy behavior only implied by product philosophy.
- Action: make it visible in-app.
- Verification: widget test.

Retirement Track:

- Retired object: About dialog as only version metadata.
- Retained boundary: About still shows app identity.

### Task 4: Export Warning And README Privacy Notes

Files:

- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `test/widget/timetable_page_test.dart`
- Modify `README.md`

Why:

Exported JSON is intentionally user-controlled but contains full timetable details.

Impact/Compatibility:

- No JSON schema change.
- No storage path change.

Steps:

1. Add widget test for export dialog warning text.
2. Verify RED.
3. Add warning text to `_ExportFileNameDialog`.
4. Add README privacy section:
   - local storage only,
   - WebView import is user-initiated and local parsed,
   - `INTERNET` permission is for user-opened academic pages,
   - JSON exports go to `Download/KiroTime` and contain complete timetable data,
   - diagnostics keep summaries by default and full HTML diagnostics remain off unless enabled.
5. Verify GREEN with:
   - `flutter test test/widget/timetable_page_test.dart`

Repair Track:

- Repaired object: export sensitivity not surfaced at save time.
- Action: warn before creating public backup file.
- Verification: widget test.

Retirement Track:

- Retired object: neutral export dialog that only names the destination.
- Retained boundary: user still controls file name and save/cancel.

### Task 5: Version Bump And Release Verification

Files:

- Modify `pubspec.yaml`
- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

Privacy behavior changes should ship as a distinct build.

Impact/Compatibility:

- Version changes from `0.1.1+2` to `0.1.2+3`.
- Package id stays `com.kirotime.app`.

Steps:

1. Update `pubspec.yaml` to `0.1.2+3`.
2. Update About dialog version/build display.
3. Update widget test expectations.
4. Run:
   - `dart format ...`
   - `flutter analyze`
   - `flutter test`
   - `flutter build apk --release --split-per-abi`
5. Scan with the project privacy keyword list for removed school, local path,
   device id, personal-name, and placeholder package identifiers. Keep the
   private keyword list outside tracked docs so the scan command itself does
   not reintroduce removed strings.

Repair Track:

- Repaired object: release artifacts not reflecting privacy changes.
- Action: version and rebuild.
- Verification: build output and tests.

Retirement Track:

- Retired object: previous sanitized-only build as latest release candidate.
- Retained boundary: old APK remains a local artifact but should not be shared as latest.

## Risks

- If a user already has `keepWebViewLoginState` saved as true, changing defaults will not override it. That is intentional to avoid silently changing a user preference.
- Full database encryption is deferred; the current app remains local plaintext storage inside the app sandbox.
- Exported JSON in public Downloads is user-readable by design.
