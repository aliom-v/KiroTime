# Import Parser Hardening Intent

## TaskIntentDraft

- Outcome: repair four confirmed import defects and leave regression coverage for each pure logic branch.
- Scope: HTML table rows, CSS Grid span parsing, HTML section bounds, API candidate ranking, and confirmed path persistence.
- Non-goals: WebDAV, backend services, JSON schema changes, database migrations, school-specific adapters, release packaging.
- Risk hints: parser changes are shared across all HTML imports; probe changes affect which remote response reaches preview and persistence.

## BaselineReadSetHint

- `docs/aegis/BASELINE-GOVERNANCE.md`
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`
- `docs/aegis/plans/2026-06-16-phase-2-html-import.md`
- `docs/aegis/plans/2026-06-20-import-probe-preview.md`
- `lib/features/import/domain/academic_timetable_html_parser.dart`
- `lib/features/import/domain/academic_timetable_api_probe.dart`
- `lib/features/import/presentation/course_import_page.dart`
- Related import domain tests

## ImpactStatementDraft

- Affected layers: import domain parser, import domain probe rules, import presentation orchestration, documentation/tests.
- Canonical owners remain unchanged.
- Stable invariants: explicit week lists, overlapping-course support, local-only parsing, preview before timetable replacement, optional HTML fallback.
- Compatibility change: HTML placement maximum aligns with the existing 16-section semester maximum.
- Retirement: first-section-only table traversal, end-span-as-absolute parsing, first-non-empty API selection, and pre-confirmation path saving.

## Baseline Check

Decision: minor drift, self-correctable. The architecture and ownership map remain valid; the defects are local logic contradictions within the existing owners.
