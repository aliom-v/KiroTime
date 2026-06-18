# Section Time Settings Plan

## Goal

Add per-semester class time schedules so KiroTime can show real start/end times on the timetable and in course details. The first version must keep the default 10-section layout, support three generated day parts (morning, afternoon, evening), allow manual per-section overrides, and keep time settings with each semester.

## Architecture

- `lib/features/timetable/domain/section_time_settings.dart` owns pure time-generation logic:
  - minute-of-day parsing/formatting,
  - per-section start/end records,
  - three-part generation rules,
  - section-count synchronization,
  - default timetable restoration.
- `SemesterSettings` owns semester metadata plus `SectionTimeSettings`.
- `SemesterRecord` persists section times as JSON text to avoid adding another Isar collection.
- `TimetableJsonCodec` includes section times in exported semester JSON and falls back to defaults for old backups.
- `SettingsCenterDialog` adds an "上课时间" entry under "课表设置" with:
  - generated section-time list,
  - quick three-part generation,
  - per-section edit,
  - restore defaults.
- `TimetablePage` reads the current semester's section times for:
  - left-side section time labels,
  - course detail time text,
  - conflict detail time text.

## Tech Stack

- Flutter / Dart
- Riverpod
- Isar
- Existing KiroTime centered dialog helper: `showKiroDialog`
- Existing widget tests and domain/database/import-export tests

## Baseline/Authority Refs

- `docs/aegis/plans/2026-06-17-timetable-settings-and-terms.md`
- `docs/aegis/plans/2026-06-17-settings-center-and-local-data.md`
- `docs/aegis/plans/2026-06-18-privacy-hardening.md`
- Current code owners:
  - `lib/features/timetable/domain/semester_settings.dart`
  - `lib/features/timetable/data/semester_record.dart`
  - `lib/features/settings/presentation/settings_center_dialog.dart`
  - `lib/features/timetable/presentation/timetable_page.dart`
  - `lib/features/import_export/domain/timetable_json_codec.dart`

## Compatibility Boundary

- Existing semesters without stored section-time JSON must load with the default generated timetable.
- Existing exported JSON files without `sectionTimes` must remain importable.
- `sectionCount` remains the source of how many rows the timetable renders.
- Changing `sectionCount` automatically resizes the section-time list without losing existing matching sections.
- Manual per-section edits are preserved until the user regenerates or restores defaults.
- Course schedule section numbers are unchanged; only display times are added.

## Verification

- Unit tests for time generation, long break insertion, section-count synchronization, parsing/formatting, and manual overrides.
- Database tests for semester section-time persistence and old-record fallback.
- JSON codec tests for section-time round trip and old JSON fallback.
- Widget tests for:
  - settings page exposes "上课时间",
  - left column shows real times from semester settings,
  - editing section count extends time rows,
  - course details include real time ranges.
- Full verification:
  - `dart format --set-exit-if-changed lib test`
  - `flutter analyze`
  - `flutter test`
  - `flutter build apk --release --split-per-abi`
  - `git diff --check`

## Task 1: Add Pure Section-Time Domain Model

Files:

- Create `lib/features/timetable/domain/section_time_settings.dart`
- Create `test/features/timetable/domain/section_time_settings_test.dart`
- Modify `lib/features/timetable/domain/semester_settings.dart`

Why:

The time rules should be testable without UI, database, or Riverpod.

Impact/Compatibility:

- Default 10-section schedule becomes explicit.
- `SemesterSettings` can still be constructed by old callers because the new field is optional.

Steps:

1. Write failing tests for default 10 sections, three-part generation, long break insertion, ensure-section-count, and manual section replacement.
2. Run the focused test and verify it fails because the model does not exist yet.
3. Add immutable model classes:
   - `SectionTime`
   - `DayPartTimeRule`
   - `SectionTimeSettings`
4. Add `sectionTimeSettings` to `SemesterSettings`, with constructor fallback and `copyWith`.
5. Run the focused test and verify it passes.

## Task 2: Persist Time Settings With Semesters

Files:

