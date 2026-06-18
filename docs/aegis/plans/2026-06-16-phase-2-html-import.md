# Phase 2 HTML Import Plan

## Goal

Implement the Phase 2 safe local import loop: users manually open a school timetable page in a WebView, KiroTime reads `document.documentElement.outerHTML`, parses timetable table cells locally with Dart `html`, converts the result into `CourseMeta` and `CourseSchedule`, stores it in Isar, and refreshes the timetable.

## Architecture

- `lib/features/import/domain/`: pure parsing and import result types. This layer has no Flutter UI or Isar dependency.
- `lib/features/import/presentation/`: WebView import screen and user actions.
- `lib/core/database/`: persistence method that replaces the current timetable with imported course data.
- `lib/features/timetable/`: app entry point and provider invalidation after import.

## Tech Stack

- Flutter / Dart
- Riverpod
- Isar
- `webview_flutter`
- `html`

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: Phase 2 requires WebView manual login, `outerHTML`, local `html` parsing, and conversion into existing models.
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`: course contracts live in `lib/features/courses/data/`, persistence in `lib/core/database/`, timetable UI/state in `lib/features/timetable/`.

## Compatibility Boundary

- Keep `CourseMeta.id` and `CourseSchedule.courseMetaId` as string business IDs.
- Keep `CourseSchedule.weeks` as explicit `List<int>`.
- Do not add backend crawling, WebDAV sync, or native widgets in this phase.
- Existing mock reset remains available for development.

## Verification

- Parser unit tests cover week expressions and table cell extraction.
- Widget/unit tests continue to pass.
- `flutter analyze` must pass.
- Android runner builds and installs to the connected ADB device after SDK setup.

## Tasks

### Task 1: Add parser contract tests

Files:

- `test/features/import/domain/academic_timetable_html_parser_test.dart`

Steps:

1. Write failing tests for week expressions: `1-16周`, `1-16周(单)`, `2-16周(双)`, `1,3,5,7周`, and `1-5,7-9周`.
2. Write a failing table parsing test using HTML cells with `data-day`, `data-start-section`, and `data-end-section`.
3. Run `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart` and confirm failure because the parser does not exist.

### Task 2: Implement pure parser

Files:

- `lib/features/import/domain/academic_timetable_html_parser.dart`

Steps:

1. Add `ImportedTimetable`, `ImportedCourseMeta`, and `ImportedCourseSchedule` value types.
2. Implement `AcademicTimetableHtmlParser.parseWeeks`.
3. Implement `AcademicTimetableHtmlParser.parse` for cells with explicit `data-day`, `data-start-section`, and `data-end-section` attributes plus resilient text extraction.
4. Run the parser tests until green.

### Task 3: Persist imported courses

Files:

- `lib/core/database/isar_database.dart`
- `lib/features/timetable/application/timetable_providers.dart`

Steps:

1. Add `replaceWithImportedTimetable` to clear course tables and write imported metas/schedules in one transaction.
2. Keep `seedMockData` and `resetWithMockData` unchanged.
3. Invalidate timetable providers after import.
4. Run all tests.

### Task 4: Add WebView import page and timetable entry

Files:

- `lib/features/import/presentation/course_import_page.dart`
- `lib/features/timetable/presentation/timetable_page.dart`
- `lib/app.dart` if routing needs a named route.

Steps:

1. Add an app bar import action from the timetable page.
2. Add URL input and a WebView screen.
3. On import, run JavaScript `document.documentElement.outerHTML`.
4. Parse and persist locally.
5. Return to timetable after success and refresh providers.

### Task 5: Android runner and install

Files:

- `android/`
- `pubspec.yaml`
- `pubspec.lock`
- `README.md`

Steps:

1. Generate Android runner with `flutter create --platforms=android .`.
2. Add `INTERNET` permission for WebView.
3. Install Android SDK platform/build-tools if needed.
4. Run `flutter build apk --debug`.
5. Run `flutter install -d <device-id>` or `flutter run -d <device-id>`.

## Risks

- School timetable HTML differs by institution. Phase 2 starts with a generic explicit-attribute parser plus text heuristics; school-specific adapters can be added later without changing the model.
- Android SDK installation may need network and license acceptance on this machine.
