# Settings Interaction Polish Plan

## Goal

Implement the approved KiroTime interaction polish slice:

- Replace the flexible semester `Wrap` chips with a stable two-column semester switcher so terms do not jump around while adding, editing, or selecting.
- Make week switching feel smoother by animating the term header and timetable board together with a shorter slide/fade transition.
- Make wheel pickers clearer by visually emphasizing the currently centered/selected item in week, number, and date wheels.

## Architecture

- `lib/features/settings/presentation/settings_center_dialog.dart` owns the settings-center semester switcher and date/number wheel dialogs.
- `lib/features/timetable/presentation/timetable_page.dart` owns the timetable page, week header, week picker dialog, and swipe transition.
- `lib/features/timetable/application/timetable_providers.dart` already owns sorted semester state through `sortSemestersByAcademicTime`; this slice should reuse it and avoid new persistence changes.
- `test/widget/timetable_page_test.dart` owns user-visible widget coverage for the timetable screen and settings dialog.

## Tech Stack

- Flutter / Dart
- Riverpod
- Existing widget tests with `flutter_test`

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: local-first lightweight timetable app.
- `docs/aegis/plans/2026-06-17-settings-center-and-local-data.md`: settings center and local settings ownership.
- `docs/aegis/plans/2026-06-17-course-dialogs-management-and-polish.md`: centered dialog and polished timetable interaction direction.
- Commit `6558a5c`: semester ordering and keyboard dialog sizing baseline.

## Compatibility Boundary

- Do not change course data models, Isar schema, import/export JSON format, or semester persistence behavior.
- Keep semester sorting by academic time.
- Keep top week label as a lightweight week picker only.
- Keep current week switching semantics: arrows/swipes clamp to `1..totalWeeks`, and week picker confirmation updates `currentWeek`.
- Do not introduce new packages.

## Verification

- Target widget tests:
  - semester management uses a stable two-column switcher/card layout.
  - selected semester remains visually distinguishable.
  - week picker selected item has an explicit selected key/style.
  - date/number wheels expose selected item semantics or keys after scrolling.
  - horizontal swipe still changes visible week.
- Full verification:
  - `dart format ...`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --debug`
  - `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk`

## Task 1: Stable Two-Column Semester Switcher

Files:

- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

The current `Wrap + ChoiceChip` layout changes positions based on label width, selected chip styling, and term count. A fixed two-column grid is easier to scan and more reliable for switching semesters.

Impact/Compatibility:

- Replace only the visual switcher. `_selectSemester`, `_startCreateSemester`, `_editingSemester`, and persistence providers stay unchanged.
- The selected semester still updates through `selectSemesterProvider`.
- The add entry remains in the same grid area as a fixed card.

Steps:

1. Write a widget test that opens settings and asserts semester switch items are rendered as two fixed-width cards rather than `ChoiceChip`.
2. Verify RED with:
   `flutter test test/widget/timetable_page_test.dart --plain-name "semester settings uses fixed two-column switcher cards"`
3. Add `_SemesterSwitcherGrid` and `_SemesterSwitchCard` widgets in `settings_center_dialog.dart`.
4. Replace the `Wrap` section with `_SemesterSwitcherGrid`.
5. Verify GREEN with the target widget test, then run existing semester settings tests.

## Task 2: Smoother Week Transition

Files:

- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

The timetable board currently animates alone. Moving the header/week dates with the board gives a more coherent swipe feel, and a slightly shorter transition improves perceived responsiveness.

Impact/Compatibility:

- Current week source remains `currentWeekProvider`.
- Swipe, arrow, and picker update behavior remains unchanged.
- Only presentation structure changes: wrap the term header and board in one keyed animated subtree.

Steps:

1. Write a widget test that verifies the transition wrapper key changes with `currentWeek` and still preserves swipe behavior.
2. Verify RED with:
   `flutter test test/widget/timetable_page_test.dart --plain-name "week transition animates header and board together"`
3. Extract `_WeekTransition` around `_TermHeader` and timetable board content.
4. Use duration `160ms`, `easeOutCubic`, and a small `SlideTransition + FadeTransition`.
5. Verify GREEN with target test plus `horizontal swipe changes visible week`.

## Task 3: Wheel Picker Selected-State Polish

Files:

- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

Wheel pickers should make the currently centered value obvious before the user taps confirm. The current week picker has partial styling but does not call `setState` while scrolling, and the date wheels do not visually distinguish selected items.

Impact/Compatibility:

- Confirm/cancel behavior remains unchanged.
- Existing `ListWheelScrollView` and wheel physics remain unchanged.
- Add visual keys/semantics only for selected wheel items to make behavior testable.

Steps:

1. Write a widget test for the week picker selected item key/style and a settings date wheel selected item marker.
2. Verify RED with the target tests.
3. Add shared selected wheel item styling helpers in the existing files:
   - selected value: bolder, slightly larger, darker.
   - non-selected values: lighter color and normal weight.
   - center selection band or subtle divider in `_WheelDialogScaffold` / week picker body.
4. Ensure `onSelectedItemChanged` calls `setState` where the UI depends on selected value.
5. Verify GREEN with target tests.

## Task 4: Full Verification, Install, And Commit

Files:

- Update `docs/aegis/INDEX.md`
- Create/update `docs/aegis/work/2026-06-17-settings-interaction-polish/`

Why:

This is a user-visible interaction slice. It needs regression tests, Android build, device install, and a clean git state.

Impact/Compatibility:

- No schema or dependency changes.
- Git history should contain one focused commit for this polish slice.

Steps:

1. Run `dart format` on changed Dart files.
2. Run `flutter analyze`.
3. Run `flutter test`.
4. Run `flutter build apk --debug`.
5. Run `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk`.
6. Commit with message `Polish settings switcher and week controls`.
7. Confirm `git status --short` is empty.

## Risks And Rollback

- Animation changes can make widget tests timing-sensitive; keep transition duration short and continue using `pumpAndSettle`.
- Two-column cards may need responsive constraints on very narrow screens; use grid/card min heights and text ellipsis.
- Wheel selected-state tests should use keys/semantics, not fragile font-size pixel assertions.

## Non-Goals

- No parser fixes.
- No database migration.
- No WebDAV or native widget work.
- No redesign of the whole settings center.
