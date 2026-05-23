---
name: merge-conflict-handling
description: Use when diagnosing or resolving merge conflicts, rebases, divergent branches, or PR update conflicts safely.
---

# Merge Conflict Handling

1. Inspect branch and conflict state with safe git commands.
2. Identify conflicted files and the source of each side.
3. Understand repository patterns before editing.
4. Ask the human before choosing between conflicting product behavior, API contracts, schema changes, or business rules.
5. Resolve minimally and preserve tests.
6. Run targeted validation for the resolved files.
7. Do not rebase, reset, force-push, squash, or delete branches unless the human explicitly asks.
