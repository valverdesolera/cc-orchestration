---
name: assumption-validation-tests
description: Use BEFORE any non-trivial fix or implementation, AND AFTER it. Captures a failing test that reproduces the bug or demonstrates the missing capability, then validates the fix by comparing pre/post test results. Complements the official `superpowers` plugin's TDD red-green-refactor enforcement; use both together.
---

# Assumption-validation tests (pre/post comparison)

The rule, in plain words: **unless you are strictly sure of an issue, write a test first to prove the assumption is correct. Then implement. Then re-run the test to prove the fix actually solves it.**

This is broader than classic TDD because it applies to:
- Bug fixes (the test reproduces the bug, then passes after the fix)
- New features (the test specifies the behavior, then passes after the implementation)
- Refactors (existing tests must keep passing; new ones cover the new edge cases the refactor exposes)
- "Performance fixes" where the assumption is about latency/throughput (the test is a benchmark threshold)

## When to use vs. delegating to superpowers

| Situation | Use this skill | Use superpowers' TDD framework |
| --- | --- | --- |
| Project already uses red-green-refactor TDD | Light — just record the pre/post test diff | YES, drive the workflow |
| Project doesn't have TDD culture | Drive the workflow yourself | Optional — superpowers can still enforce locally |
| Pure bug fix (no new behavior) | YES — write a reproducer test first | YES |
| Performance bug | YES — write a benchmark with a regression threshold | superpowers can scaffold the test |

Always invoke `superpowers` when it's installed and applicable — its red-green-refactor enforcement is stricter than this skill.

## Procedure

Step 1 — Capture the assumption explicitly:
```
## Assumption
"<exact statement of what we believe is happening or what should happen>"
```

Step 2 — Write a test that proves the assumption (FAIL first):
- For a bug: the test reproduces the bug and currently fails.
- For a feature: the test asserts the feature's behavior and currently fails (because the feature doesn't exist).
- For perf: the test measures the current value and asserts the target threshold; it currently fails.

Save the test file path and the *exact failing output* into `docs/ignored/implementation/<feature>/PreTest-<timestamp>.md`:
```
## Pre-Implementation Test
File: <test-file-path>
Test name: <test-name>
Status: FAIL (expected)
Output:
<verbatim failing output>
```

Step 3 — Implement the fix or feature.

Step 4 — Re-run the test. It MUST pass.
Save the result to `docs/ignored/implementation/<feature>/PostTest-<timestamp>.md`:
```
## Post-Implementation Test
File: <test-file-path>
Test name: <test-name>
Status: PASS
Output:
<verbatim passing output>
```

Step 5 — Run the full test suite (or the relevant subset per `validation-matrix`) to check no regressions.

Step 6 — Write the diff summary:
```
## Pre/Post Comparison
Pre-status: FAIL
Post-status: PASS
Regressions introduced: NONE | <list>
Verdict: ASSUMPTION_VALIDATED | ASSUMPTION_DISPROVEN | INCONCLUSIVE
```

If `Verdict: ASSUMPTION_DISPROVEN` — the test still fails — the implementation did not solve the problem. Loop back.

If `Verdict: INCONCLUSIVE` — flaky test, environmental factors. Escalate.

## Hard rules

- The pre-implementation test MUST fail. If it passes, you don't actually understand the problem.
- The test must be specific to the assumption. Don't ship a generic smoke test as "the assumption test."
- Keep both files (`PreTest-*.md`, `PostTest-*.md`) — they're the proof the fix works. Code reviewers reference them.
- Never claim "fixed" without a `PostTest` showing PASS.
- If `superpowers` is installed, invoke its TDD command to wrap this procedure with its stricter enforcement.
