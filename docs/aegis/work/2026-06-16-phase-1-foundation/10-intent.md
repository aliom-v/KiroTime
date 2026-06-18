# Phase 1 Foundation Intent

## Requested Outcome

Create the initial KiroTime Flutter project in `<project-root>`, write the development plan, configure Riverpod and Isar, implement the Phase 1 course data model, and build a local mock timetable grid view.

## Scope

- Flutter app scaffold files and source directories.
- Isar model definitions for `CourseMeta` and `CourseSchedule`.
- Local database service and seed mock data.
- Riverpod providers for database access, `currentWeek`, and visible schedules.
- Timetable grid UI using `Table` background plus `Stack`/`Positioned` cards.
- Focused unit/widget test source for filtering and layout rules.

## Non-goals

- School WebView import.
- HTML parser.
- WebDAV sync.
- Native widget extensions.
- Backend service.

## BaselineReadSetHint

- User-provided KiroTime development document in the conversation.
- `DEVELOPMENT_PLAN.md`.
- `pubspec.yaml` after creation.
- `lib/features/timetable/` owners after creation.

## ImpactStatementDraft

This task establishes the first app architecture and data contracts. The strongest compatibility boundary is that week participation is stored as an explicit integer list on `CourseSchedule.weeks`; future import, sync, and widgets must preserve that representation unless a later migration is deliberately designed.
