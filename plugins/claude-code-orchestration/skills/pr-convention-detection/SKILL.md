---
name: pr-convention-detection
description: Use when drafting, updating, or creating pull requests to inspect repository templates, recent merged PR conventions, title style, required sections, testing notes, risks, and migration notes.
---

# PR Convention Detection

1. Check branch state and base branch.
2. Inspect PR templates and contribution docs.
3. Use `gh pr list --state merged --limit 20` when available.
4. Prefer templates over inferred conventions.
5. Prefer recent merged PRs touching similar directories over unrelated PRs.
6. Do not invent conventions.
7. Before creating a PR, show:
   - Observed PR convention.
   - Proposed title.
   - Proposed body.
   - Base branch.
   - Head branch.
   - Commands used.
8. Create the PR only if the human explicitly asks.