- Modify `lib/features/timetable/data/semester_record.dart`
- Regenerate `lib/features/timetable/data/semester_record.g.dart`
- Modify `test/core/database/kiro_time_database_test.dart`

Why:

Different semesters can use different work/rest schedules.

Impact/Compatibility:

- Existing Isar records get an empty JSON string and load defaults.
- No new collection is added.

Steps:

1. Add failing database tests for custom section-time persistence and empty-json fallback.
2. Run focused database tests and verify RED.
3. Add `sectionTimesJson` string field to `SemesterRecord`.
4. Encode/decode `SectionTimeSettings` through JSON in `fromSettings` and `toSettings`.
5. Run `dart run build_runner build --delete-conflicting-outputs`.
6. Run focused database tests and verify GREEN.

## Task 3: Include Section Times In Local JSON Backup

Files:

- Modify `lib/features/import_export/domain/timetable_json_codec.dart`
- Modify `test/features/import_export/domain/timetable_json_codec_test.dart`

Why:

Local import/export should preserve user-edited time settings.

Impact/Compatibility:

- Exported JSON adds `sectionTimes`.
- Importing older JSON without `sectionTimes` still uses defaults.

Steps:

1. Add failing JSON round-trip and old-JSON fallback tests.
2. Run focused codec tests and verify RED.
3. Encode `sectionTimeSettings.toJson()` under each semester.
4. Decode `sectionTimes` with a default fallback.
5. Run focused codec tests and verify GREEN.

## Task 4: Build Settings UI For Class Times

Files:

- Modify `lib/features/settings/presentation/settings_center_dialog.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

Users need a local, non-ADB way to generate, edit, and restore class times.

Impact/Compatibility:

- Keeps the existing settings center.
- Adds one entry under "课表设置" without moving import/export or appearance settings.

Steps:

1. Add failing widget tests that open settings and find "上课时间", the section list, and restore defaults.
2. Add an action tile under "每日节数".
3. Implement centered section-time settings dialog.
4. Implement per-section centered edit dialog.
5. Implement three-part generation dialog with morning/afternoon/evening rules.
6. Wire changes to `_editingSemester` and save through the existing settings save path.
7. Run focused widget tests and verify GREEN.

## Task 5: Render Real Times On Timetable And Course Details

Files:

- Modify `lib/features/timetable/presentation/timetable_page.dart`
- Modify `test/widget/timetable_page_test.dart`

Why:

The main timetable must show actual times instead of hardcoded placeholders.

Impact/Compatibility:

- Timetable layout stays Stack/Table based.
- Section rows still use section numbers for positioning.
- Course cards remain unchanged; details gain time range text.

Steps:

1. Add failing widget tests for left-column time labels and course detail real-time text.
2. Pass `SectionTimeSettings` into the board/grid.
3. Replace `_SectionTimeCell` hardcoded times with semester section times.
4. Add helper formatting for schedule ranges, for example `周一 第1-2节 08:10-09:50`.
5. Use the helper in course detail and conflict detail dialogs.
6. Run focused widget tests and verify GREEN.

## Task 6: Version, Verification, Build, Install, Commit

Files:

- Modify `pubspec.yaml`
- Generated Android/Flutter build output is not committed.

Why:

This is a user-visible feature release.

Impact/Compatibility:

- Version moves from `0.1.2+3` to `0.1.3+4`.

Steps:

1. Bump `pubspec.yaml` version.
2. Run formatting.
3. Run `flutter analyze`.
4. Run `flutter test`.
5. Build Android release split APKs.
6. If ADB is connected, install the current debug/release artifact for manual verification.
7. Check `git status --short` and `git diff --check`.
8. Commit with a concise feature message.

## Risks And Follow-Ups

- The first version uses a generated list plus manual overrides. It does not attempt per-week summer/winter schedules.
- Three-part generation is intentionally local to settings; imports do not infer class times from school HTML yet.
- If a school has non-linear section naming, the app still stores numeric sections and displays time ranges for those numbers.
- Future work can add named presets, import/export of standalone time presets, and a compact time editor optimized for landscape/tablet screens.
