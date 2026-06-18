# Timetable Settings And Term Management Plan

## Goal

Make the timetable configurable without losing its dense default layout. The screen should default to a 10-section visible rhythm, allow schools with more daily sections, support week swiping, and move semester/section-count controls into a single settings surface with lightweight term management.

## Architecture

- `lib/features/timetable/domain/semester_settings.dart` owns pure timetable display settings and semester metadata.
- `lib/features/timetable/application/timetable_providers.dart` owns Riverpod state for selected semester, current week, and visible section count.
- `lib/features/timetable/presentation/timetable_page.dart` owns the timetable screen, settings sheet, week swipe gestures, and term management UI.
- `lib/features/timetable/domain/timetable_layout.dart` remains the placement algorithm owner. It may accept a configurable section count but must keep its schedule placement semantics.
- Isar course models remain unchanged in this slice.

## Tech Stack

- Flutter / Dart
- Riverpod
- Existing widget/unit tests

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: timetable must remain Stack/Positioned based and support complex schedule placements.
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`: domain layout owns filtering and placement; UI depends on providers.
- `docs/aegis/plans/2026-06-17-interactive-timetable-usability.md`: semester settings are in-memory first; persistence is deferred.
- User request on 2026-06-17: default 10 sections, configurable section count, swipe week switching, settings-based semester management and switching.

## Compatibility Boundary

- Keep `CourseMeta` and `CourseSchedule` schemas unchanged.
- Keep imported schedules that use section 11/12 renderable when section count is increased.
- Default visible section count is `10`.
- Minimum section count is `8`, maximum section count is `16`.
- Section count lower than an existing schedule's end section must not hide that schedule; rendering section count is the max of configured count and the largest schedule end section in the current week.
- Settings remain in memory for this slice. Persistent settings store is a follow-up.
- No WebDAV, sync, native widgets, or database migration in this slice.

## Verification

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- Install to connected Android device with `flutter install -d <device-id> --debug` when available.

## Proposed Product Shape

1. Main timetable defaults to 10 configured sections.
2. If a course exists after section 10, the board extends to that section and users scroll downward.
3. Course cards use the same dense card format: course, section text, classroom.
4. The week header supports:
   - left/right buttons,
   - horizontal swipe left/right on the timetable/header area.
5. The settings sheet includes:
   - current term fields: school-year start, semester, start date, total weeks,
   - section count field,
   - term management list with select/add controls.
6. Term management is lightweight:
   - keep a list of `SemesterSettings`,
   - selected term controls displayed dates and current week,
   - add term creates a new term using the current term as a template with a new id/label,
   - no per-term course data partitioning yet. Courses still use the same local course store.

## Non-Goals

- Persist settings across app restarts.
- Bind imported courses to different terms.
- Add full CRUD term deletion/reordering.
- Add single-day or three-day timetable modes.
- Change the course database schema.

## Task 1: Extend SemesterSettings For Display And Terms

Files:

- `lib/features/timetable/domain/semester_settings.dart`
- `test/widget/timetable_page_test.dart`

Why:

The UI needs a single object that can describe term identity and the configured daily section count.

Impact/Compatibility:

- Existing callers keep using `semesterStart`, `totalWeeks`, and `label`.
- New fields are in-memory only.

Steps:

1. Add failing tests covering default section count and settings update.
2. Add fields:
   - `id`
   - `sectionCount`
3. Add constants:
   - `defaultSectionCount = 10`
   - `minSectionCount = 8`
   - `maxSectionCount = 16`
4. Clamp section count in construction/copy helpers.
5. Verify widget tests.

## Task 2: Add Term Collection State

Files:

- `lib/features/timetable/application/timetable_providers.dart`
- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

Why:

Settings needs a term manager and the timetable needs a selected term.

Impact/Compatibility:

- `semesterSettingsProvider` remains available for UI consumers as selected term settings.
- `currentWeekProvider` stays the week filter source.

Steps:

1. Add `semesterListProvider` seeded with the current inferred term.
2. Add `selectedSemesterIdProvider`.
3. Make `semesterSettingsProvider` derive from the selected id.
4. Add helper functions to update selected term and add a new term.
5. Keep current week clamped to the active term's total weeks.

## Task 3: Render Default 10 Sections And Extend For More

Files:

- `lib/features/timetable/presentation/timetable_page.dart`
- `lib/features/timetable/domain/timetable_layout.dart`
- `test/widget/timetable_page_test.dart`

Why:

The default UI should show about 10 sections, but schedules after section 10 must still be visible by scrolling.

Impact/Compatibility:

- Placement math remains section-based.
- `TimetableLayout.sectionsPerDay` should no longer be the only display section source.

Steps:

1. Add tests:
   - default board renders through section 10.
   - section count setting can show section 12.
   - a schedule ending at section 12 extends the board even if configured count is 10.
2. Compute render section count as max(configured count, max schedule end section).
3. Generate background rows and section pickers from configurable count.
4. Keep edit dropdowns capable of selecting up to `SemesterSettings.maxSectionCount`.

## Task 4: Add Week Swipe Navigation

Files:

- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

Why:

Swiping horizontally is faster than tapping arrows repeatedly.

Impact/Compatibility:

- Does not change week filtering semantics.
- Keeps buttons for discoverability.

Steps:

1. Add widget tests for drag left -> next week and drag right -> previous week.
2. Wrap timetable area in a `GestureDetector` with horizontal drag threshold.
3. Clamp week to `1..totalWeeks`.

## Task 5: Build Settings And Term Management UI

Files:

- `lib/features/timetable/presentation/timetable_page.dart`
- `test/widget/timetable_page_test.dart`

Why:

Semester settings, section count, and term switching should live in one settings surface.

Impact/Compatibility:

- Existing setting fields stay available.
- Adds term list and add/select actions without changing course storage.

Steps:

1. Add tests:
   - settings sheet exposes section count.
   - changing section count updates visible board.
   - adding/selecting a term changes the header label.
2. Extend settings sheet with section count text field.
3. Add term chips/list rows with selected state.
4. Add `新增学期` action that creates a term with unique id.
5. Save updates selected term and current week.

## Risks And Follow-Ups

- In-memory term management will reset on app restart. Follow-up: local settings persistence.
- Courses are not yet partitioned by term. Follow-up: term id association for imported/manual courses.
- 7-day dense grid still limits long text. Follow-up: single-day/three-day view.

## Self-Review

- Scope covers the requested default 10 sections, configurable section count, week swipe, settings consolidation, and lightweight term management.
- Course schemas remain stable.
- Persistence is explicitly out of scope.
- Verification commands are concrete.
- Old fixed 12-section display behavior is retired in favor of configurable render count.
