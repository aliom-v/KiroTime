# Import Parser Residual Hardening Plan

## Goal

Repair the remaining timetable import risks identified after the first parser hardening pass:

1. Parse `grid-area` row spans correctly.
2. Stop treating pixel offsets as percentages and infer common 12-row versus 16-row percentage layouts conservatively.
3. Reject impossible imported sections and weeks instead of persisting off-grid data.
4. Rank fuller API candidates before using crowded-slot warnings as a tie-breaker.
5. Keep crowded-slot warnings visible while allowing an explicit user override.
6. Replace blocking synchronous XHR with an asynchronous JavaScript-channel request that has browser-side and Dart-side timeouts.
7. Keep candidate diagnostics isolated and persist the detected path only after the core timetable replacement succeeds.

## Architecture

- `academic_timetable_html_parser.dart` remains the canonical owner of HTML structure, placement, and HTML week-line recognition.
- `academic_timetable_json_parser.dart` remains the canonical owner of school JSON field validation.
- `academic_timetable_api_probe.dart` remains the canonical owner of pure candidate comparison and crowded-slot summaries.
- A small `semester_api_probe_client.dart` presentation helper owns asynchronous JavaScript request lifecycle, request IDs, channel message decoding, and timeouts without depending on `WebViewController` directly.
- A small `import_preview_dialog.dart` widget owns preview rendering and the explicit suspicious-result override.
- A small `import_persistence_sequence.dart` helper owns core-versus-optional ordering, while `import_persistence_provider.dart` composes database replacement, optional state persistence, and cache refresh outside the page lifecycle.
- `course_import_page.dart` remains the composition owner for WebView, providers, diagnostics, and user-triggered import flow.

## Tech Stack

