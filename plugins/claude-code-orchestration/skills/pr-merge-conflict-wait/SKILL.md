---
name: pr-merge-conflict-wait
description: Use immediately after `pr-creator` opens a PR. Waits for GitHub to compute mergeability, then surfaces any merge conflicts (or any failing required checks) to the human before the PR is considered "submitted." Solves the problem of PRs sitting with unnoticed conflicts.
---

# PR merge-conflict wait

GitHub computes `mergeable` asynchronously. A PR opened via `gh pr create` may return success while the merge state is still `UNKNOWN`. If conflicts exist, the human typically doesn't notice until much later.

This skill makes the orchestrator wait + report.

## Procedure

After `pr-creator` returns a PR URL:

1. Use the `github` plugin (installed from `claude-plugins-official`) to query:
   ```
   gh pr view <number> --json mergeable,mergeStateStatus,statusCheckRollup,reviewDecision
   ```
2. Initial `mergeable` will often be `UNKNOWN` for several seconds. Poll every 5 seconds, up to 60 seconds total. If still `UNKNOWN`, report that GitHub hasn't computed it yet and recommend the human check.
3. Once `mergeable` resolves:
   - `MERGEABLE` → continue to step 4.
   - `CONFLICTING` → STOP. Report the conflicting files to the human. Do not move on.
4. Check `mergeStateStatus`:
   - `CLEAN` → all good.
   - `BLOCKED` → required reviews/checks not yet satisfied. Report which.
   - `BEHIND` → branch is behind base. Recommend rebasing.
   - `UNSTABLE` → some non-required checks failing. Report which.
5. Check `statusCheckRollup` for any failing required checks. Report them.
6. Report `reviewDecision` (REVIEW_REQUIRED, APPROVED, CHANGES_REQUESTED).

## Output

```
## PR <number> Mergeability Report
URL: <url>
Branch: <head> -> <base>

Mergeable: MERGEABLE | CONFLICTING | UNKNOWN
Merge state: CLEAN | BLOCKED | BEHIND | UNSTABLE | ...
Review decision: REVIEW_REQUIRED | APPROVED | CHANGES_REQUESTED

## Conflicts (if any)
- file/path:line  (conflict markers expected on rebase/merge)

## Failing Required Checks (if any)
- check name — URL — short summary

## Recommended Action
- (one of) Ready for review / Resolve conflicts / Rebase onto base / Address failing checks / Wait for required reviews
```

## Hard rules
- Never claim "PR is ready" without `mergeable: MERGEABLE` AND no failing required checks.
- If the GitHub API rate limits, retry with backoff, then escalate to the human.
- Do not attempt to resolve conflicts automatically — that's `merge-conflict-resolver`'s job, and only with explicit human approval.
- Do not approve the PR — that's a human decision.

## Integration

This skill is called from the `pr-creator` workflow as the final step. If conflicts are reported, the orchestrator hands off to `merge-conflict-resolver` (with human approval) or escalates.
