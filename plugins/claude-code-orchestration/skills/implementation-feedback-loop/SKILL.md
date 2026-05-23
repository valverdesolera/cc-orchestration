---
name: implementation-feedback-loop
description: Use to enforce the mandatory coding, context refresh, code review, testing, documentation review, and retry loop for every implementation unit.
---

# Implementation Feedback Loop

Use this loop for every approved implementation stage or cohesive unit. Do not collapse multiple units into one loop.

## The loop iterates until reviews + validation pass

The loop CAN iterate many times — that's the point. What's bounded is the number of different review systems per iteration (two: custom code-reviewer + /code-review), not the number of iterations.

## Per iteration

1. Confirm the current stage is approved and scoped (first iteration only).
2. Coding agent implements (first iteration) or applies the minimal fix from the previous iteration's feedback.
3. Refresh codebase contextualization for touched modules under `docs/ignored/context/**`.
4. Architecture-enforcer verifies alignment (brownfield) or matches the declared design (greenfield).
5. Code reviewer (custom) reviews every changed, added, and deleted file against the approved stage, edge cases, codebase patterns, comments policy, architecture boundaries, AND placeholder/stub detection.
6. /code-review from `code-review@claude-plugins-official` runs the diff-level bug pass (line-by-line bugs, removed-behavior audit, cross-file tracer).
7. If EITHER step 5 OR step 6 reports findings: collect them, hand back to coding agent, start a new iteration at step 2.
8. If BOTH pass: continue to validation.
9. Test agent runs targeted tests first, then broader validation per validation-matrix. For bug fixes and feature work, `assumption-validation-tests` produces PreTest (FAIL) and PostTest (PASS) artifacts.
10. If validation fails: start a new iteration at step 2 with the test-failure feedback. After the fix, re-run steps 2-6 (review again), then step 9.
11. If validation passes: documentation-reviewer updates `docs/ignored/**` and removes stale/conflicting content.
12. Comment-policy-checker scans the diff + commit message. BLOCKS the unit if violations found.

## Iteration limits + escalation

- **Max 5 review-fix iterations**: if reviews are still failing after 5 iterations, ESCALATE to the human. Do not loop forever. Likely root causes: misunderstood requirement, wrong architecture choice, scope creep.
- **Max 3 validation-fix iterations**: if validation still fails after 3 iterations (with reviews passing in each), ESCALATE. Likely: the test is wrong, or the architecture can't satisfy the test.
- Each iteration must record its findings + the fix applied in the workbook's activity log (so the human can audit how convergence happened — or didn't).

## Exit criteria before next stage

- Latest iteration's policy review (step 5) has no blocking findings.
- Latest iteration's diff bug pass (step 6) has no CONFIRMED findings (PLAUSIBLE findings may proceed with explicit acknowledgment).
- Required validation passed or the human explicitly accepted the remaining risk.
- Documentation changes are current and internally consistent.
- Context snapshots for touched modules are refreshed.
- Comment-policy-checker returned CLEAN.
- Remaining risks and unverified items are reported.

## What "ONE pipeline" does NOT mean

"ONE policy reviewer + ONE bug-finder pass per iteration" does NOT mean the loop runs only once. It means each iteration uses 2 reviewers (not 5). The loop itself runs as many iterations as needed, up to the limits above.
