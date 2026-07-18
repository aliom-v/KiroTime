# Import Parser Hardening Reflection

## Goal

Implement the four confirmed import optimizations described in `docs/aegis/plans/2026-07-18-import-parser-hardening.md` while preserving local-only import behavior and existing data contracts.

## DeeperCause

No unresolved deeper cause remains inside the scoped logic:

- Standard table failure came from assigning all row ownership to the first table section instead of collecting direct rows from each section.
- Separate CSS Grid end spans were parsed by the absolute-line parser before span semantics were considered.
- The number 12 owned two different contracts: application placement bounds and a legacy percentage-layout heuristic. Splitting those responsibilities preserved old pages while enabling sections through 16 where the HTML exposes explicit placement.
- API probing treated non-empty as complete and returned immediately; candidate quality now has one pure owner and the loop selects only after evaluating all successes.
- API path persistence was tied to probe success rather than confirmed persistence; it now exists only inside the confirmed persistence path.

## Evidence

- HTML parser: 28 tests passed after three RED reproductions.
- API probe: 10 tests passed after RED for the missing selection contract.
- Related import regression: 46 tests passed in the final run.
- Static analysis: no issues found in the final run.
- Diff hygiene: `git diff --check` passed.
- Full suite: 121 passed; one isolated pre-existing date-dependent widget assertion failed and was reproduced alone.

## Architecture Review

- Ownership integrity: HTML structure remains in the HTML parser; candidate quality remains in the probe domain; WebView requests and persistence remain in presentation orchestration.
- Module boundaries: no database or WebView dependency entered the pure parser/probe rules.
- Contract changes: no Isar, JSON, or course model contract changed.
- Cascade proliferation: one candidate value type was added to remove ranking logic from the page; no fallback chain was added.
- Dependency direction: the parser references the canonical semester section maximum; UI depends on pure domain selection.
- Retirement completeness: all four defective paths identified in the plan are no longer active.
- Entropy flow: candidate orchestration grew because every success is evaluated, while selection authority became deterministic and testable.

## Repair Track

- Repaired objects: table row traversal, Grid end-span parsing, section bounds, API candidate selection, and API path save timing.
- Impact: semantic tables import, Grid spans retain their full range, explicit sections 13-16 survive, fuller/safer API results can outrank early partial results, and canceled previews no longer change the stored path.
- Verification: target RED/GREEN tests, related regression tests, static analysis, and diff checks.

## Retirement Track

- Retired: first-section-only table lookup.
- Retired: end-property spans interpreted as absolute lines.
- Retired: 12 as the explicit/Grid/table maximum.
- Retired: first-non-empty API early return.
- Retired: path saving before preview confirmation.
- Retained boundary: 12-row inference for legacy percentage-position pages, because those percentages do not reveal a reliable 16-row contract.

## Review Note

Two advisory subagent review attempts did not return before timeout and were shut down without findings. Completion evidence therefore relies on direct line-level self-review plus automated verification; no independent reviewer approval is claimed.

## Residual Risk

- Candidate completeness is inferred from parsed counts and suspicious-slot shape; there is no school-specific expected course count.
- Real Android WebView behavior was not manually tested with an authenticated school session.
- A separate widget test has a date-dependent `第16周` expectation and currently fails on 2026-07-18; it is outside this import task.

## Confidence

Grade B: direct reproductions and focused regression coverage support the four repairs; confidence is bounded by the lack of live school WebView verification and independent review output.
