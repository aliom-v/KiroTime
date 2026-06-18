# Timetable Conflicts And Semester Persistence Plan

## Goal

Implement the approved next KiroTime slice in two stages:

1. Improve timetable cards and details:
   - Course cards show only course name, classroom, and teacher.
   - Tapping a normal card opens a richer detail sheet.
   - True same-week overlaps render as one conflict card instead of unreadable side-by-side narrow cards.
2. Persist semester management:
   - Semester list and selected semester survive app restart.
   - Courses are partitioned by semester.
   - Import saves courses into the currently selected semester.

## Architecture

- `lib/features/timetable/domain/timetable_layout.dart` owns visible placement grouping and conflict detection.
- `lib/features/timetable/presentation/timetable_page.dart` owns visual cards, conflict sheets, course detail sheets, and settings sheet wiring.
- `lib/features/courses/data/` owns persisted course schemas. `CourseSchedule` will gain `semesterId`; `CourseMeta` may keep course identity global for this slice unless per-semester metadata isolation is needed by tests.
- `lib/features/timetable/data/` will own persisted semester records.
- `lib/features/timetable/application/timetable_providers.dart` owns selected semester state, current week, current term settings, and semester-scoped course queries.
- `lib/core/database/isar_database.dart` owns Isar schema registration, import replacement, seed/reset migration, and writes.
- `lib/features/import/presentation/course_import_page.dart` passes the selected semester id into import persistence.

## Tech Stack

