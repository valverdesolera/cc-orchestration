---
name: codebase-contextualization
description: Use before coding in a branch and after meaningful code changes to generate or refresh module context files that summarize architecture, dependencies, data flow, contracts, and guardrails.
---

# Codebase Contextualization

Use this skill before implementation starts on a branch and after code changes that alter module behavior or topology.

## Output location

Use only gitignored central snapshots under `docs/ignored/context/<module-path>.md`. Encode module paths with stable names, for example `src-payments-checkout.md` or `app-web-auth.md`.

Do not create or edit module-local `.module-context.md` files. They conflict with the current Markdown hygiene rule and are blocked by hooks.

Do not commit generated context files unless the human explicitly promotes a durable fact to official docs.

## Module context template

```markdown
# Module: <Name>

## Purpose
Core responsibility, key entry points, expected inputs/outputs, and invariants.

- **Primary Users/Callers:**
- **Core Logic:**

## Dependencies
Internal modules and external boundaries touched.

## Architectural Constraints
Crucial allowed/forbidden dependencies and “do nots”.

## Internal Topology
- **File Layout Map:**
- **Key Internal Classes / Functions:**

## Execution & Data Flow
Mermaid or text-based sequence.

## Cross-Cutting Concerns
- **Dependencies:**
- **State & Side Effects:**
- **Telemetry:**

## Public Interface & Contracts
- **Primary Entry Points:**
- **Data Contracts / Schemas:**
- **Expected Invariants:**

## Directory Layout & Key Files

## Dependencies & Side Effects
- **Internal Imports:**
- **External Services:**
- **State / Mutations:**

## Architectural Guardrails
- **Allowed:**
- **Forbidden:**
```

## Refresh rules

- Refresh only affected modules unless the change is repo-wide.
- Refresh after meaningful code changes before code review so reviewers are not working from stale architecture context.
- Mark stale or uncertain facts instead of guessing.
- If a durable fact belongs in official docs, add it to a documentation-reviewer handoff.
