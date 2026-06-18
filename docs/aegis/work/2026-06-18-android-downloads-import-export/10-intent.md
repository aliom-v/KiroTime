# Intent

## Requested Outcome

Implement Android-first local timetable backup and restore:

- export JSON to public `Downloads/KiroTime`,
- allow export filename rename,
- handle same-name files with overwrite/new-copy/cancel,
- import JSON through Android local file picker,
- import with overwrite-current, create-new-semester, or overwrite-all modes.

## Scope

- Android-only file IO for this slice.
- Preserve existing JSON schema and database semantics.
- Keep clipboard import as a fallback.
- Build and install to the connected ADB device after verification.

## Non-Goals

- iOS, desktop, or web file save/pick support.
- WebDAV sync.
- Android package rename or release signing.

## Baseline Read Set Hint

- `docs/aegis/plans/2026-06-18-android-downloads-import-export.md`
- `docs/aegis/plans/2026-06-17-settings-center-and-local-data.md`
- `lib/features/import_export/domain/timetable_json_codec.dart`
- `lib/features/import_export/application/import_export_providers.dart`
- `lib/features/settings/presentation/settings_center_dialog.dart`
- `lib/core/database/isar_database.dart`
- `android/app/src/main/kotlin/com/example/kiro_time/MainActivity.kt`

## Impact Statement Draft

- UI impact: settings import/export section gains local file import and rename/collision dialogs.
- Data impact: new import mode can add a new semester without deleting existing data.
- Platform impact: Android `MethodChannel` becomes the owner of public Downloads file IO.
- Compatibility boundary: JSON version 1 remains readable; current/all import modes stay available.
