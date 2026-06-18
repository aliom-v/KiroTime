# Phase 2 HTML Import Intent

## Requested Outcome

Install KiroTime to the connected Android device and begin Phase 2 by adding a safe local WebView HTML import flow.

## Scope

- Configure Android build/install environment under the user home directory.
- Generate Android runner if missing.
- Add `webview_flutter` and `html`.
- Add local parser, persistence replacement method, WebView import page, and timetable refresh.
- Add focused tests for parser behavior.

## Non-Goals

- No backend crawler.
- No WebDAV sync.
- No native home screen widget.
- No school-specific hardcoded adapter in this slice.

## BaselineReadSetHint

- `DEVELOPMENT_PLAN.md`
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`
- `lib/core/database/isar_database.dart`
- `lib/features/courses/data/course_meta.dart`
- `lib/features/courses/data/course_schedule.dart`
- `lib/features/timetable/application/timetable_providers.dart`
- `lib/features/timetable/presentation/timetable_page.dart`

## ImpactStatementDraft

Affected layers are import domain, local persistence, timetable state refresh, timetable UI navigation, dependencies, and Android platform runner. The existing course data contract must remain stable: explicit week lists and one-to-many course metadata to schedules.
