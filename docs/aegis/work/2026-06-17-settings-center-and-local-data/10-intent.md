# Intent

## Requested Outcome

Implement a settings center for KiroTime with four sections: timetable settings, appearance, import/export, and advanced settings. Add explicit semester creation/editing, lightweight week selection from the header, local JSON import/export, and persisted local preferences.

## Scope

- Settings UI and local preference persistence.
- Timetable rendering options that are immediately useful on phone.
- Local JSON backup/restore for current semester and all semesters.
- Device build/install after verification.

## Non-Goals

- WebDAV sync.
- Native widgets.
- Solving second-semester parser ambiguity without a trusted baseline artifact.
- Moving timetable editing dialogs unless required for settings integration.

## Baseline Read Set

- `docs/aegis/baseline/2026-06-16-initial-baseline.md`
- `docs/aegis/plans/2026-06-17-settings-center-and-local-data.md`
- `lib/features/timetable/presentation/timetable_page.dart`
- `lib/features/timetable/application/timetable_providers.dart`
- `lib/core/database/isar_database.dart`
- `test/widget/timetable_page_test.dart`
- `test/core/database/kiro_time_database_test.dart`

## Impact Statement

- UI: timetable top bar, week picker, settings dialog, course card appearance.
- State: Riverpod settings providers and semester creation flow.
- Persistence: existing `AppSettingRecord`, existing course/semester collections.
- Import/export: new JSON codec and file/share integration.

## Risk Hints

- `file_picker` and `share_plus` plugin APIs may be platform/version sensitive.
- All-semester import is destructive and needs preview/confirmation.
- Hiding weekends changes layout math and must not break conflict positioning.
