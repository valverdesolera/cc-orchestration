---
name: parallelization-decision
description: Use BEFORE the orchestrator dispatches any multi-agent or multi-stage work. Forces an explicit human decision on which stages can be parallelized and which must serialize. Default is SERIALIZE — parallelization is opt-in per stage, never assumed.
---

# Parallelization decision

The orchestrator must never silently parallelize. Parallelization can hide bugs (race conditions in the workflow), produce conflicting code changes in overlapping files, or burn tokens on work that depends on another stage's output.

## When to invoke
- Right after `implementation-planner` produces stages.
- Right after `parallel-research-coordinator` proposes areas.
- Right before any agent fans out work to multiple subagents.

## Procedure

Step 1 — List the stages/tasks:
```
Stage 1: <description>
Stage 2: <description>
...
```

Step 2 — For each pair (i, j), declare dependency:
```
| From | To | Dependency Type |
| --- | --- | --- |
| 1 | 2 | data-only        ← stage 2 needs stage 1's output |
| 1 | 3 | none             ← independent |
| 2 | 3 | files-overlap    ← stage 2 and 3 may modify same files |
```

Dependency types:
- `none` — fully independent, safe to parallelize
- `data-only` — stage B needs stage A's output but doesn't touch the same files; serialize
- `files-overlap` — stages touch the same files; must serialize
- `unknown` — ASK THE HUMAN

Step 3 — Build the parallelization plan:
```
Parallel group 1: stages [A, B, C]   ← all pairwise `none`
Then serial: stage D                  ← depends on group 1
Parallel group 2: stages [E, F]
Then serial: stage G
```

Step 4 — Ask the human:
> "Proposed parallelization plan: [show plan]. Are these groupings correct? Are any `unknown` dependencies actually `data-only` or `files-overlap`?"

DO NOT proceed until the human approves.

Step 5 — Record the decision in `docs/ignored/implementation/<feature>/Parallelization-<timestamp>.md`.

## Defaults
- Default for any stage pair: `unknown` → serialize until human says otherwise.
- Default for any new agent fan-out: ask before fan-out, even if the stages were previously approved as parallel — file-modification conflicts can emerge.

## Hard rules
- No silent parallelization, ever.
- If a parallel group's agents return conflicting file edits, abort all unmerged work, report the conflict, and ask the human how to proceed.
- Document the actual parallel vs. serial execution in the workbook activity log.
