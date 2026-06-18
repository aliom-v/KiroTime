# Interactive Timetable Usability Plan

## Goal

Turn the current timetable screen from a mostly visual mockup into a usable app surface. The user must be able to interact with week/date controls, inspect and edit courses, access import intentionally, and configure the basic semester calendar that drives current week and displayed dates.

## Architecture

- `lib/features/timetable/presentation/` owns timetable screen UI, interaction surfaces, sheets, and navigation from the main timetable.
- `lib/features/timetable/application/` owns Riverpod state for current week and semester settings.
- `lib/features/timetable/domain/` owns pure calendar calculations and section time defaults.
- `lib/core/database/` keeps owning Isar course data only. This plan does not add database persistence for semester settings yet unless needed for a minimal local settings store.
- `lib/features/import/` remains the WebView import owner. This plan only links to it from real buttons.

## Tech Stack

- Flutter / Dart
- Riverpod
- Existing Isar course storage
- Existing widget/unit test stack

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: Phase 1 timetable must remain `Stack` / absolute-positioned and support complex schedules.
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`: `CourseSchedule.weeks` is the canonical week representation, and timetable UI depends on providers.
- `docs/aegis/plans/2026-06-16-phase-2-html-import.md`: WebView import is local-only and must not become backend crawling.
- User feedback on 2026-06-17: current UI feels like a static image overlay and is not meaningfully interactive.

## Compatibility Boundary

- Keep `CourseMeta` and `CourseSchedule` schemas unchanged.
- Keep current course detail and edit bottom sheets working.
- Keep `TimetableLayout.buildPlacements` as the canonical placement/lane algorithm.
- Do not introduce WebDAV, native widgets, backend APIs, or a full route system in this slice.
- Do not make decorative controls that do nothing. Any visible control is either wired to behavior or removed.

## Verification

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- Install to connected Android device with `flutter install -d <device-id> --debug` when available.

## Problems To Repair

1. The timetable header looks interactive but the week selector and date header do not expose enough behavior.
2. The bottom navigation is visually present but only some items have real behavior.
3. Semester data is hard-coded from date heuristics, so current week/date can be wrong for real schools.
4. Import replaces all data without preview or confirmation. This plan documents that risk but defers full import preview to the next plan.
5. The timetable screen has grown into one large file with mixed layout, interaction, and form concerns.

## Task 1: Add Semester State And Settings Entry

Files:

- Create `lib/features/timetable/domain/semester_settings.dart`
- Modify `lib/features/timetable/application/timetable_providers.dart`
- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

The displayed current week and week dates must be based on user-editable semester settings, not only hard-coded month heuristics.

Impact/Compatibility:

- Keeps `CourseSchedule.weeks` unchanged.
- `currentWeekProvider` remains the week filter source, but gets initialized from semester settings.
- Settings are in-memory first for this slice. Persistence can be added later with a dedicated settings store.

Steps:

1. Write tests:
   - Widget test taps the semester/settings control and verifies a settings sheet opens.
   - Widget test changes the week/start date fields and sees the visible week label update.
2. Verify RED:
   - `flutter test test/widget/timetable_page_test.dart`
3. Implement:
   - Add `SemesterSettings` with `schoolYearStart`, `semester`, `semesterStart`, `totalWeeks`, `sectionTimes`.
   - Add `semesterSettingsProvider`.
   - Add a real settings button in the header.
   - Add a bottom sheet with start date, total week count, and semester label controls.
4. Verify GREEN:
   - `flutter test test/widget/timetable_page_test.dart`
5. Full verification:
   - `flutter analyze`
   - `flutter test`

Repair Track:

- Repaired object: hard-coded `AcademicCalendar.resolve(DateTime.now())` as the only semester authority.
- Action: introduce explicit settings state and route visible calendar labels through it.
- Impact: week/date display becomes user-controllable.
- Verification: widget tests for settings interaction and week label update.

Retirement Track:

- Retired object: pretending the header dropdown is interactive while it only shows text.
- Action: make header control open real settings.
- Retained boundary: default heuristic remains only as initial settings factory.
- Future trigger: when persistent settings are added, the in-memory provider becomes backed by local storage.

## Task 2: Make Date Header And Week Controls Explicitly Interactive

Files:

- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

The user should be able to change weeks directly from visible controls and understand what each control does.

Impact/Compatibility:

- Does not change placement logic.
- Does not change stored courses.

Steps:

1. Write tests:
   - Tapping next week changes `第16周` to `第17周`.
   - Tapping previous week changes it back.
   - Tapping a day header highlights/selects that day without changing week.
2. Verify RED:
   - `flutter test test/widget/timetable_page_test.dart`
3. Implement:
   - Add `selectedDayProvider` or local state if it remains screen-only.
   - Make date cells `InkWell`s with clear selected/today states.
   - Ensure visible controls use tooltips and do not conflict with course cards.
4. Verify GREEN:
   - `flutter test test/widget/timetable_page_test.dart`
5. Full verification:
   - `flutter analyze`
   - `flutter test`

Repair Track:

- Repaired object: date header appears tappable but is passive.
- Action: add selected day state and tap handlers.
- Impact: visible UI now reflects user input.
- Verification: widget interaction tests.

Retirement Track:

- Retired object: static date header.
- Action: all date cells become intentional controls.
- Retained boundary: selecting a day does not filter courses yet unless explicitly added later.
- Future trigger: if a Today page is implemented, selected day state can drive it.

## Task 3: Replace Decorative Bottom Navigation With Real Actions

Files:

- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

Bottom controls must not feel like a pasted image. Every visible bottom item must trigger a visible effect.

Impact/Compatibility:

- Keeps `CourseImportPage` navigation.
- Does not add unrelated social/discover pages.

Steps:

1. Write tests:
   - Tapping `今日` resets current week to the default current week and selects today.
   - Tapping `导入` navigates to `CourseImportPage`.
   - `课表` is selected and does not create a fake route.
2. Verify RED:
   - `flutter test test/widget/timetable_page_test.dart`
3. Implement:
   - Make `今日` reset week/day with a visible snackbar or state change.
   - Keep `课表` as selected inert tab with no fake route.
   - Keep `导入` navigating to import.
   - Remove any decorative action that is not wired.
4. Verify GREEN:
   - `flutter test test/widget/timetable_page_test.dart`
5. Full verification:
   - `flutter analyze`
   - `flutter test`

Repair Track:

- Repaired object: bottom navigation that looks complete but has partial behavior.
- Action: wire all visible actions or intentionally mark the current one as selected.
- Impact: UI no longer feels like a static overlay.
- Verification: widget interaction tests.

Retirement Track:

- Retired object: decorative-only bottom item behavior.
- Action: all bottom items have defined behavior.
- Retained boundary: no Discover/social tab.
- Future trigger: a dedicated Today page can replace the current reset behavior later.

## Task 4: Preserve Course Interactions Through The New Layout

Files:

- Modify `test/widget/timetable_page_test.dart`
- Modify `lib/features/timetable/presentation/timetable_page.dart` only if tests expose issues.

Why:

The new visual style must not break the core interaction: tap course -> details -> edit -> save.

Impact/Compatibility:

- Keeps existing edit provider and database update flow.
- No schema change.

Steps:

1. Write/keep tests:
   - Existing `tapping a course shows complete schedule details`.
   - Existing `editing a course saves changed schedule fields`.
   - Add one test that taps a course near the bottom overlay and confirms the bottom nav does not intercept it when the course is visible.
2. Verify RED for any new missing coverage:
   - `flutter test test/widget/timetable_page_test.dart`
3. Implement only if needed:
   - Adjust scroll bottom padding, overlay hit area, or card z-order.
4. Verify GREEN:
   - `flutter test test/widget/timetable_page_test.dart`
5. Full verification:
   - `flutter analyze`
   - `flutter test`

Repair Track:

- Repaired object: risk that the overlay blocks timetable interactions.
- Action: prove course taps still work and adjust hit testing if needed.
- Impact: visual bottom nav does not break the course grid.
- Verification: widget interaction tests.

Retirement Track:

- Retired object: untested overlay behavior.
- Action: add regression coverage.
- Retained boundary: bottom overlay stays visual but not at the cost of course taps.
- Future trigger: route-level navigation can replace the overlay later.

## Task 5: Document Deferred Import Safety Work

Files:

- Modify `README.md`
- Optionally add `docs/aegis/plans/2026-06-17-import-preview.md` later.

Why:

Import preview and safe replacement are important, but mixing them into this UI repair slice would blur scope.

Impact/Compatibility:

- No code change required in this plan.
- Makes project status honest.

Steps:

1. Update README current limitations:
   - Import currently replaces local timetable.
   - Import preview and backup are next priority.
2. Verify:
   - `flutter analyze`
   - `flutter test`

Repair Track:

- Repaired object: unclear product status.
- Action: document known limitation.
- Impact: avoids pretending import safety is complete.
- Verification: docs reviewed and tests still pass.

Retirement Track:

- Retired object: implicit assumption that import replacement is safe enough.
- Action: explicitly mark preview/backup as required next work.
- Retained boundary: no import behavior change in this slice.
- Future trigger: implement import preview plan.

## Self-Review

- Spec coverage: covers user complaint about static/overlay feel through settings, header, bottom nav, and course interaction tasks.
- Placeholder scan: no TBD/TODO placeholders.
- Type consistency: uses existing Riverpod provider patterns and `CourseSchedule` contract.
- Compatibility: course schemas and import contracts stay stable.
- Verification: every major task has widget test and full test commands.
- Dual-track: each repair task includes repair and retirement surfaces.
