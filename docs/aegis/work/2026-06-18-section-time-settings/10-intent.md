# Section Time Settings Intent

## Requested Outcome

Implement per-semester class time settings:

- default 10 generated sections,
- morning/afternoon/evening generation,
- configurable section duration, short breaks, optional long break,
- generated list display,
- manual per-section start/end edit,
- real times in timetable left column,
- real times in course and conflict details,
- local persistence and JSON backup round trip.

## Scope

- Add pure time model under timetable domain.
- Extend semester settings and persistence.
- Extend local JSON codec.
- Add settings-center UI for class times.
- Replace hardcoded timetable time labels.
- Bump release version for the feature.

## Non-Goals

- Do not change course import parsing.
- Do not infer class times from school HTML/PDF.
- Do not add summer/winter multi-preset switching.
- Do not change schedule section numbering.

## Risk Hints

- Isar generated schema must be regenerated after adding a stored field.
- Widget tests may need updates because existing assertions expect hardcoded `09:00`.
- Existing JSON and existing databases must keep loading through default fallback.

## BaselineReadSetHint

- `docs/aegis/plans/2026-06-18-section-time-settings.md`
- `lib/features/timetable/domain/semester_settings.dart`
- `lib/features/timetable/data/semester_record.dart`
- `lib/features/settings/presentation/settings_center_dialog.dart`
- `lib/features/timetable/presentation/timetable_page.dart`
- `lib/features/import_export/domain/timetable_json_codec.dart`
- `test/widget/timetable_page_test.dart`
- `test/core/database/kiro_time_database_test.dart`
- `test/features/import_export/domain/timetable_json_codec_test.dart`

## ImpactStatementDraft

This changes a shared semester data contract and UI rendering contract. The canonical owner for generated class times is the timetable domain model; persistence and export/import only serialize it. Existing hardcoded left-column time labels should retire once `SectionTimeSettings` is wired into `TimetablePage`.
