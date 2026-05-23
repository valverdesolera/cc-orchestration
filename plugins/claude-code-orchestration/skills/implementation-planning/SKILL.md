---
name: implementation-planning
description: Use when turning a user request into implementation stages, acceptance
  criteria, assumptions, edge cases, validation plans, and human-review checkpoints
  before coding.
---
# Implementation Planning

Create temporary planning files under `docs/ignored/implementation/<task-slug>/`.

## Required sequence

1. Restate the requested outcome.
2. Extract acceptance criteria, non-goals, constraints, and impacted users/systems.
3. List assumptions explicitly. Do not proceed on assumptions that affect behavior, contracts, architecture, or rollout; ask the human.
4. List edge cases and failure scenarios. Ask the human to accept, reject, or clarify them before implementation.
5. Research the codebase for existing patterns and ownership.
6. Research authoritative framework/library documentation when implementation depends on external behavior.
7. Split work into small implementation stages. Each stage must be independently reviewable and testable.
8. For each stage, define files likely touched, validation commands, rollback notes, and limitations.
9. Include a “not over-engineered” check: why this scope is sufficient and what was deliberately not built.
10. Wait for human approval before coding.

## Stage file template

```markdown
# Implementation Stage <N>: <name>

## Goal

## Approved requirements

## Assumptions requiring human approval

## Edge cases requiring human approval

## Existing codebase patterns to follow

## External documentation used

## Files likely touched

## Implementation steps

## Validation commands

## Limitations / version constraints

## Not-over-engineered check

## Reviewer checklist
```


## Required pre-implementation response

Before implementation begins, return exactly these sections and stop for explicit confirmation:

1. Understanding
2. Confirmed constraints
3. Assumptions
4. Repo findings
5. Documentation/MCP findings
6. Documentation files that already exist in `docs/ignored/` and are relevant
7. Documentation files that will need to be created or updated
8. Open questions
9. Status: waiting for explicit confirmation

## Feedback loop requirement

Each stage must include code review pass criteria, validation commands, documentation files to refresh, context snapshots to refresh, failure retry behavior, and human risk-acceptance criteria. Later stages may not start until the current stage passes review, validation, and documentation gates or the human explicitly accepts the remaining risk.
