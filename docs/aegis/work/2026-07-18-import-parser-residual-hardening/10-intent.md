# Import Parser Residual Hardening Intent

## TaskIntentDraft

- Outcome: fix every actionable residual import issue identified in the post-hardening review and leave regression coverage for pure logic, UI warning override, request lifecycle, and persistence order.
- Scope: HTML Grid/absolute placement, import section/week bounds, API candidate ranking, preview authorization, WebView request transport, candidate diagnostics, and confirmed persistence sequencing.
- Non-goals: WebDAV, backend APIs, school-specific domains/adapters, schema migrations, release packaging, and unrelated date-dependent timetable tests.
- Risk hints: parser behavior is shared across HTML imports; WebView transport changes require platform-manual evidence; persistence order changes user-visible failure semantics.

## BaselineReadSetHint

- `DEVELOPMENT_PLAN.md`
- `docs/aegis/BASELINE-GOVERNANCE.md`
- `docs/aegis/baseline/2026-06-16-initial-baseline.md`
- `docs/aegis/plans/2026-06-16-phase-2-html-import.md`
- `docs/aegis/plans/2026-06-20-import-probe-preview.md`
- `docs/aegis/plans/2026-07-18-import-parser-hardening.md`
- Import domain parsers/probe and tests
- `course_import_page.dart`
- `KiroTimeDatabase.replaceWithImportedData`

## ImpactStatementDraft

- Affected layers: import domain, import presentation, one import application sequencing helper, tests, and Aegis records.
- Canonical owners remain explicit; no school-specific owner is added.
- Stable invariants: local-only import, preview before replacement, explicit week lists, overlapping-course support, HTML fallback, and unchanged stored schemas.
- Compatibility changes: suspicious imports require explicit override instead of being blocked; unsupported pixel-only placement is rejected; common 16-row percentages gain conservative support.
- Retirement: duplicated Grid-area parsing, pixel-as-percent arithmetic, bare-number week classification, suspicious-first ranking, synchronous XHR, shared per-request error state, and pre-core optional persistence.

## Baseline Check

Decision: aligned. The remaining defects are implementation contradictions inside existing owners; no baseline or architecture authority change is required.
