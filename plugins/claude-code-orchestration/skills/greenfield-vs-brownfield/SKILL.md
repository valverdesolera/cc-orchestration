---
name: greenfield-vs-brownfield
description: Use when deciding HOW to approach an implementation — from scratch (greenfield) vs. modifying existing code (brownfield). Brownfield is the default and is much stricter about following existing patterns; greenfield is design-led and uses the official feature-dev plugin's code-architect for approach proposals.
---

# Greenfield vs. brownfield implementation

Before any planning starts, decide which mode applies.

## Detection

| Signal | Mode |
| --- | --- |
| Touched files all in a new module that doesn't exist yet | Greenfield |
| Touched files include any existing module's code | Brownfield (at least partly) |
| Mixed (some new, some existing) | Treat the new module as greenfield, the changes to existing modules as brownfield, and produce *two* plan sections accordingly |

## Greenfield rules

- Run the official `/feature-dev` workflow first to explore similar code in the repo (`code-explorer`) and to get architecture proposals (`code-architect`).
- Pick ONE proposal explicitly; document the rejected alternatives and why.
- Write the module's Context File under `docs/ignored/context/<module>/` *before* coding starts, not after.
- Document allowed/forbidden imports for this module in the Context File. The `architecture-enforcer` agent will use this on every change.
- Pick the testing strategy up front (use the official `superpowers` TDD framework if applicable). Tests must fail first.

## Brownfield rules (STRICTER — default)

- DO NOT redesign. The existing patterns are the design.
- Before writing any code, run the `codebase-contextualization` skill (parallelized via `parallel-research-coordinator` if the area is large) to refresh the Context Files for every touched module.
- Read 2–3 nearby existing implementations of similar functionality. Mirror their:
  - Layer structure
  - Naming conventions
  - Error model
  - Test style
  - Telemetry calls
- Drift is acceptable ONLY when:
  - The implementation plan explicitly declares "Drift: <reason>"
  - The human has confirmed the drift in writing
  - The Context File is updated to reflect the new pattern
- Use the official `superpowers` plugin to enforce that the new code's tests look like the project's existing tests (TDD red-green-refactor in the project's existing test framework).
- After the change, `architecture-enforcer` must return `ALIGNED` or `DRIFT_ACCEPTABLE_PER_PLAN`. If it returns `DRIFT_REQUIRES_HUMAN_REVIEW`, stop and escalate.

## Output: section in the implementation plan

```
## Implementation Mode
Mode: greenfield | brownfield | mixed
Greenfield modules: ...
Brownfield modules: ...
Rationale: why this mode applies.

## Existing-Pattern References (brownfield only)
- Pattern A: <file:line> — what it does and why we'll mirror it
- Pattern B: ...

## Drift Declarations (if any)
- Where: <module>
- What pattern we're breaking: ...
- Why the existing pattern doesn't fit: ...
- Human approval reference: ...
- Context File update: ...
```

## Mode mismatch is a hard stop

If, during implementation, you discover the work is actually brownfield (touches existing code) but the plan was written as greenfield (or vice versa), stop coding and ask the human. Do not silently switch modes.
