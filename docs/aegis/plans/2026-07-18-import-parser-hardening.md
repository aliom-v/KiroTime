# Import Parser Hardening Plan

## Goal

Repair four confirmed import defects without changing KiroTime's local-first architecture:

1. Parse standard timetable tables whose header and body are separated into `thead` and `tbody`.
2. Interpret CSS Grid `grid-row-end: span N` and `grid-column-end: span N` as spans rather than absolute grid lines.
3. Preserve HTML courses in sections 13-16, matching the application's supported semester range.
4. Evaluate all successful API probe candidates, select the strongest result, and save the detected path only after the user confirms the import.

## Architecture

- `academic_timetable_html_parser.dart` remains the sole owner of HTML structure and placement parsing.
- `academic_timetable_api_probe.dart` owns pure candidate quality comparison in addition to path generation and suspicious-result summaries.
- `course_import_page.dart` remains the WebView/API orchestration owner. It collects candidate results, delegates quality selection to the domain helper, shows the preview, and persists settings/data only after confirmation.
- Existing JSON field mappings, Isar persistence, preview UI, diagnostics, and HTML fallback remain in place.

## Considered Approaches

### A. Rewrite the HTML parser around school-specific adapters

This could be more precise for known schools, but it would discard broad compatibility and introduce school-specific ownership. Rejected for this repair.

### B. Apply targeted parser fixes and pure candidate ranking

This keeps existing owners, adds narrow regression coverage, and retires only the defective branches. Chosen.

### C. Keep the parser unchanged and rely on preview warnings

This avoids parser changes but leaves empty imports, shortened section spans, and late-section clamping unresolved. Rejected because preview is not a substitute for correct parsing.

## Tech Stack

- Flutter / Dart
- `html` DOM parser
- Riverpod
- WebView JavaScript
- Flutter test framework

## Baseline/Authority Refs

