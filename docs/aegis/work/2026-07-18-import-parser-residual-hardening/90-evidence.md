# Import Parser Residual Hardening Evidence

## RED/GREEN Evidence

### HTML Placement And Week Bounds

- RED covered Grid-area spans, 12/16 percentage inference, pixel-only placement, invalid text sections, bare numeric week lines, and oversized week ranges.
- GREEN: related course-week and HTML parser suite passed 46 tests.

### JSON Bounds

- RED reproduced section ranges outside 1-16, partial range matches, and weeks outside 1-24.
- GREEN: JSON parser target passed 5 tests.

### Candidate Ranking And Preview

- RED proved fuller crowded candidates lost and suspicious previews could not be confirmed.
- GREEN: probe-domain and preview-widget targets passed 13 tests.

### Asynchronous WebView Probe

- Initial RED failed to compile because `semester_api_probe_client.dart` did not exist.
- Review-driven RED added request cancellation and error-response payload retention before those contracts existed.
- GREEN: 8 client tests passed, covering asynchronous XHR, request IDs, unknown IDs, timeout/abort cleanup, error payloads, reusable cancellation, concurrent response ordering, and disposal.
- Page integration now waits for channel readiness, binds probes to a page generation, cancels pending requests on navigation, blocks stale HTML fallback, and disables navigation controls during import.
- Independent final review found no remaining Critical or Important issues.

### Persistence Sequencing

- Initial RED failed to compile because `import_persistence_sequence.dart` did not exist.
- Review-driven RED failed to compile because the lifecycle-independent `import_persistence_provider.dart` did not exist.
- GREEN: 8 sequence/provider tests passed for `replace -> metadata -> path -> refresh`, core-failure propagation, optional-failure warnings with continued execution, refresh after optional warnings, captured-semester binding, and non-current metadata updates that preserve the user's selected semester.
- `saveImportPreferencesProvider` and the import-specific `updateImportedSemesterStartProvider` update memory only after their database writes succeed.
- `CourseImportPage` obtains the persistence function before awaiting and performs no `ref` access after the operation; global invalidation is provider-owned.
- Database GREEN: 16 tests passed, including atomic rejection of replacement into a missing semester and field-only semester-start updates that preserve display name, section count, and total weeks.
- Imported metadata merges into the latest in-memory semester list only if the target still exists.

## Final Regression

```bash
flutter test test/features/import
```

- Exit code: 0
- Result: 79 tests passed.

```bash
flutter analyze --no-pub
```

- Exit code: 0
- Result: `No issues found!`

```bash
git diff --check
```

- Exit code: 0

## Full Suite

```bash
flutter test --no-pub
```

- Exit code: 0
- Result: 163 tests passed.
- The pre-existing `第16周` assertion was stabilized to derive the expected week from the edited semester and `DateTime.now()`, matching production behavior without changing runtime logic.

## Manual Verification Not Performed

- No authenticated school session or Android device was available.
- JavaScript-channel requests, cookies, and navigation cancellation should still be exercised on Android against a real school session before release.
