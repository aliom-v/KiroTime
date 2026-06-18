# Android Downloads Import Export Plan

## Goal

Implement the confirmed Android-only local backup flow for KiroTime:

- Export current-semester or all-semester JSON to the public `Downloads/KiroTime` directory.
- Let the user rename the exported file before saving.
- When a file with the same name exists, let the user choose overwrite, create a copy, or cancel.
- Import timetable JSON through an Android local file picker.
- During import preview, let the user choose: overwrite current semester, import as a new semester, or overwrite all timetable data.

This plan does not attempt cross-platform file save/pick support. Android is the only target in this slice.

## Architecture

- `TimetableJsonCodec` remains the canonical JSON format owner.
- `KiroTimeDatabase` remains the canonical persistence owner.
- New Android file IO is isolated behind a Flutter `MethodChannel` owned by `MainActivity.kt`.
- Dart calls the Android channel through a small storage gateway under `lib/features/import_export/`.
- Settings UI remains owned by `SettingsCenterDialog`, but file naming, collision policy, and import mode are represented with small typed Dart objects instead of ad hoc strings.
- Existing clipboard JSON import stays as a fallback/diagnostic entry, but the main user-facing import is local file selection.

## Tech Stack

- Flutter / Dart
- Riverpod
- Isar
- Android Kotlin `MethodChannel`
- Android `MediaStore.Downloads` for public `Downloads/KiroTime` export on Android 10+
- Android `ACTION_OPEN_DOCUMENT` for local JSON file picking

## Baseline/Authority Refs

- `docs/aegis/plans/2026-06-17-settings-center-and-local-data.md`: existing settings center and JSON import/export contract.
- `lib/features/import_export/domain/timetable_json_codec.dart`: current JSON schema.
- `lib/features/import_export/application/import_export_providers.dart`: current export/import application layer.
- `lib/features/settings/presentation/settings_center_dialog.dart`: current settings UI.
- `lib/core/database/isar_database.dart`: Isar write boundary.
- `android/app/src/main/kotlin/com/example/kiro_time/MainActivity.kt`: Android embedding entry.

## Compatibility Boundary

- JSON format remains backward-compatible with existing exported `kiro_time_timetable` version `1` files.
- Existing current-semester import semantics remain available: imported schedules are assigned to the current selected semester.
- Existing all-semester import semantics remain available: full timetable-owned data can be replaced.
- New "import as new semester" must not mutate existing semesters or schedules except for adding the new semester, metas, schedules, and selecting the new semester.
- Exported JSON files must be readable by the existing decoder.
- No `MANAGE_EXTERNAL_STORAGE` permission is introduced.

## Verification

- Unit tests for filename sanitization and collision policy request objects.
- Unit tests for import-as-new-semester database/application behavior.
- Widget tests for settings labels and import mode selection if the existing test harness can cover the dialog without platform channels.
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- Install on ADB device.
- Manual Android verification:
  - Export current semester to `Downloads/KiroTime`.
  - Export same name and choose "new copy".
  - Export same name and choose "overwrite".
  - Pick exported JSON through local file picker.
  - Import preview shows counts and allows overwrite current/new semester/overwrite all.

## Task 1: Model File Export Options

Files:

- Create `lib/features/import_export/domain/timetable_file_naming.dart`
- Add `test/features/import_export/domain/timetable_file_naming_test.dart`

Why:

Filename defaults, sanitization, and collision choices are user-visible and should be deterministic before Android IO is wired in.

Impact/Compatibility:

- Pure Dart helper only.
- No storage behavior changes yet.

Steps:

1. Write tests for:
   - default current-semester and all-semester filenames end in `.json`,
   - invalid filename characters are replaced,
   - empty names fall back to `KiroTime_课表备份.json`,
   - duplicate copy names append `_2`, `_3`, etc.
2. Run the test and verify it fails because the helper does not exist.
3. Implement `TimetableFileNaming` with:
   - `defaultExportFileName(scope, semesterLabel, now)`,
   - `sanitizeJsonFileName(input)`,
   - `copyNameFor(existingName, existingNames)`.
4. Run the target test and verify it passes.
5. Commit this slice.

## Task 2: Add Android Storage MethodChannel

Files:

- Modify `android/app/src/main/kotlin/com/example/kiro_time/MainActivity.kt`
- Create `lib/features/import_export/data/android_timetable_file_gateway.dart`
- Add `test/features/import_export/data/android_timetable_file_gateway_test.dart`

Why:

The app needs to write user-visible JSON into `Downloads/KiroTime` and read JSON through the Android file picker without requesting broad storage permission.

Impact/Compatibility:

- Android-only implementation.
- Non-Android platforms throw `UnsupportedError` through the Dart gateway in this slice.
- No changes to JSON schema.

Steps:

1. Write Dart gateway tests with a fake `MethodChannel` handler for:
   - `exportTimetableJson` sends `fileName`, `json`, and `overwrite`.
   - `pickTimetableJson` returns `fileName` and `json`.
   - null pick result becomes null.
