# Import, Settings, And Glass Completion Plan

## Goal

Close the remaining gaps from the timetable redesign:

- detect usable section clock times from imported academic-system pages,
- let the user review and apply detected times to the imported semester,
- provide complete saved academic URL management from settings,
- replace the long settings dialog with a full-screen settings route,
- apply the light glass material consistently without reducing timetable readability.

## Execution Status

- Task 1 complete: timetable-axis times are detected conservatively with explicit-range and start-only evidence.
- Task 2 complete: import preview requires an explicit user decision and accepted times persist only to the target semester.
- Task 3 complete: named URL bookmarks support add, edit, remove, reorder, normalization, and legacy string-list decoding.
- Task 4 complete: the settings entry now opens a full-screen route with direct navigation to all four sections.
- Task 5 complete for automated QA: shared glass primitives remain in use and mobile widget regressions pass. Physical-device visual QA remains environment-dependent.

## Acceptance Criteria

1. HTML import can detect explicit section start/end times from a timetable axis. Start-only axes remain reviewable and use a documented conservative duration fallback.
2. Import preview distinguishes course placement from detected clock times and never changes semester times without explicit user confirmation.
3. Applying detected times updates only the target semester and persists through restart/export.
4. Settings can add, edit, remove, and reorder saved HTTP(S) academic URLs. Old string-list preferences remain readable.
5. The settings entry opens a full-screen route with four directly reachable sections: timetable, appearance, import/export, and advanced.
6. Timetable, settings, and import surfaces share the light glass theme while the dense course grid keeps an opaque-enough reading surface.
7. Existing JSON, Isar records, course section placement, and the default 08:10 schedule remain backward compatible.

## Architecture

- `AcademicTimetableHtmlParser` owns extraction of timetable-axis clock evidence. It does not persist settings.
- `ImportedTimetable` carries optional detected section-time evidence alongside courses and semester start.
- Import preview owns the user decision to apply detected times.
- Existing semester providers remain the only persistence path for `SectionTimeSettings`.
- `ImportPreferences` remains the app-setting compatibility boundary for saved URLs. New structured entries must decode legacy strings.
- A new settings page owns navigation and section layout. Existing dialogs remain focused editors for dates, times, filenames, and destructive confirmation.
- `GlassPanel`, `KiroCanvas`, and `KiroPalette` remain the shared visual primitives; business screens must not define competing glass colors.

## Compatibility Rules

- Do not infer clock times from course card position alone.
- Do not overwrite customized semester times unless the user opts in during import.
- Reject non-HTTP(S) saved URLs on input, but tolerate and filter malformed legacy values during decoding.
- Preserve local-first behavior; no network service or new dependency is introduced.
- Keep course placement numeric (`startSection` / `endSection`) and independent from displayed clock times.

## Task 1: Detect Section-Time Evidence

Files:

- `lib/features/import/domain/academic_timetable_html_parser.dart`
- `lib/features/timetable/domain/section_time_settings.dart`
- `test/features/import/domain/academic_timetable_html_parser_test.dart`

Steps:

1. Add failing fixtures for explicit ranges (`08:10-08:55`) and start-only axes (`08:10:00`).
2. Parse section numbers and clock text only from verified timetable-axis cells.
3. Require ordered, non-overlapping results and reject malformed or sparse evidence.
4. Return detected settings as optional import metadata.

## Task 2: Review And Apply Imported Times

Files:

- `lib/features/import/presentation/import_preview_dialog.dart`
- `lib/features/import/presentation/course_import_page.dart`
- `lib/features/import/application/import_persistence_provider.dart`
- related tests

Steps:

1. Show detected time ranges in preview with an explicit apply toggle.
2. Default the toggle off when evidence used a duration fallback; default it on only for complete explicit ranges.
3. Persist accepted settings to the target semester after course import succeeds.
4. Keep import successful with a warning if optional time persistence fails.

## Task 3: Complete Saved URL Management

Files:

- `lib/features/settings/domain/import_preferences.dart`
- `lib/features/settings/presentation/`
- `lib/features/import/presentation/course_import_page.dart`
- related tests

Steps:

1. Add a backward-compatible structured bookmark model with name and URL.
2. Build add/edit/remove/reorder controls in settings.
3. Normalize duplicates by URI and keep the selected academic URL synchronized.
4. Render bookmark names in import quick actions with host fallback.

## Task 4: Full-Screen Settings Route

Files:

- create `lib/features/settings/presentation/settings_page.dart`
- split or reuse focused section widgets from `settings_center_dialog.dart`
- modify `lib/features/timetable/presentation/timetable_page.dart`
- widget tests

Steps:

1. Add a full-screen scaffold with compact section navigation.
2. Move the four existing settings groups without changing their persistence owners.
3. Keep focused modal editors for individual values and confirmations.
4. Verify phone-width, large-text, and back-navigation behavior.

## Task 5: Glass Consistency And QA

Files:

- `lib/ui/glass.dart`
- `lib/ui/kiro_theme.dart`
- timetable/import/settings presentation files
- widget tests

Steps:

1. Use shared glass surfaces for page chrome and controls.
2. Keep the timetable grid legible with a high-opacity neutral surface instead of stacking expensive blur filters.
3. Add overflow tests for narrow phones and large text scaling.
4. Run visual device QA when an Android/iOS build environment is available.

## Verification

- `dart format --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `git diff --check`
- Android/iOS screenshots for timetable, settings, and import pages when a device toolchain is available.

## Residual Risks

- Academic systems use inconsistent markup; automatic time extraction must remain evidence-driven and optional.
- Some systems expose only section starts, so end times may require user confirmation.
- Multiple live blur layers can hurt low-end Android performance; the dense grid intentionally favors readability over maximum translucency.
