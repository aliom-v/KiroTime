# Import Probe And Preview Plan

## Goal

Improve KiroTime import reliability after reports that imported courses can stack into one timetable slot:

- Add a WebView-side semester API probe before HTML fallback.
- Show an import preview before replacing the selected semester.
- Add a diagnostic summary when probing fails or parsed schedules look suspicious.
- Make HTML fallback more conservative so outer timetable containers are not parsed as course cards.

## Architecture

- `lib/features/import/domain/academic_timetable_api_probe.dart` owns pure candidate path generation, probe result models, and suspicious import summarization.
- `lib/features/import/domain/academic_timetable_html_parser.dart` remains the pure HTML parsing owner.
- `lib/features/import/domain/academic_timetable_json_parser.dart` remains the JSON payload parsing owner.
- `lib/features/import/presentation/course_import_page.dart` owns WebView JavaScript execution, probe orchestration, preview dialog, and persistence after confirmation.
- `lib/features/settings/domain/import_preferences.dart` continues to own saved import preferences, including the selected semester API path.
- `KiroTimeDatabase.replaceWithImportedData` remains the only persistence path for replacing current-semester courses.

## Tech Stack

- Flutter / Dart
- Riverpod
- WebView JavaScript via `webview_flutter`
- `html` local parsing
- Existing Flutter test framework

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: Phase 2 import is local-only and no backend crawler is introduced.
- `docs/aegis/plans/2026-06-16-phase-2-html-import.md`: WebView import page extracts local page state and parser stays pure domain logic.
- `docs/aegis/plans/2026-06-18-privacy-hardening.md`: no hard-coded school endpoint; defaults remain privacy-first.
- `docs/aegis/plans/2026-06-17-timetable-conflicts-and-semester-persistence.md`: import replaces only the selected semester.

## Compatibility Boundary

- Do not hard-code a school domain or real account data.
- Do not save cookies, HTML, or diagnostics unless existing settings explicitly allow it.
- Do not replace timetable data until the user confirms a preview.
- Keep `semesterApiPath` optional; empty values still use HTML fallback.
- Keep JSON parser field mapping stable: `kbList` / `sjkList`, `kcmc`, `xm`, `jxbmc`, `xqj`, `jcs`, `zcd`, `xqmc`, `cdmc`.
- Keep HTML fallback available, but make it reject ambiguous outer containers rather than inventing a placement.
- Existing local JSON import/export format is not changed.

## Verification

- `flutter test test/features/import/domain/academic_timetable_api_probe_test.dart`
- `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart test/features/import/domain/academic_timetable_json_parser_test.dart`
- `flutter test test/widget/timetable_page_test.dart`
- `flutter analyze`
- Manual Android verification when ADB is available:
  - Open import page.
  - Log in to timetable page.
  - Tap `自动探测接口`.
  - Confirm preview shows source, schedule count, conflict/suspicious summary, and candidate path.
  - Confirm import only writes after pressing confirm.

## Task 1: Pure Probe Models And Suspicious Preview Summary

Files:

- Create `lib/features/import/domain/academic_timetable_api_probe.dart`
- Create `test/features/import/domain/academic_timetable_api_probe_test.dart`

Why:

The UI needs deterministic, testable rules for candidate endpoint generation and for detecting obviously bad parse results such as many schedules occupying one time slot.

Impact/Compatibility:

- Pure domain code only; no WebView, storage, or UI side effects.
- Enables import preview to block suspicious imports before persistence.

Steps:

1. Write tests for:
   - extracting candidate API paths from page path/script text,
   - preserving configured API path as first candidate,
   - deduplicating candidates,
   - summarizing slot counts and marking a slot suspicious when too many schedules share the same day/start/end.
2. Run:
   - `flutter test test/features/import/domain/academic_timetable_api_probe_test.dart`
   - Expected RED because the file does not exist.
3. Implement:
   - `AcademicTimetableApiProbe.buildCandidatePaths`.
   - `ImportPreviewSummary.fromTimetable`.
   - `TimetableSlotCount` value type.
4. Run the same test and expect GREEN.

## Task 2: Probe And Preview UI Flow

Files:

- Modify `lib/features/import/presentation/course_import_page.dart`
- Modify `test/widget/timetable_page_test.dart` if widget coverage can reach the import dialog without real WebView.

Why:

Users need to know what will be imported before current-semester courses are replaced. This is the main protection against stacked bad data.