2. Run the test and verify it fails because the gateway does not exist.
3. Implement `AndroidTimetableFileGateway` in Dart.
4. Implement Kotlin `MethodChannel`:
   - channel name `kiro_time/timetable_files`,
   - method `exportTimetableJson`,
   - method `pickTimetableJson`,
   - method `fileExistsInDownloads`,
   - export path uses `MediaStore.Downloads` relative path `Download/KiroTime/`,
   - picker uses `Intent.ACTION_OPEN_DOCUMENT` with `application/json` and `text/*` fallback,
   - returns picked file display name and UTF-8 text.
5. Run the Dart gateway test.
6. Build debug APK to verify Kotlin compiles.
7. Commit this slice.

## Task 3: Import Modes And Database Support

Files:

- Modify `lib/features/import_export/application/import_export_providers.dart`
- Modify `lib/core/database/isar_database.dart`
- Add tests under `test/features/import_export/application/` or extend `test/core/database/kiro_time_database_test.dart`

Why:

The import preview needs three distinct outcomes: overwrite current, create new semester, overwrite all.

Impact/Compatibility:

- Existing current-semester and all-semester replacement behavior stays intact.
- New-semester import creates a unique semester id, remaps imported meta ids and schedule ids if needed to avoid collisions, assigns all imported schedules to the created semester, and selects it.

Steps:

1. Write a failing database/application test for importing a current-semester snapshot as a new semester:
   - existing current semester remains unchanged,
   - new semester exists and is selected,
   - imported schedules point to the new semester,
   - imported courses are visible.
2. Run the test and verify RED.
3. Add `TimetableImportMode` with values:
   - `overwriteCurrentSemester`,
   - `createNewSemester`,
   - `overwriteAllData`.
4. Add a database helper or provider path that imports a snapshot into a newly created semester with unique ids.
5. Update `applyTimetableImportProvider` to accept an import mode.
6. Run the target test and verify GREEN.
7. Commit this slice.

## Task 4: Settings UI Flow

Files:

- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Add or update widget tests under `test/widget/`

Why:

Users need a complete local backup/restore flow without ADB or clipboard workarounds.

Impact/Compatibility:

- Existing settings dialog remains one screen with the same four groups.
- The clipboard import entry is retained as a smaller fallback action.

Steps:

1. Write/update widget tests that assert:
   - the import/export section shows "从本地 JSON 导入",
   - export actions open a rename dialog,
   - import preview contains the three mode options.
2. Run the target widget test and verify RED where coverage is new.
3. Implement export rename dialog:
   - prefilled default filename,
   - editable text field,
   - save button.
4. Implement collision handling:
   - call `fileExistsInDownloads`,
   - if exists, show overwrite/new-copy/cancel dialog,
   - new-copy computes a new filename and exports without overwriting.
5. Implement local JSON import:
   - call Android file picker,
   - decode JSON,
   - show preview,
   - mode selector defaults to overwrite current semester for current-semester backups and overwrite all for all-semester backups.
6. Keep clipboard JSON import as "从剪贴板 JSON 导入".
7. Run target widget tests and verify GREEN.
8. Commit this slice.

## Task 5: Full Verification And Device Install

Files:

- No production file changes expected.

Why:

This feature crosses UI, database, platform channel, Android build, and device storage.

Impact/Compatibility:

- Produces an installable debug APK for the connected ADB device.
- Worktree should end clean after commit.

Steps:

1. Run `dart format lib test android/app/src/main/kotlin/com/example/kiro_time/MainActivity.kt`.
2. Run `flutter analyze`.
3. Run `flutter test`.
4. Run `flutter build apk --debug`.
5. Install with `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk`.
6. Use `adb shell` or Android file manager evidence to confirm `Download/KiroTime` exists after export.
7. Run `git status --short` and confirm clean.

## Repair Track

- Repaired object: local JSON import/export UX.
- Action: move the primary Android export location from private app documents to public Downloads and add picker-based import.
- Impact: users can back up and restore data without ADB and without repeated school-system login.
- Verification: tests, Android build, ADB install, manual Downloads export/import check.

## Retirement Track

- Old owner/fallback: App Documents export path and clipboard import.
- Action: main settings actions move to Android public file IO; clipboard import remains as a fallback diagnostic path.
- Retained boundary: JSON codec and database import semantics stay reusable.
- Future trigger: once cross-platform save/open dialogs are added, the clipboard fallback can be demoted further or removed.

## Risks

- Android file picker result handling is asynchronous and must survive cancel flow.
- Some file managers may report MIME type as `application/octet-stream`; picker should accept broad text/json MIME patterns.
- MediaStore overwrite behavior differs by Android API; implementation should delete existing row when overwrite is explicitly selected.
- Changing Android package name or signing later will not preserve existing app-private data; public JSON export is the mitigation.