- Flutter / Dart
- Riverpod
- `webview_flutter` JavaScript channels
- `html` DOM parser
- Isar
- Flutter test framework

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: import remains local-first through a manually authenticated WebView; WebDAV and backend crawling remain deferred.
- `docs/aegis/BASELINE-GOVERNANCE.md`: preserve canonical ownership, explicit compatibility boundaries, and retirement tracking.
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`: overlapping schedules are valid and week membership remains an explicit list.
- `docs/aegis/plans/2026-06-16-phase-2-html-import.md`: parsers remain independent of Flutter UI and Isar.
- `docs/aegis/plans/2026-06-20-import-probe-preview.md`: preview confirmation remains mandatory before timetable replacement.
- `docs/aegis/plans/2026-07-18-import-parser-hardening.md`: direct table rows, explicit/Grid section bounds, and HTML fallback behavior remain compatible.
- `lib/features/timetable/domain/semester_settings.dart`: imported sections must remain within 1-16.
- `lib/features/timetable/domain/academic_calendar.dart`: imported week values must remain within 1-24.

## Compatibility Boundary

- Do not add WebDAV, backend services, analytics, school-specific domains, or direct Dart HTTP requests.
- Do not change `CourseMeta`, `CourseSchedule`, Isar schemas, or local JSON import/export.
- Keep overlapping courses valid. Crowded-slot detection is a warning and candidate tie-breaker, never an unconditional rejection rule.
- Preserve the established 12-row percentage interpretation when 12-row and 16-row layouts are equally plausible.
- Reject unsupported pixel-only placement instead of inventing a section. Text, explicit attributes, table structure, and Grid placement continue to take precedence.
- Keep HTML fallback available when every API candidate fails.
- Timetable replacement is the core success boundary. Optional semester metadata and detected-path persistence run only after it succeeds and may produce warnings without reporting the core import as failed.

## Verification

- `flutter test test/features/courses/domain/course_week_text_test.dart`
- `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart`
- `flutter test test/features/import/domain/academic_timetable_json_parser_test.dart`
- `flutter test test/features/import/domain/academic_timetable_api_probe_test.dart`
- `flutter test test/features/import/presentation/import_preview_dialog_test.dart`
- `flutter test test/features/import/presentation/semester_api_probe_client_test.dart`
- `flutter test test/features/import/application/import_persistence_sequence_test.dart`
- `flutter test test/features/import`
- `flutter analyze --no-pub`
- `flutter test --no-pub`
- `git diff --check`

## Considered Approaches

### A. Add school-specific parser and endpoint adapters

This could encode exact row counts and expected API payload sizes, but it would introduce school-specific ownership and conflict with the generic local-first import contract. Rejected.

### B. Apply conservative generic inference and isolate side-effect coordinators

This repairs confirmed logic, makes asynchronous request and persistence ordering testable, and preserves generic compatibility. Chosen.

### C. Keep current parsing and only strengthen warning text

This would leave incorrect Grid spans, pixel misplacement, WebView blocking, and invalid persisted data active. Rejected.

## Task 1: HTML Placement And Week-Line Validation

Files:

- Create `test/features/courses/domain/course_week_text_test.dart`
- Modify `lib/features/courses/domain/course_week_text.dart`
- Modify `test/features/import/domain/academic_timetable_html_parser_test.dart`
- Modify `lib/features/import/domain/academic_timetable_html_parser.dart`

Why:

`grid-area` still sends `span N` through the absolute-line parser. Absolute placement accepts `px` but divides it by percentage row height. HTML also treats a bare numeric detail line as week text and accepts out-of-range text sections.

Impact/Compatibility:

- Existing Grid shorthand and separate start/end declarations stay valid.
- 12-row percentage fixtures stay unchanged.
- A 16-row percentage fixture with values that align more closely to 16 rows parses sections 13-16.
- Ambiguous percentage fixtures retain 12 rows.
- Pixel-only cards and invalid text sections are skipped rather than misplaced.
- Marked week lines such as `1-16周`, odd/even expressions, and range/list forms remain valid; a bare classroom number no longer creates a schedule.

Steps:

1. Add failing tests named:
   - `parses grid-area row span values`
   - `infers sixteen-row percentage placement when alignment is stronger`
   - `keeps ambiguous percentage placement on twelve rows`
   - `does not guess sections from pixel-only positioning`
   - `rejects out-of-range text sections`
   - `does not treat a bare classroom number as week text`
2. Run `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart` and confirm the new assertions fail for the current parser behavior.
3. Implement `_parseGridArea` through `_parseGridLineRange`, require `%` units in percentage placement, add a 12/16 alignment scorer with 12-row tie preference, validate text section bounds against `SemesterSettings.maxSectionCount`, add optional pre-expansion bounds to `CourseWeekText.parse`, and use those bounds from recognized HTML week-line parsing.
4. Run the same test and confirm GREEN.
5. Commit the parser slice.

### Repair Track

- Root cause: Grid-area and separate Grid syntax have duplicate parsers; absolute layout ignores CSS units; generic week parsing is used as HTML line classification and expands ranges before import bounds are known.
- Canonical owner: HTML placement and line classification helpers plus `CourseWeekText` for bounded token expansion.
- Minimal repair: route both Grid syntaxes through one range parser, reject unsupported units, score only 12/16 percentage layouts, distinguish marked/ranged week lines from arbitrary numbers, and let the week parser reject bounded endpoints before expansion.

### Retirement Track

- Retire: `_parseGridArea` absolute-only end parsing.
- Retire: pixel values interpreted with percentage arithmetic.
- Retire: arbitrary bare integers acting as HTML week markers.
- Retire: duplicated HTML-side token scanning that diverges from `CourseWeekText` grammar.
- Retain: 12-row inference as the compatibility fallback for ambiguous percentage layouts.

## Task 2: JSON Import Bounds

Files:

- Modify `test/features/import/domain/academic_timetable_json_parser_test.dart`
- Modify `lib/features/import/domain/academic_timetable_json_parser.dart`

Why:

The school JSON parser validates weekdays but accepts sections outside 1-16 and week values outside 1-24, producing persisted schedules that can be clipped or never shown.

Impact/Compatibility:

- Existing school field mappings and valid evening/weekend schedules stay unchanged.
- Invalid items are skipped consistently with other malformed JSON items.
- Valid week lists remain sorted and explicit.

Steps:

1. Add a failing test `skips schedules outside supported section and week bounds` containing one valid item, invalid `0-2`, invalid `15-17`, week `0`, and week `25` items.
2. Run `flutter test test/features/import/domain/academic_timetable_json_parser_test.dart` and confirm invalid items are currently returned.
3. Validate `_SectionRange` against 1-16 and call the canonical bounded `CourseWeekText.parse` API with 1-24 before creating `_JsonSchedule`.
4. Run the JSON parser test and confirm GREEN.
5. Commit the JSON validation slice.

### Repair Track

- Root cause: the parser validates weekday bounds but assumes section/week fields are trustworthy.
- Canonical owner: `_parseItem` and `_parseSectionRange` in the JSON parser.
- Minimal repair: apply canonical timetable bounds before model creation.

### Retirement Track

- Retire: off-grid JSON schedules entering persistence.
- Retain: malformed-item skip behavior and all current field mappings.

## Task 3: Candidate Ranking And Preview Override

Files:

- Modify `test/features/import/domain/academic_timetable_api_probe_test.dart`
- Modify `lib/features/import/domain/academic_timetable_api_probe.dart`
- Create `lib/features/import/presentation/import_preview_dialog.dart`
- Create `test/features/import/presentation/import_preview_dialog_test.dart`
- Modify `lib/features/import/presentation/course_import_page.dart`

Why:

Crowded-slot status currently outranks completeness and disables confirmation. A legitimate full timetable with four overlapping courses can therefore lose to an incomplete candidate or become impossible to import.

Impact/Compatibility:

- Candidate order remains deterministic.
- Schedule count, then course count, represent available completeness signals; suspicious status becomes a final tie-breaker.
- Crowded slots remain visible as warnings.
- Normal previews keep `确认导入`; suspicious previews use enabled `仍然导入` so override intent is explicit.

Steps:

1. Replace the old ranking expectation with failing tests proving a fuller crowded candidate beats a smaller non-crowded result and a non-crowded candidate wins only when counts tie.
2. Add a failing widget test that pumps `ImportPreviewDialog`, verifies the warning, finds an enabled `仍然导入` button, taps it, and observes `true` from the dialog.
3. Run the two target test files and confirm RED.
4. Reorder `_isBetterCandidate`, extract the preview dialog widget, and wire `_showImportPreview` to it.
5. Run both test files and confirm GREEN, then commit the slice.

### Repair Track

- Root cause: an anomaly heuristic owns both candidate precedence and import authorization.
- Canonical owner: pure ranking stays in the probe domain; user authorization stays in the preview widget.
- Minimal repair: counts first, warning as tie-breaker, explicit enabled override.

### Retirement Track

- Retire: suspicious-first candidate precedence.
- Retire: disabled confirmation for crowded slots.
- Retain: crowded-slot warning threshold and diagnostics.

## Task 4: Asynchronous WebView Probe And Isolated Diagnostics

Files:

- Create `lib/features/import/presentation/semester_api_probe_client.dart`
- Create `test/features/import/presentation/semester_api_probe_client_test.dart`
- Modify `lib/features/import/presentation/course_import_page.dart`

Why:

Synchronous XHR blocks the WebView and cannot use a timeout. Shared `_lastSemesterApiError` can also leak one candidate's error into the next candidate's diagnostic.

Impact/Compatibility:

- Requests keep the same URL, POST body, headers, cookies, and candidate order.
- JavaScript uses asynchronous XHR, an 8-second browser timeout, a request ID, and one JavaScript channel.
- Dart applies a bounded timeout and abort cleanup.
- Each request returns its own payload/error result; no shared mutable error is used during candidate iteration.

Steps:

1. Add failing client tests that capture the generated script, verify asynchronous `xhr.open(..., true)`, verify timeout/channel behavior, complete a request through a matching message, ignore an unknown request ID, and return a timeout result when no message arrives.
2. Run `flutter test test/features/import/presentation/semester_api_probe_client_test.dart` and confirm RED because the client does not exist.
3. Implement the callback-injected client, initialize its JavaScript channel in `CourseImportPage`, dispose pending requests, replace synchronous result evaluation, and return `_SemesterApiReadResult(payload, error)` per candidate.
4. Run the client test plus API probe and WebView codec tests; confirm GREEN.
5. Commit the asynchronous probe slice.

### Repair Track

- Root cause: request execution and result return are coupled to synchronous JavaScript evaluation and one page-level error field.
- Canonical owner: the new presentation client owns request lifecycle; the page owns candidate orchestration.
- Minimal repair: JavaScript channel completion with two timeout layers and request-scoped errors.

### Retirement Track

- Retire: synchronous XHR and `_lastSemesterApiError` as per-request transport state.
- Retain: page-level aggregated diagnostic summary after candidate iteration.

## Task 5: Persistence Sequencing And Final Verification

Files:

- Create `lib/features/import/application/import_persistence_sequence.dart`
- Create `lib/features/import/application/import_persistence_provider.dart`
- Create `test/features/import/application/import_persistence_sequence_test.dart`
- Create `test/features/import/application/import_persistence_provider_test.dart`
- Modify `lib/features/import/presentation/course_import_page.dart`
- Modify `lib/core/database/isar_database.dart`
- Modify `lib/features/settings/application/settings_providers.dart`
- Modify `lib/features/timetable/application/timetable_providers.dart`
- Modify `test/core/database/kiro_time_database_test.dart`
- Update `docs/aegis/work/2026-07-18-import-parser-residual-hardening/20-checkpoint.md`
- Create `docs/aegis/work/2026-07-18-import-parser-residual-hardening/90-evidence.md`
- Create `docs/aegis/work/2026-07-18-import-parser-residual-hardening/99-reflection.md`
- Update `docs/aegis/INDEX.md`

Why:

The detected path and semester metadata currently run before core timetable replacement. A later database failure can leave partial state, while an optional preference failure can make a successful course replacement look like a failed import.

Impact/Compatibility:

- Core timetable replacement must succeed before metadata/path persistence starts.
- A core replacement failure propagates and prevents optional writes.
- Metadata/path failures become warnings after successful core replacement.
- Provider invalidation and success messaging happen only after the core replacement succeeds.
- Optional providers update in-memory state only after their database writes succeed.
- Persistence and provider invalidation continue safely if the import page is closed during the operation.
- Core replacement rejects a target semester deleted before its transaction, and imported semester-start updates modify only the still-existing target record.

Steps:

1. Add failing tests proving the sequence is `replace -> metadata -> path`, optional steps do not run when replacement fails, and optional failures are returned as warnings instead of throwing.
2. Run `flutter test test/features/import/application/import_persistence_sequence_test.dart` and confirm RED.
3. Implement the sequence helper and a lifecycle-independent provider composition. Wire `_persistPreparedImport` through that provider, bind core and metadata writes to one captured semester ID, validate target existence in the replacement transaction, update only the target semester-start field, persist optional state before updating memory, set page UI state only while mounted, and include warnings in the success message.
4. Run all task-specific tests, `flutter test test/features/import`, `flutter analyze --no-pub`, `flutter test --no-pub`, and `git diff --check`.
5. Record exact RED/GREEN/full-suite evidence, architecture review, repair/retirement closure, residual risk, and commit the final slice.

### Repair Track

- Root cause: optional settings writes precede the canonical timetable replacement boundary and share its error path.
- Canonical owner: a testable application sequencing policy composed by the page.
- Minimal repair: core first, optional writes second, warnings instead of false core failure.

### Retirement Track

- Retire: path and metadata writes before course replacement.
- Retire: optional preference failure reported as total import failure.
- Retain: Isar transaction inside `KiroTimeDatabase.replaceWithImportedData` as the core replacement boundary.

## Risks And Manual Verification

- Pure percentage positioning cannot identify every possible row count from one card. The implementation deliberately supports common 12/16 layouts and retains 12 on ties.
- Pixel-only static HTML has no computed parent geometry, so rejecting it is safer than guessing; a live school sample would be required for a richer adapter.
- JavaScript-channel behavior requires Android manual verification with an authenticated school session even after coordinator tests pass.
- No Android device or school account is assumed available during automated verification.