- Flutter / Dart
- Riverpod
- Isar
- Existing widget and domain tests
- `build_runner` for generated Isar schema code

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: `CourseSchedule.weeks` remains explicit and rendering filters by membership in `currentWeek`.
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`: timetable layout is the canonical owner for filtering and placement; providers mediate UI/database access.
- `docs/aegis/plans/2026-06-17-timetable-settings-and-terms.md`: current in-memory semester list is a temporary boundary and must become persistent in this slice.
- User-approved scope on 2026-06-17: cards show course/place/teacher, conflict card only for real conflicts, richer details, persistent semester switching, course data scoped to semester, import into current semester.

## Compatibility Boundary

- Keep `CourseMeta.name` and `CourseMeta.teacher` stable.
- Keep `CourseSchedule.weeks` explicit; do not replace with odd/even flags.
- Keep one `CourseSchedule` per concrete time/place/week block.
- Only current-week schedules can participate in visible conflict grouping.
- Do not optimize or special-case long courses in this slice.
- Existing imported data without `semesterId` should be assigned to the selected/default semester during app startup or schema migration behavior.
- Import replacement should replace only the current semester's courses, not all semesters.
- Existing Phase 3 WebDAV and Phase 4 widgets remain out of scope.

## Verification

- `dart run build_runner build --delete-conflicting-outputs`
- `dart format ...`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `flutter install -d <device-id> --debug`
- Manual/ADB sanity:
  - Launch app.
  - Check normal cards show course/classroom/teacher.
  - Check true conflicts show a conflict card only when current week has overlapping courses.
  - Reopen app and confirm selected semester persists.
  - Import current page and confirm schedules are assigned to selected semester.

## Proposed Product Rules

### Normal Card

Render exactly:

```text
课程名
地点
老师
```

Do not render section text on the card. Section is already represented by card position.

### Normal Detail Sheet

Show:

- Course name
- Teacher
- Classroom
- Weekday and section range
- Week text
- Teaching class if available later
- Edit action

Teaching class is not yet in the persisted schema. If parser can recover a course-code-like value, keep this as a follow-up unless the model change stays small enough in this slice.

### Conflict Card

Only render for true current-week overlaps: at least two schedules whose visible sections overlap on the same day after current-week filtering.

Render a single full-width card for the conflict region:

```text
2门冲突
课程A / 课程B
地点摘要
```

If only one visible course exists, render a normal card and no number.

Tapping a conflict card opens a detail sheet listing each conflicted course with course name, classroom, teacher, weekday/section range, and weeks.

### Semester Persistence

- Persist terms as Isar records.
- Persist selected semester id.
- Filter all timetable queries by selected semester id.
- Add new semesters in settings and save them immediately.
- Import replaces only data for the selected semester.

## Task 1: Model Visible Items And Conflict Groups

Files:

- `lib/features/timetable/domain/timetable_layout.dart`
- `test/features/timetable/domain/timetable_layout_test.dart`

Why:

The current lane model makes overlapping cards unreadably narrow on mobile. The domain layout should identify conflict groups and let UI render a single conflict card.

Impact/Compatibility:

- Retires side-by-side lane rendering for visible conflicts.
- Keeps current-week filtering as the source of visible schedules.
- Keeps placement section math stable.

Steps:

1. Write failing tests:
   - one visible course creates one normal item,
   - two current-week overlapping courses create one conflict item,
   - same time but different weeks does not conflict after filtering.
2. Run `flutter test test/features/timetable/domain/timetable_layout_test.dart` and confirm RED.
3. Add a visible item model:
   - normal item with one `TimetableCoursePlacement`,
   - conflict item with multiple placements and combined day/start/span.
4. Update layout builder to expose visible items while preserving existing placement construction for tests that still assert lane math.
5. Run `flutter test test/features/timetable/domain/timetable_layout_test.dart` and confirm GREEN.

## Task 2: Render Normal Cards And Conflict Cards

Files:

- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

Why:

Users need readable course cards and explicit conflict handling.

Impact/Compatibility:

- Normal cards no longer show section text.
- Conflict card appears only for true overlaps in the current week.
- Existing course detail and edit flow remains available for normal cards.

Steps:

1. Write failing widget tests:
   - normal card renders course name, classroom, teacher and does not render `1-2节` inside the card,
   - tapping normal card opens details with weekday/section/weeks,
   - overlapping current-week courses render one conflict card,
   - tapping conflict card opens a list with both courses.
2. Run `flutter test test/widget/timetable_page_test.dart` and confirm RED.
3. Replace `_PositionedCourseCard` rendering loop with visible item rendering.
4. Update `_CourseCard` body text to course/classroom/teacher.
5. Add `_ConflictCard` and `_ConflictDetailSheet`.
6. Run `flutter test test/widget/timetable_page_test.dart` and confirm GREEN.

## Task 3: Persist Semester Records

Files:

- `lib/features/timetable/data/semester_record.dart`
- `lib/features/timetable/domain/semester_settings.dart`
- `lib/core/database/isar_database.dart`
- `lib/features/timetable/application/timetable_providers.dart`
- `test/features/timetable/...` or widget tests as appropriate

Why:

The current term list is in-memory and resets after app restart.

Impact/Compatibility:

- Adds an Isar collection for semester settings.
- Replaces in-memory-only semester list provider with database-backed state.
- Current default term is created automatically when no term exists.

Steps:

1. Write failing provider/database tests where possible:
   - created semester can round-trip through Isar,
   - selected semester id can be saved and restored.
2. Add `SemesterRecord` Isar collection with fields matching `SemesterSettings`.
3. Register `SemesterRecordSchema` in `KiroTimeDatabase.open`.
4. Add database helpers:
   - ensure default semester,
   - list semesters,
   - upsert semester,
   - save selected semester id,
   - read selected semester id.
5. Update providers to load and persist semesters.
6. Run `dart run build_runner build --delete-conflicting-outputs`, then tests.

## Task 4: Scope Courses By Semester

Files:

- `lib/features/courses/data/course_schedule.dart`
- `lib/core/database/isar_database.dart`
- `lib/features/timetable/application/timetable_providers.dart`
- `lib/features/import/presentation/course_import_page.dart`
- tests for import/database/provider behavior

Why:

Switching semester must show that semester's courses only, and import must not erase other semesters.

Impact/Compatibility:

- Adds `semesterId` to `CourseSchedule`.
- Existing schedules without a semester id are treated as belonging to the selected/default semester.
- Import replacement clears schedules for the selected semester only.

Steps:

1. Write failing tests:
   - timetable query returns only selected semester schedules,
   - replacing imported data for semester B leaves semester A schedules intact.
2. Add `semesterId` to `CourseSchedule`.
3. Regenerate Isar code.
4. Update mock seed and import conversion to populate semester id.
5. Update database replacement to accept `semesterId`.
6. Update providers to filter by selected semester id.
7. Run all tests.

## Task 5: End-To-End Verification And Install

Files:

- No source files unless verification exposes a bug.

Why:

This slice changes UI, domain grouping, persistence, and import behavior.

Steps:

1. Run `dart format` on modified Dart files.
2. Run `dart run build_runner build --delete-conflicting-outputs`.
3. Run `flutter analyze`.
4. Run `flutter test`.
5. Run `flutter build apk --debug`.
6. Run `flutter install -d <device-id> --debug`.
7. Use ADB/database inspection to confirm selected semester and current schedules are stored as expected.

## Risks And Follow-Ups

- Isar schema changes may require clearing/reimporting debug data if automatic migration does not preserve old rows cleanly.
- Teaching class requires a persisted field and parser support. If not implemented in this slice, detail sheet should omit it rather than show fake data.
- Conflict grouping must avoid hiding true separate courses; the conflict sheet is the disclosure mechanism.
- Long course display is intentionally unchanged per user instruction.

## Self-Review

- Scope covers both approved stages.
- The plan avoids changing `weeks` semantics.
- The plan explicitly retires unreadable side-by-side conflict cards.
- The plan makes semester persistence and course partitioning first-class, not in-memory UI state.
- Verification includes tests, build, and device install.
