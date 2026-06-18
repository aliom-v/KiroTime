# KiroTime Development Plan

## 1. Vision

KiroTime is an open-source, cross-platform timetable app focused on:

- Extreme lightness: no ads, no social layer, fast startup.
- Local-first data: user timetable data stays on the client.
- Zero server cost: multi-device sync is deferred to user-owned WebDAV storage.
- Robust timetable modeling: the data model must support single/double weeks, skipped weeks, one course with multiple time slots, and overlapping courses.

## 2. Technical Direction

- App framework: Flutter / Dart
- Minimum Dart SDK for current dependencies: 3.10.0
- State management: Riverpod
- Local database: Isar
- Network and parsing: `webview_flutter` + `html` for Phase 2 local import; `dio` remains deferred until direct network requests are needed
- Home widgets, deferred to Phase 4: `home_widget`
- Sync, deferred to Phase 3: `webdav_client`

## 3. Core Data Model

KiroTime deliberately separates course metadata from concrete lesson schedules.

### CourseMeta

`CourseMeta` owns stable course information:

- `id`: unique string id
- `name`: course name
- `teacher`: teacher name

### CourseSchedule

`CourseSchedule` owns one concrete time/place occurrence:

- `id`: unique string id
- `courseMetaId`: linked `CourseMeta.id`
- `classroom`: classroom or campus location
- `dayOfWeek`: 1 to 7
- `startSection`: first class section
- `endSection`: last class section
- `weeks`: explicit week list, for example `[1, 2, 3, 5, 7, 9]`

The explicit `weeks` array is the compatibility boundary for complicated Chinese university timetables. Rendering must filter by membership in `weeks`, not by lossy odd/even flags.

Storage note: Isar uses an integer `Id` internally. KiroTime keeps the public business `id` as a string and derives the Isar `isarId` from that string with a stable 64-bit hash.

## 4. Phase Plan

### Phase 1: Infrastructure and Local Mock Rendering

Status: completed.

Scope:

- Initialize Flutter project structure.
- Configure Riverpod and Isar dependencies.
- Add Isar collection definitions for `CourseMeta` and `CourseSchedule`.
- Add local data access services.
- Add a `currentWeek` state provider.
- Render a 7 x 12 timetable view with a `Table` background and `Stack` + `Positioned` course cards.
- Seed mock data locally so the timetable can render without Phase 2 import logic.

Non-goals:

- No WebView import.
- No WebDAV sync.
- No native home widget.
- No backend.

### Phase 2: Safe Local HTML Parsing

Current priority. Initial generic local parser and WebView import entry are implemented.

- Use `webview_flutter` for manual login to school systems.
- Extract `document.documentElement.outerHTML`.
- Parse local HTML with Dart `html`.
- Convert table cell data into `CourseMeta` and `CourseSchedule`.

### Phase 3: WebDAV Backup and Sync

Deferred.

- Add settings for WebDAV endpoint, account, and app password.
- Export Isar data to JSON.
- Encrypt and upload the JSON backup.
- Support one-tap restore.

### Phase 4: Platform Widgets

Deferred.

- iOS Widget Extension reads today's JSON through App Group storage.
- Android AppWidget refreshes from `home_widget` transferred data.

## 5. Phase 1 Acceptance Criteria

- `pubspec.yaml` declares Flutter, Riverpod, Isar, generator, and test dependencies.
- `CourseMeta` and `CourseSchedule` are Isar collections.
- Query logic can return only schedules whose `weeks` contains `currentWeek`.
- UI uses `Table` for the 7 x 12 background and `Stack` with absolute positioning for cards.
- Mock data includes at least:
  - one multi-week normal course,
  - one odd/even-style course represented as explicit weeks,
  - one overlapping course,
  - one single course with multiple schedules.
- Tests cover the week-filtering and card layout calculation rules.

## 6. Environment Note

This repository was scaffolded on a machine where `flutter` and `dart` were not available in `PATH`. Source files, project metadata, and tests are written so that the first full verification after installing Flutter is:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```
