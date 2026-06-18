# Import Semester Metadata Plan

## Goal

When importing a school timetable page, persist two pieces of metadata already present in the HTML:

- The first week start date, such as `第一周   2026-08-31/2026-09-06`, into the selected semester settings.
- The teaching class/course class code line, such as `操作系统-0011` or `软件工程-0004A`, into `CourseMeta.teachingClass`.

## Architecture

- `lib/features/import/domain/academic_timetable_html_parser.dart` remains the pure HTML parsing owner.
- `ImportedTimetable` gains optional `semesterStart` and continues carrying parsed metas/schedules.
- `CourseMeta.teachingClass` remains the data owner for teaching class information.
- `lib/features/import/presentation/course_import_page.dart` remains the WebView import orchestration owner and applies parsed semester metadata to the selected semester.
- `lib/features/timetable/application/timetable_providers.dart` continues owning in-memory/persistent semester settings updates through `updateSelectedSemesterProvider`.

## Tech Stack

- Flutter / Dart
- Riverpod
- Isar
- `html` parser
- Existing Flutter test framework

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: Phase 2 import is local HTML parsing with no backend.
- `docs/aegis/plans/2026-06-16-phase-2-html-import.md`: parser is pure domain logic, import page orchestrates WebView and persistence.
- `docs/aegis/plans/2026-06-17-timetable-conflicts-and-semester-persistence.md`: selected semester state and persistence live in timetable providers/database.
- Current phone evidence: imported course coordinates match the PDF, but selected semester start stayed `2026-08-17` while school HTML says `2026-08-31`.

## Compatibility Boundary

- Existing import behavior must still replace only the currently selected semester courses.
- If no first-week date is found, import must keep the existing semester settings unchanged.
- If no teaching class line is found, `teachingClass` stays empty.
- Course de-duplication must remain stable; same course name + teacher + teaching class should share a `CourseMeta`, but different teaching class variants can remain distinct metas.
- No database schema change is required because `CourseMeta.teachingClass` and `SemesterRecord.semesterStart` already exist.

## Verification

- `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart`
- `flutter test test/widget/timetable_page_test.dart`
- `flutter test`
- `flutter analyze`
- `flutter build apk --debug`
- `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk`

## Task 1: Parse first-week date and teaching class in domain parser

Files:

- `test/features/import/domain/academic_timetable_html_parser_test.dart`
- `lib/features/import/domain/academic_timetable_html_parser.dart`

Why:

- The school page already exposes the semester first-week date and teaching class lines. Parsing them at the domain layer keeps the WebView/UI layer simple and avoids duplicating HTML rules.

Impact/Compatibility:

- Adds `ImportedTimetable.semesterStart` as nullable metadata.
- Adds teaching class extraction without changing schedule placement, week parsing, or Isar schema.

Steps:

1. Write failing tests:
   - HTML containing `第一周   2026-08-31/2026-09-06` returns `DateTime(2026, 8, 31)`.
   - A lesson with lines `操作系统`, `操作系统-0011`, classroom, teacher, weeks stores `teachingClass == 操作系统-0011`.
   - A split lesson cell with `软件工程-0004` and `软件工程-0004A` keeps separate teaching class metadata.
2. Run the parser test and confirm failure.
3. Add nullable `semesterStart` to `ImportedTimetable`.
4. Implement `_parseSemesterStart(document)` using the first date range after `第一周`, preferring the range start date.
5. Implement teaching class extraction from the course-code line before `_normalizeDetailLines` filters it out.
6. Include `teachingClass` in `_ParsedSchedule.metaKey` and `scheduleKey`.
7. Run the parser test until green.

## Task 2: Apply parsed first-week date during import

Files:

- `test/widget/timetable_page_test.dart`
- `lib/features/import/presentation/course_import_page.dart`

Why:

- Correct imported dates must affect current-week calculation and week labels immediately after import.

Impact/Compatibility:

- Uses existing `updateSelectedSemesterProvider` so semester settings are persisted and in-memory state is updated through the established owner.
- Keeps current `sectionCount`, `totalWeeks`, display name, and semester id unchanged.

Steps:

1. Write a failing widget/provider-facing test that importing a timetable with `semesterStart` updates the selected semester settings.
2. Run the relevant widget test and confirm failure.
3. In `_importCurrentPage`, after successful parse and before/after replacing courses, if `imported.semesterStart != null`, call `updateSelectedSemesterProvider` with `current.copyWith(semesterStart: imported.semesterStart)`.
4. Keep provider invalidation for course data after replacement.
5. Run the widget test until green.

## Task 3: Full verification and Android install

Files:

- No production files unless verification exposes a bug.

Why:

- This touches parser, import orchestration, persisted semester settings, and user-visible week calculation.

Steps:

1. Run `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart`.
2. Run `flutter test test/widget/timetable_page_test.dart`.
3. Run `flutter test`.
4. Run `flutter analyze`.
5. Build debug APK.
6. Install on connected device `<device-id>`.

## Repair Track

- Repaired object: import metadata pipeline.
- Action: parse metadata at source and apply it through existing semester/update owners.
- Impact: imported timetables use the school-defined first week and real teaching class values.
- Verification: parser tests, widget tests, full test suite, analyze, APK build/install.

## Retirement Track

- Retired object: implicit reliance on `SemesterSettings.fromDate(DateTime.now())` for imported semester start after import.
- Action: keep it only as fallback when imported HTML has no first-week date.
- Future trigger: if more schools expose machine-readable term metadata, add parser adapters in the parser layer, not the UI layer.

## Residual Risks

- Some schools may label the first week differently from `第一周 yyyy-mm-dd/yyyy-mm-dd`; this plan handles the current observed format and common date separators.
- The current school HTML includes only teaching class code, not the full `教学班组成`; full composition parsing requires richer detail pages or PDF import and is out of scope.
