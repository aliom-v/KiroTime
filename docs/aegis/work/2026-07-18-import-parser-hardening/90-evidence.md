# Import Parser Hardening Evidence

## EvidenceBundleDraft

### HTML Parser RED

Command:

```bash
flutter test test/features/import/domain/academic_timetable_html_parser_test.dart
```

Observed before implementation:

- `thead`/`tbody` case: expected 1 schedule, got 0.
- separate Grid end span case: expected end section 4, got 3.
- sections 13-16 case: expected start section 13, got 12.

### HTML Parser GREEN

Same target command after implementation:

- Exit code: 0
- Result: 28 tests passed.
- Existing percentage-position and outer-container regression cases remained green after separating the 16-section bound from the 12-row percentage heuristic.

### API Candidate RED

Command:

```bash
flutter test test/features/import/domain/academic_timetable_api_probe_test.dart
```

Observed before implementation:

- `TimetableProbeCandidate` and `selectBestCandidate` did not exist, so the new quality-selection tests failed to compile.

### API Candidate GREEN

Same target command after implementation:

- Exit code: 0
- Result: 10 tests passed.
- Covered later fuller candidate, non-suspicious preference, course-count tie-break, and stable discovery-order tie.

### Related Import Regression

Command covered HTML parser, API probe, JSON parser, and WebView codec tests:

- Exit code: 0
- Result: 46 tests passed.

### Static Analysis

Command:

```bash
flutter analyze --no-pub
```

- Exit code: 0
- Result: `No issues found!`

### Full Test Suite

Command:

```bash
flutter test --no-pub
```

- Result: 121 tests passed, 1 unrelated widget test failed.
- Failure: `semester settings update visible term and current week` expected `第16周`.
- Isolation: the same test fails alone; no timetable UI/provider files changed in this task.
- Root cause: after saving, production recomputes the week from `DateTime.now()`. With start date `2026-03-02`, total weeks 18, and current date `2026-07-18`, the result clamps to week 18 rather than the test's date-dependent week 16 expectation.
- Decision: record as pre-existing test debt; do not mix an unrelated timetable test repair into import parser hardening.

### Worktree Hygiene

- Temporary probe tests and Flutter logs from diagnosis were removed.
- `git diff --check` passed.
- Existing user-owned uncommitted import changes were preserved.

## Manual Verification Not Performed

- No authenticated school WebView session or Android device was available in this task.
- Candidate request behavior and preview confirmation should still be exercised on Android with a real school session before release.
