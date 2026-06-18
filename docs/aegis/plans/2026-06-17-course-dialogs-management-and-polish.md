# Course Dialogs Management And Polish Plan

## Goal

Implement the approved KiroTime usability polish slice:

- Replace course detail, conflict detail, course edit, and course add surfaces with centered dialogs.
- Add `teachingClass` to real course metadata and show it only when non-empty.
- Add course create, edit, delete, and copy-to-semester flows.
- Improve semester management with display name, delete protection, and deletion cleanup.
- Render conflicts as normal course cards with a small top-right count badge.
- Use stable pastel course colors.
- Add a light horizontal slide/fade transition when changing weeks.

## Product Rules

### Centered Dialogs

- Course detail, conflict detail, edit, and add must use centered dialogs, not bottom sheets.
- Dialog width should be responsive: roughly 88-92% of phone width, max 420 px.
- Dialog transition should be subtle `fade + scale`, about 160-220 ms.
- Long forms scroll inside the dialog.
- Dialog actions stay visible at the bottom where practical.

### Course Detail

- Show course name, classroom, teacher, teaching class, weekday/section range, and weeks.
- Omit teaching class when the value is empty.
- Actions: edit, delete, copy to other semester.
- Delete must ask for confirmation.
- Delete removes only the current `CourseSchedule`; orphan `CourseMeta` records are cleaned.

### Course Editor

- Use one reusable `CourseEditorDialog` for add and edit.
- Editable fields:
  - course name
  - teacher
  - teaching class
  - classroom
  - weekday
  - start section
  - end section
  - weeks
- Add creates a new `CourseMeta` and `CourseSchedule` in the selected semester.
- Edit updates the selected schedule and its meta.
- Empty teaching class is allowed.

### Copy To Semester

- Detail dialog exposes copy-to-semester.
- Copy opens a centered semester picker.
- Copy creates a new schedule in the target semester and keeps name, teacher, teaching class, classroom, weekday, sections, and weeks.
- Copy must not mutate the original schedule.

### Semester Management

- Add `displayName` to `SemesterSettings` / `SemesterRecord`.
- `label` should use `displayName` when non-empty, otherwise the current generated label.
- Settings UI allows editing display name.
- Deleting the final remaining semester is blocked.
- Deleting a semester asks for confirmation.
- Deleting the current semester switches to the first remaining semester.
- Deleting a semester removes its schedules and cleans orphan metas.

### Conflict Display

- Conflict groups render as a normal pastel card rather than a warning block.
- The top-right badge shows only the count: `2`, `3`, etc.
- Single courses never show a badge.
- Conflict dialog lists all conflicting courses and each row has an edit action for that specific course.

### Colors

- Use a stable pastel palette keyed by `CourseMeta.id`.
- Card background is light.
- A left or top accent strip uses a deeper color from the same palette.
- Conflict badge may use a warm accent, but the whole card should not become a warning card.

### Week Animation

- Week changes through arrows or horizontal swipe should animate the timetable board.
- Use `AnimatedSwitcher` with `SlideTransition` and `FadeTransition`.
- Left swipe / next week: new board enters from the right.
- Right swipe / previous week: new board enters from the left.
- Target duration: about 180 ms.

## Architecture

- `CourseMeta` gains `teachingClass`.
- `CourseScheduleEdit` expands into a reusable edit payload for save operations.
- `KiroTimeDatabase` owns create/update/delete/copy schedule and semester delete helpers.
- `timetable_providers.dart` owns public app actions and provider invalidation.
- `TimetablePage` owns dialog UI, cards, conflict badge, palette, and week transition.
- `AcademicTimetableHtmlParser` preserves empty `teachingClass` until a real parser rule is added.

## Compatibility Boundary

- Keep `CourseSchedule.weeks` as explicit `List<int>`.
- Keep one `CourseSchedule` per concrete time/place/week block.
- Do not fabricate teaching class when import cannot parse it.
- Keep existing imported rows valid by defaulting `teachingClass` and `displayName` to empty strings.
- Do not implement Phase 3 WebDAV or Phase 4 widgets in this slice.