Impact/Compatibility:

- Adds `自动探测接口` button.
- Import button now parses first, opens preview, and writes only after confirmation.
- If a configured API path succeeds, behavior remains equivalent except for the confirmation step.
- If probe succeeds, save the discovered API path into import preferences.

Steps:

1. Add small helper methods in `course_import_page.dart`:
   - `_probeSemesterApiCandidates`.
   - `_readSemesterTimetableJsonFromPath`.
   - `_showImportPreview`.
   - `_persistImportedTimetable`.
2. Keep existing `_readSemesterTimetableJson` behavior as a compatibility wrapper or retire it after all callers move to candidate-based probing.
3. Add UI:
   - Button `自动探测接口`.
   - Preview dialog with source, path, schedule count, course count, suspicious slot warning, and actions `取消` / `确认导入`.
4. Run:
   - `flutter test test/features/import/domain/academic_timetable_api_probe_test.dart`
   - `flutter test test/features/import/domain/academic_timetable_json_parser_test.dart`

## Task 3: Probe Failure Diagnostics

Files:

- Modify `lib/features/import/presentation/course_import_page.dart`

Why:

When automatic probing fails, the user should be able to provide enough summary data without exposing full HTML or credentials.

Impact/Compatibility:

- Existing `复制诊断摘要` action remains.
- Summary adds probe candidates, last probe errors, parsed schedule preview, and slot distribution.
- Full HTML remains excluded from summary.

Steps:

1. Track:
   - `_lastProbeCandidates`
   - `_lastProbeErrors`
   - `_lastPreviewSummary`
2. Extend `_buildDebugSummary` with:
   - candidate paths,
   - per-path status/error,
   - parsed schedule count,
   - top crowded slots.
3. Run:
   - `flutter test test/features/import/domain/academic_timetable_api_probe_test.dart`
   - `flutter analyze`

## Task 4: Conservative HTML Fallback Repair

Files:

- Modify `lib/features/import/domain/academic_timetable_html_parser.dart`
- Modify `test/features/import/domain/academic_timetable_html_parser_test.dart`

Why:

Outer timetable containers can contain many course texts and week texts but only one guessed placement. Parsing such a container as a single card can create stacked or malformed schedules.

Impact/Compatibility:

- Real cells/cards with explicit placement still parse.
- Ambiguous outer containers are ignored.
- Table parsing remains the preferred HTML fallback path.

Steps:

1. Add failing tests:
   - an outer `kb` container with many nested lessons and one style position must not parse as one course/card,
   - direct child lesson cards with explicit placement still parse.
2. Run:
   - `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart`
   - Expected RED for the ambiguous-container case.
3. Implement stricter `_looksLikeTimetableCard`:
   - reject elements with multiple nested course-like descendants,
   - require the element itself to have explicit placement or a single lesson-like text block,
   - avoid parsing ancestor containers when descendants already look like lesson cards.
4. Run parser tests and expect GREEN.

## Task 5: Full Verification And Release Readiness

Files:

- `pubspec.yaml` only if version bump is requested after verification.

Why:

Import behavior is user-visible and affects persisted course data.

Impact/Compatibility:

- No release artifact is committed.
- Keystore files remain ignored.

Steps:

1. Run:
   - `flutter analyze`
   - `flutter test`
2. If Android device is connected:
   - `flutter build apk --debug`
   - `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
3. Check:
   - `git status --short --branch`
   - `git diff --check`

## Repair Track

- Root cause class: imported data can be written without preview even when parser output is suspicious.
- Canonical owner: import orchestration in `course_import_page.dart`, parse rules in import domain files.
- Minimal repair: add candidate API probing, preview confirmation, diagnostic summaries, and conservative HTML fallback rejection.
- Verification: domain tests for candidate/summary/parser behavior plus import regression tests.

## Retirement Track

- Retired behavior: direct parse-and-replace import with no preview.
- Retained boundary: one-tap import still exists after preview confirmation; HTML fallback remains available.
- Future deletion trigger: if JSON API probing proves reliable across target schools, reduce HTML fallback priority further.

## Risks

- Android WebView cannot expose full browser Network request history, so probing uses page variables and candidate requests rather than passive packet capture.
- Some schools may require extra POST parameters. Probe failure must be diagnosable and non-destructive.
- Widget testing of real WebView UI is limited; pure domain rules and manual device verification carry part of the confidence.
