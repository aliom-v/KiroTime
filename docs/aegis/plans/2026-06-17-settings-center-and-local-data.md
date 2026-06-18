# Settings Center And Local Data Plan

## Goal

Implement the next KiroTime settings slice:

- Replace the old semester bottom sheet with a settings center organized into four groups: timetable settings, appearance, import/export, and advanced settings.
- Make semester creation explicit: users can choose school year, semester, start date, total weeks, and daily section count, including earlier semesters.
- Stop using the top week label as a shortcut to full settings. It should open only a lightweight week picker.
- Persist appearance and import preferences locally through `AppSettingRecord`.
- Add local JSON import/export so users can back up and restore data without ADB or repeated school-system import.

## Architecture

- `lib/features/timetable/presentation/timetable_page.dart` remains the timetable screen owner, but only owns timetable layout and top-level settings entry wiring.
- New settings UI lives under `lib/features/settings/presentation/`.
- New settings application providers live under `lib/features/settings/application/`.
- New settings domain objects live under `lib/features/settings/domain/`.
- New import/export JSON codec lives under `lib/features/import_export/domain/`.
- `KiroTimeDatabase` remains the canonical Isar persistence owner. It gains narrow methods for app settings, semester creation/update support, clearing a semester, and export/import snapshots.
- No new Isar collections are required in this slice. Preferences are stored as JSON strings in `AppSettingRecord`.

## Tech Stack

- Flutter / Dart
- Riverpod
- Isar
- `AppSettingRecord` for local key-value settings
- Clipboard JSON import for this build slice, avoiding Android plugin build risk.
- App Documents JSON export with exported path copied to clipboard.

`file_picker` / platform save panels are deferred because the current Android Gradle chain failed against available plugin versions. The JSON codec and database import/export contract are plugin-independent, so a native file picker can be added later without changing the data format.

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: local-first, no-backend timetable app.
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`: ownership boundaries and compatibility rules.
- `docs/aegis/plans/2026-06-17-course-dialogs-management-and-polish.md`: centered dialog style and card interaction direction.
- Current user requirements from 2026-06-17 settings request.

## Compatibility Boundary

- Do not change `CourseMeta.id`, `CourseSchedule.id`, `CourseSchedule.courseMetaId`, or explicit `CourseSchedule.weeks`.
- Imported school courses still replace only the currently selected semester.
- Deleting a semester still deletes only that semester's schedules and orphan metas.
- JSON import must not silently merge into the wrong semester: current-semester import replaces the current semester; all-semester import replaces the full local timetable state.
- The default timetable remains 10 daily sections.

## Verification

- Widget tests for:
  - top week label opens a week picker, not the settings center,
  - settings button opens a settings center with four groups,
  - semester creation can target an earlier school year/semester,
  - appearance settings affect card density/font/weekend visibility.
- Database/unit tests for:
  - app setting JSON round-trip,
  - timetable JSON export/import round-trip for current semester,
  - all-semester export/import round-trip.
- Manual/device verification:
  - `flutter test`
  - `flutter analyze`
  - `flutter build apk --debug`
  - `adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk`

## Task 1: Settings Domain And Persistence

Files:

- Create `lib/features/settings/domain/timetable_appearance_settings.dart`
- Create `lib/features/settings/domain/import_preferences.dart`
- Create `lib/features/settings/application/settings_providers.dart`
- Modify `lib/core/database/isar_database.dart`
- Add/modify database tests

Why:

Appearance and import settings need to survive app restart without adding schema churn.

Impact/Compatibility:

- Uses existing `AppSettingRecord`.
- Keeps old selected semester key untouched.

Steps:

1. Write failing tests for `readAppSetting`, `saveAppSetting`, and settings JSON round-trip.
2. Implement narrow app setting helpers in `KiroTimeDatabase`.
3. Implement immutable settings classes with `toJson`/`fromJson` defaults.
4. Implement Riverpod providers that load, save, and expose settings.
5. Verify target tests and run formatting.

## Task 2: Timetable Settings Center

Files:

- Create `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify `lib/features/timetable/application/timetable_providers.dart`
- Modify widget tests

Why:

The old bottom sheet mixes semester CRUD with low-level fields and cannot add earlier terms cleanly.

Impact/Compatibility:

- Settings opens from the gear button.
- Existing semester update/delete providers remain the save path.
- Add semester provider changes from "next semester only" to explicit settings input.

Steps:

1. Write failing widget tests for settings groups and earlier-semester creation.
2. Replace `_SemesterSettingsSheet` with a centered settings center dialog.
3. Add scroll wheel pickers for school year, semester, start year/month/day, total weeks, and daily sections.
4. Keep rename/delete confirmation behavior.
5. Verify widget tests.

## Task 3: Lightweight Week Picker

Files:

- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify widget tests

Why:

The top "第几周" label should not route users into full settings.

Impact/Compatibility:

- Previous/next arrows and horizontal swipe remain unchanged.
- Tapping the week label opens only a centered week picker.

Steps:

1. Write failing widget test that tapping `第16周` shows `选择周数` and does not show settings groups.
2. Change `_WeekStepper` tooltip/semantics to week selection.
3. Implement compact wheel/list week picker clamped to `1..totalWeeks`.
4. Verify widget tests.

## Task 4: Appearance Settings Applied To Timetable

Files:

- Modify `lib/features/settings/domain/timetable_appearance_settings.dart`
- Modify `lib/features/settings/application/settings_providers.dart`
- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify widget tests

Why:

Users need local control over weekend display, density, font size, and color scheme.

Impact/Compatibility:

- Course cards still default to pastel fixed-per-course colors.
- If weekend display is off, weekdays render as 5 columns and weekend courses are hidden from the main board.
- Density/font changes are presentation only.

Steps:

1. Write failing widget tests for weekend toggle and card density/font labels.
2. Add settings controls under the appearance section.
3. Apply settings to header weekday count, board day column count, card padding/font, and palette selection.
4. Verify widget tests.

## Task 5: Local JSON Import/Export

Files:

- Create `lib/features/import_export/domain/timetable_json_codec.dart`
- Create `lib/features/import_export/application/import_export_providers.dart`
- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `lib/core/database/isar_database.dart`
- Modify `pubspec.yaml`
- Add tests

Why:

Local JSON backup/restore removes the need to rely on ADB or the school WebView import every time.

Impact/Compatibility:

- Export current semester includes selected semester metadata, metas, and schedules scoped to that semester.
- Export all semesters includes all semesters, selected semester id, metas, schedules, and app settings.
- Import current semester replaces the current semester only.
- Import all semesters replaces timetable-owned data and selected semester id.

Steps:

1. Add dependencies and run `flutter pub get`.
2. Write failing codec round-trip tests with teaching class, weeks, semester settings, and app settings.
3. Add database snapshot methods and import methods.
4. Add settings UI actions:
   - 从剪贴板 JSON 导入
   - 导出当前学期 JSON
   - 导出全部学期 JSON
   - 清空当前学期课程
   - 导入前预览
5. Verify tests, analyze, build, and device install.

## Risks And Rollback

- Native file picker/save-panel plugins may require Gradle-compatible versions. Current slice keeps the JSON contract and uses clipboard/path export to avoid blocking Android install.
- Full all-semester import is destructive. It must show a preview and confirmation before replacing local data.
- Appearance settings change the board column count when weekends are hidden. Tests must cover both 5-day and 7-day layouts.

## Non-Goals

- WebDAV sync.
- Native desktop/home-screen widgets.
- Editing class time ranges beyond the existing fixed section time labels.
- Fixing unresolved second-semester school parser ambiguity without a trusted second-semester PDF/HTML baseline.
