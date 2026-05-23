---
name: safe-git-commit
description: Use before staging, committing, or pushing to verify git state, branch conventions, staged files, author identity, commit message safety, and temporary artifact exclusion.
---

# Safe Git Commit

This skill is a safety checklist. It does not authorize staging, committing, or pushing. Those actions still require explicit human instruction and normal Claude Code permissions.

## Checklist

1. Run `git status --short --branch`.
2. Confirm current branch is not `main`, `master`, `develop`, or the default branch unless the human explicitly approves.
3. Inspect staged files with `git diff --cached --name-status`.
4. Do not stage or commit:
   - `docs/ignored/**`
   - `docs/temp/**`
   - workbooks
   - `.module-context.md`
   - `.claude/worktrees/**`
   - `.claude/settings.local.json`
   - temporary scripts or scratch files
   - Markdown documentation outside `docs/ignored/` unless the human explicitly approved committed documentation, while allowing required Claude Code configuration Markdown
5. Confirm `git config user.name` and `git config user.email` are correct for this repository.
6. Ensure commit message does not mention Claude, Anthropic, AI-generated code, or co-authorship.
7. Summarize validation already run and not run.
8. Only push when explicitly asked.
