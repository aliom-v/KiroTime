# Import Parser Residual Hardening Reflection

## Outcome

The remaining import defects were repaired without adding WebDAV, backend crawling, school-specific adapters, schema changes, or direct Dart HTTP access.

## Deeper Cause

- HTML placement mixed Grid span semantics, absolute lines, percentages, and pixels without preserving each syntax boundary.
- Generic week parsing was also acting as HTML line classification and accepted values outside the application's import limits.
- JSON fields were treated as trustworthy after only partial structural parsing.
- Candidate anomaly warnings owned both ranking and import authorization instead of remaining advisory.
- WebView transport depended on blocking synchronous XHR and one shared mutable error field.
- Optional preference/metadata writes ran before the database replacement that actually defines import success.

## Architecture Review

- HTML and JSON validation remain in their domain parsers.
- Candidate comparison remains pure domain logic.
- Preview authorization remains in a dedicated widget.
- `SemesterApiProbeClient` owns request IDs, JavaScript message decoding, timeout, abort, cancellation, and disposal without importing WebView types.
- `CourseImportPage` owns platform composition and page-generation validity.
- `ImportPersistenceSequence` owns core-versus-optional side-effect ordering without depending on Riverpod or Isar.
- `persistImportedTimetableProvider` owns Isar/provider composition and invalidation independently of the page lifecycle.
- No model, Isar schema, or local JSON contract changed.

## Repair And Retirement

- Repaired Grid-area spans, 12/16 percentage inference, section/week bounds, candidate precedence, suspicious-result override, asynchronous request lifecycle, stale-page rejection, persistence order, optional commit ordering, page-close persistence safety, target-semester binding, and transaction-level existence checks.
- Retired pixel-as-percentage arithmetic, bare-number week classification, partial JSON section matches, suspicious-first ranking, disabled suspicious import, synchronous XHR, shared per-request error state, stale cross-page fallback, optional writes before core replacement, memory-before-database optional state, page-owned invalidation, stale whole-list metadata replacement, and orphan writes to deleted semesters.
- Retained 12-row inference on ambiguous percentages as the compatibility boundary.
- Retained valid overlapping courses; crowded-slot detection remains a warning.

## Review Closure

- The asynchronous probe review initially found two Important issues: non-2xx payload compatibility and cross-page request mixing.
- Follow-up review found stale HTML fallback as one remaining Important issue.
- Error payload retention, page-generation checks, request cancellation, interaction blocking, and channel-ready loading closed all findings.
- Final asynchronous probe review reported no Critical or Important issues.
- Persistence review found memory-before-database optional writes and disposed-page invalidation as Important issues.
- A lifecycle-independent provider, persistence-first optional state, captured-semester metadata binding, field-level metadata transactions, target-existence checks, and provider/database integration tests closed those findings before integration.

## Residual Risk

- No page-level platform test simulates WebView channel registration failure or automatic navigation during HTML extraction; pure client tests and page-generation guards cover the underlying state transitions.
- No authenticated Android school session was available for cookie/channel verification.
- Candidate completeness remains generic and count-based because the project intentionally has no school-specific expected-course contract.
- The previously date-dependent timetable widget assertion now derives its expectation from the same semester calculation as production; the full suite is green.

## Confidence

Grade B+: the parser and coordinator contracts have focused RED/GREEN coverage, the full import suite is green, static analysis is clean, and review findings were closed. Confidence remains bounded by the lack of a live Android school session.
