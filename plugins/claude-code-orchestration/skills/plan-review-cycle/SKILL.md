---
name: plan-review-cycle
description: Use after `implementation-planner` produces a draft plan, and again after any plan revision. Runs a loop of independent reviewer subagents against the plan until they converge on "no further issues" or hit the round limit and escalate to the human. Each round writes a timestamped review file to the plan's folder.
---

# Implementation plan review cycle

Drafting a plan once is never enough. Plans accumulate stale or contradictory content over multiple revisions. This skill formalizes the convergence loop.

## Inputs
- Plan file path: `docs/ignored/implementation/<feature>/Plan.md`
- Feature/task name
- Original requirements (from `requirements-product-analyst`)
- Codebase context snapshots from `docs/ignored/context/`

## The cycle (max 5 rounds)

### Round 1 — Multi-angle review (parallel)
Spawn three independent reviewer subagents:

- **Requirements-alignment reviewer** — Does every requirement from the original have a corresponding stage in the plan? Are non-goals respected? Are acceptance criteria testable?
- **Architecture-alignment reviewer** — Use the `architecture-enforcer` agent. Does the plan respect the existing architecture? Where it drifts, is the drift declared and approved?
- **Implementation-feasibility reviewer** — Are the stages actually doable? Are dependencies between stages correct? Are edge cases enumerated? Is the validation matrix realistic?

Each writes to `docs/ignored/implementation/<feature>/Review-<round>-<reviewer>-<timestamp>.md`.

### Round 2 — Consolidation
A consolidator subagent reads the three review files and produces:
- A merged issue list (dedup, prioritize)
- For each issue: severity (blocker/major/minor) and recommended action

If `0 blockers AND 0 majors` → plan approved, exit cycle.
If issues exist → proceed to Round 3.

### Round 3 — Plan revision
`implementation-planner` revises the plan to address every blocker + major. The revision must:
- Be a new file `Plan-v<n>.md`, not an overwrite of the previous version.
- Reference the consolidated issue list and say which issues each change addresses.
- Run `documentation-reviewer` over the *previous* plan to strip stale/contradicted content from it (or supersede it explicitly).

### Round 4 — Re-review (parallel, same three reviewers)
Run round 1 again over the new plan.

### Round 5 — Final consolidation
Same as round 2. If still issues remain → escalate to human, do not implement.

## Convergence criteria
- 0 blockers AND 0 majors → APPROVED. Implementation can start.
- Any blocker remaining after round 5 → ESCALATE.
- Any major remaining after round 5 → ESCALATE.
- Only minors remaining → APPROVED_WITH_FOLLOW_UPS (note them, but implementation may start).

## Output
A single file `docs/ignored/implementation/<feature>/Plan-Final.md` with header:

```
# Plan-Final
Approved-at: <timestamp>
Reviewer convergence rounds: <n>
Remaining minors: <list>
Supersedes: Plan-v1.md, Plan-v2.md, ...
```

The orchestrator must reject implementation against a non-`Plan-Final.md` artifact unless the human explicitly approves.

## Documentation hygiene rule
Every round of revision triggers `documentation-reviewer` on the plan folder. Old plan versions are kept (audit trail) but flagged as superseded inside their headers. No stale content lingers in `Plan-Final.md`.