## Task 1: Data Model And Database Actions

Files:

- `lib/features/courses/data/course_meta.dart`
- `lib/features/courses/data/course_schedule_edit.dart`
- `lib/features/timetable/domain/semester_settings.dart`
- `lib/features/timetable/data/semester_record.dart`
- `lib/core/database/isar_database.dart`
- `test/core/database/kiro_time_database_test.dart`

Steps:

1. Write failing tests:
   - course meta round-trips `teachingClass`,
   - create schedule writes selected semester id,
   - delete schedule removes only that schedule and cleans orphan meta,
   - copy schedule to another semester creates a distinct schedule,
   - semester display name round-trips,
   - deleting a semester removes its schedules and blocks deleting the last semester.
2. Add `CourseMeta.teachingClass` with default empty string.
3. Add `SemesterSettings.displayName` and `SemesterRecord.displayName`.
4. Add database helpers for create/update/delete/copy schedules and delete semester.
5. Regenerate Isar code.
6. Run database tests.

## Task 2: Providers And Import Wiring

Files:

- `lib/features/timetable/application/timetable_providers.dart`
- `lib/features/import/domain/academic_timetable_html_parser.dart`
- `lib/features/import/presentation/course_import_page.dart`

Steps:

1. Add provider actions:
   - save course edit,
   - create course,
   - delete schedule,
   - copy schedule to semester,
   - delete semester.
2. Ensure provider invalidation refreshes visible items, metas, schedules, and selected semester.
3. Ensure import creates `CourseMeta` with empty `teachingClass` unless real data is parsed.
4. Run parser/provider-related tests.

## Task 3: Centered Dialogs And Course Management UI

Files:

- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

Steps:

1. Write failing widget tests:
   - tapping a course opens a centered dialog, not a bottom sheet,
   - detail shows teaching class only when non-empty,
   - edit dialog can edit teaching class,
   - add course creates a new course through provider action,
   - delete asks for confirmation and calls delete action,
   - copy opens semester picker and calls copy action.
2. Replace course detail and edit bottom sheets with centered dialogs.
3. Add top-bar add course button.
4. Add reusable editor dialog.
5. Add delete confirmation dialog.
6. Add copy-to-semester picker dialog.
7. Run widget tests.

## Task 4: Semester Management UI

Files:

- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

Steps:

1. Write failing widget tests:
   - custom display name appears in header and chip,
   - deleting last semester is blocked,
   - deleting current semester switches to remaining semester,
   - delete confirmation is required.
2. Add display name text field.
3. Add delete semester action in settings.
4. Wire provider delete behavior.
5. Run widget tests.

## Task 5: Conflict Badge, Pastel Cards, And Week Animation

Files:

- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

Steps:

1. Write failing widget tests:
   - conflict card shows badge `2` and not `2门冲突`,
   - single course has no badge,
   - conflict detail dialog has edit action per course,
   - week changes animate board key/direction.
2. Replace warning-style conflict card with normal pastel card plus badge.
3. Add stable pastel palette model.
4. Add conflict detail edit actions.
5. Add board `AnimatedSwitcher` slide/fade transition.
6. Run widget tests.

## Task 6: End-To-End Verification And Install

Steps:

1. `dart format ...`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter analyze`
4. `flutter test`
5. `flutter build apk --debug`
6. `flutter install -d <device-id> --debug`
7. ADB cold-start sanity check for crash-free startup.

## Risks And Follow-Ups

- This slice touches Isar schema. Debug data should migrate with empty defaults, but if a local dev DB is stale or corrupt, clearing/reimporting may be required.
- Teaching class parser support is intentionally conservative; it should stay empty unless a reliable signal is found.
- Course copy duplicates schedule data intentionally; later sync/export should include copied schedules normally.
- Centered dialogs on very small screens need scroll and keyboard verification.
