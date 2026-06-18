# Intent

## Requested Outcome

Polish KiroTime settings and week controls after the settings-center slice:

- Stable two-column semester switcher cards for easier term switching.
- Smoother left/right week animation that moves header and board together.
- Clear selected-state styling for week, date, and number wheel pickers.

## Scope

- Settings-center semester switcher presentation.
- Timetable week transition presentation.
- Wheel picker selected-state presentation.
- Widget tests, Android build/install, and git clean state.

## Non-Goals

- Data model or Isar schema changes.
- Parser/import fixes.
- WebDAV or native widget work.
- Full settings-center redesign.

## BaselineReadSetHint

- `docs/aegis/plans/2026-06-17-settings-interaction-polish.md`
- `lib/features/settings/presentation/settings_center_dialog.dart`
- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

## ImpactStatementDraft

- UI: settings semester switcher, week header/board transition, wheel picker selected-state styling.
- State: no new state owners; reuse current Riverpod providers.
- Persistence: unchanged.
- Compatibility: selected semester and current week behavior must remain unchanged.
