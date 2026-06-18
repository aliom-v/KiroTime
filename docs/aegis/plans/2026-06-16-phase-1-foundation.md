# Phase 1 Foundation Plan

## Goal

Initialize KiroTime as a Flutter app with Riverpod, Isar data collections, local mock data, and a timetable grid that renders current-week courses using a `Table` background and `Stack` absolute positioning.

## Architecture

- `lib/core/database/`: Isar opening and seeding.
- `lib/features/courses/data/`: Isar collection models and generated-part declarations.
- `lib/features/timetable/`: providers, layout calculation, and timetable UI.
- `test/`: unit/widget tests for week filtering and layout rules.

## Tech Stack

- Flutter / Dart
- `flutter_riverpod`
- `isar`, `isar_flutter_libs`, `isar_generator`
- `build_runner`
- `path_provider`
- `uuid`

## Baseline/Authority Refs

- User-provided KiroTime development document.
- `DEVELOPMENT_PLAN.md`.
- Flutter package versions checked from `pub.dev` on 2026-06-16.

## Compatibility Boundary

- `CourseSchedule.weeks` is an explicit `List<int>` and is the canonical representation for odd/even weeks, skipped weeks, and unusual teaching weeks.
- A course may have multiple schedules through `CourseSchedule.courseMetaId`.
- Overlaps are legal and must render as visible overlapping cards rather than being rejected.
- The public `id` fields remain strings. Isar's integer primary key is derived through `isarId`, following Isar's documented string-id recipe.

## Verification

Because `flutter`, `dart`, and `fvm` are not available in the current `PATH`, this plan includes two verification levels:

- Current machine: file existence, git status, and source review.
- Flutter-enabled machine: `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `flutter test`, and `flutter analyze`.

## Tasks

### Task 1: Scaffold project metadata

Files:

- `pubspec.yaml`
- `analysis_options.yaml`
- platform placeholder directories as needed

Steps:

1. Write Flutter metadata and dependencies.
2. Add lints configuration.
3. Verify files are tracked by `git status --short`.

### Task 2: Add data model and database owner

Files:

- `lib/features/courses/data/course_meta.dart`
- `lib/features/courses/data/course_schedule.dart`
- `lib/core/database/isar_database.dart`
- `lib/core/database/mock_course_seed.dart`

Steps:

1. Write Isar collection definitions.
2. Write local seed data that covers normal, odd/even, overlapping, and multi-schedule cases.
3. Keep generated `*.g.dart` files out until build_runner can run.

### Task 3: Add timetable domain logic and providers

Files:

- `lib/features/timetable/domain/timetable_layout.dart`
- `lib/features/timetable/application/timetable_providers.dart`

Steps:

1. Write pure filtering/layout helpers.
2. Write Riverpod providers for `currentWeek`, database, and current-week schedules.
3. Keep UI-independent logic testable without Isar runtime.

### Task 4: Add timetable UI

Files:

- `lib/main.dart`
- `lib/app.dart`
- `lib/features/timetable/presentation/timetable_page.dart`

Steps:

1. Wrap app in `ProviderScope`.
2. Build a week selector and timetable scaffold.
3. Render 7 x 12 background grid with `Table`.
4. Render courses with `Stack` and `Positioned`.

### Task 5: Add tests and evidence

Files:

- `test/features/timetable/domain/timetable_layout_test.dart`
- `test/widget/timetable_page_test.dart`
- `docs/aegis/work/2026-06-16-phase-1-foundation/90-evidence.md`

Steps:

1. Add tests for current-week filtering.
2. Add tests for layout calculation.
3. Record that Flutter execution is blocked locally by missing SDK.

## Risks

- Isar generated files require `build_runner`; without local Dart, generated code cannot be produced in this environment.
- A manually written Flutter scaffold may need `flutter create . --platforms=android,ios,linux,macos,windows,web` later to add native runners.
- Widget and analyzer verification must be run after Flutter is installed.

## Rollback Surface

The work is isolated on branch `phase-1-foundation`. Rollback is a branch deletion or worktree removal before merging.