- `DEVELOPMENT_PLAN.md`: imports remain local and no backend is introduced.
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`: course and schedule contracts remain stable.
- `docs/aegis/plans/2026-06-16-phase-2-html-import.md`: HTML parsing stays pure and persistence remains outside the parser.
- `docs/aegis/plans/2026-06-20-import-probe-preview.md`: preview confirmation and HTML fallback remain compatibility boundaries.
- `lib/features/timetable/domain/semester_settings.dart`: supported section count is 8-16.

## Compatibility Boundary

- No WebDAV, backend, cloud account, analytics, or school-specific domain is added.
- `CourseMeta`, `CourseSchedule`, JSON import/export, and Isar schemas do not change.
- Overlapping courses remain valid; suspicious-result detection is a ranking and preview signal, not a parser rejection rule.
- Candidate ties preserve configured/page discovery order.
- A non-suspicious candidate outranks a suspicious candidate; otherwise the candidate with more schedules, then more course metadata, wins.
- HTML fallback remains available when all API candidates fail.
- The detected API path is not saved before preview confirmation.

## Verification

- `flutter test test/features/import/domain/academic_timetable_html_parser_test.dart`
- `flutter test test/features/import/domain/academic_timetable_api_probe_test.dart`
- `flutter test test/features/import/domain/academic_timetable_json_parser_test.dart test/features/import/domain/webview_html_codec_test.dart`
- `flutter test`
- `flutter analyze`
- `git diff --check`

## Task 1: Standard Table Sections

Files:

- Modify `test/features/import/domain/academic_timetable_html_parser_test.dart`
- Modify `lib/features/import/domain/academic_timetable_html_parser.dart`

Why:

`_directTableRows` currently chooses only the first `thead` or `tbody`, so semantic tables can expose a header but hide all course rows.

Impact/Compatibility:

- Direct `tr` children continue to parse.
- Rows inside direct `thead`, `tbody`, and `tfoot` sections are collected in document order.
- Rows from nested lesson tables remain excluded.

Steps:

1. Add a failing test with weekday headers in `thead` and course cells in `tbody`; expect one correctly placed schedule.
2. Run the HTML parser test and confirm the new case returns zero schedules.
3. Replace the single-parent lookup with direct-child row collection across table sections.
4. Run the HTML parser test and confirm all cases pass.
5. Do not commit separately because the shared worktree already contains user-owned import changes.

### Repair Track

- Root cause: row ownership stops at the first table section.
- Canonical owner: `_directTableRows` in the HTML parser.
- Minimal repair: flatten direct table sections only.

### Retirement Track

- Retire: first-section-only row lookup.
- Retain: nested-table isolation through direct-child traversal.

## Task 2: CSS Grid Span And Section Limit

Files:

- Modify `test/features/import/domain/academic_timetable_html_parser_test.dart`
- Modify `lib/features/import/domain/academic_timetable_html_parser.dart`

Why:

Separate `grid-row-start`/`grid-row-end` declarations treat `span N` as absolute line `N`. HTML placement also clamps sections to 12 although semester settings support 16.

Impact/Compatibility:

- Existing `grid-row: start / span N` behavior remains.
- Separate start/end declarations gain equivalent behavior.
- Sections 1-12 remain unchanged; explicit attributes, table rows, and CSS Grid sections 13-16 stop collapsing to 12.
- Legacy absolute-position percentage cards retain their existing 12-row inference because their percentages do not expose a reliable row-count contract.

Steps:

1. Add one failing test for separate Grid start/end span properties and one for explicit sections 13-16.
2. Run the HTML parser test and confirm the span ends one section early and late sections clamp to 12.
3. Parse an explicit end span before parsing an absolute end line, use `SemesterSettings.maxSectionCount` for explicit/Grid/table bounds, and retain a separate 12-row percentage-position heuristic.
4. Run the HTML parser test and confirm all cases pass.
5. Do not commit separately because the shared worktree already contains user-owned import changes.

### Repair Track

- Root cause: `_parseGridLineRange` sends `span N` through the absolute-line parser; one constant incorrectly owns both application bounds and legacy percentage-layout inference.
- Canonical owner: CSS placement helpers and placement bounds in the HTML parser.
- Minimal repair: reorder end parsing and reference the canonical semester maximum.

### Retirement Track

- Retire: implicit interpretation of end-property spans as absolute lines.
- Retire: duplicated 12-section cap for explicit/Grid/table placement.
- Retain: application-wide 16-section maximum and the separate legacy 12-row percentage-position heuristic.

## Task 3: API Candidate Quality Selection

Files:

- Modify `test/features/import/domain/academic_timetable_api_probe_test.dart`
- Modify `lib/features/import/domain/academic_timetable_api_probe.dart`
- Modify `lib/features/import/presentation/course_import_page.dart`

Why:

The current probe returns the first non-empty parsed response. A partial or malformed endpoint can therefore hide a later complete endpoint.

Impact/Compatibility:

- Candidate request order is unchanged.
- All parseable non-empty candidates are evaluated.
- Non-suspicious results rank above suspicious results; schedule count and course count break remaining differences.
- Equal candidates preserve original order.

Steps:

1. Add failing domain tests proving a later fuller candidate wins, a non-suspicious candidate beats a suspicious candidate, and ties preserve order.
2. Run the API probe test and confirm the selection API is missing.
3. Add a `TimetableProbeCandidate` value and `selectBestCandidate` pure rule.
4. Change `_probeCandidates` to collect successes, select once after all requests, and retain diagnostics for failed paths.
5. Run API, JSON, and WebView codec tests and confirm they pass.

### Repair Track

- Root cause: response validity is reduced to `schedules.isNotEmpty`, followed by immediate return.
- Canonical owner: quality comparison in `academic_timetable_api_probe.dart`; request execution stays in the page.
- Minimal repair: collect, compare, then return once.

### Retirement Track

- Retire: first-non-empty early return.
- Retain: deterministic candidate order as final tie-breaker.

## Task 4: Confirmed Path Persistence

Files:

- Modify `lib/features/import/presentation/course_import_page.dart`

Why:

The detected endpoint is currently stored before the preview decision, so canceling or being blocked by a suspicious result still changes future import behavior.

Impact/Compatibility:

- Preview cancellation performs no settings or timetable write.
- Confirmed imports continue to remember the successful API path.
- HTML imports continue without an API path update.

Steps:

1. Remove path-saving calls from `_prepareImport` and `_probeSemesterApi` before preview.
2. Save `prepared.path` inside the confirmed persistence path.
3. Verify both import entry points call persistence only after confirmation.
4. Run static analysis and related tests.
5. Do not commit separately because the shared worktree already contains user-owned import changes.

### Repair Track

- Root cause: preference persistence is coupled to probe success rather than import confirmation.
- Canonical owner: `_persistPreparedImport`, the existing confirmed persistence boundary.
- Minimal repair: move the existing save call into that boundary.

### Retirement Track

- Retire: pre-preview endpoint persistence from both entry points.
- Retain: endpoint persistence for confirmed API imports.

## Risks

- Candidate completeness is inferred from parsed output, not an external school-specific expected count.
- Absolute-position pages that encode a 16-row timetable only through percentages remain ambiguous; explicit section text, attributes, or Grid lines are required for reliable sections 13-16.
- Real WebView request behavior still requires Android manual verification when a device and school session are available.
- Existing user-owned uncommitted changes must be preserved; this plan does not create commits or rewrite unrelated files.
