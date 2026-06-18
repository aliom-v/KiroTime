# Initial Baseline

## Project Structure

- `DEVELOPMENT_PLAN.md`: product vision, phased roadmap, and Phase 1 acceptance criteria.
- `pubspec.yaml`: Flutter package metadata and dependency constraints.
- `lib/main.dart` and `lib/app.dart`: app entry and Material shell.
- `lib/core/database/`: Isar database opening, string-id hashing, and mock seed data.
- `lib/features/courses/data/`: `CourseMeta` and `CourseSchedule` Isar collections.
- `lib/features/timetable/`: timetable providers, layout rules, and UI.
- `test/`: planned unit/widget tests.

## Tech Stack

- Flutter / Dart SDK `>=3.10.0 <4.0.0`
- Riverpod for state management
- Isar for local persistence
- `build_runner` and `isar_generator` for generated collection code

## Ownership Mapping

- Course data contract: `lib/features/courses/data/`
- Local persistence: `lib/core/database/`
- Timetable filtering/layout: `lib/features/timetable/domain/`
- Timetable state composition: `lib/features/timetable/application/`
- Timetable UI: `lib/features/timetable/presentation/`

## Contract Inventory

- `CourseMeta.id`: public string course identifier.
- `CourseSchedule.id`: public string schedule identifier.
- `CourseSchedule.courseMetaId`: link to `CourseMeta.id`.
- `CourseSchedule.weeks`: explicit week membership list.
- `TimetableLayout.filterSchedulesForWeek`: filters by `weeks.contains(currentWeek)`.
- `TimetableLayout.buildPlacements`: maps schedules to absolute grid placement and overlap lanes.

## Dependency Direction

UI depends on providers. Providers depend on database and domain layout. Domain layout depends only on course data models. Database owns Isar access and seed data.

## Test System

Flutter test files exist for:

- string-id hashing,
- week filtering,
- overlap placement,
- basic timetable page expectations.

Full execution is blocked until Flutter/Dart are available in `PATH`.

## Build And Deploy

No CI or deployment pipeline exists yet. First full local verification command:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```

## Known Anti-patterns

- Do not collapse `CourseSchedule.weeks` into odd/even flags.
- Do not reject overlapping schedules; they are valid timetable states.
- Do not introduce a backend for Phase 1.
- Do not hand-write Isar generated files.

## Compatibility Boundaries

- Public course and schedule identifiers remain strings.
- Isar internal IDs are derived from public string IDs.
- Week filtering is based on explicit week membership.
- A course can have multiple schedules.
