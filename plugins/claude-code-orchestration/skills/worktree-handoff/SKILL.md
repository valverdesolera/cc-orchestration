---
name: worktree-handoff
description: Use before starting or handing off Claude Code worktree work to decide which gitignored context, docs, workbooks, env files, and setup steps must be copied, regenerated, or omitted.
---

# Worktree Handoff

Claude Code worktrees are fresh checkouts. Gitignored files such as `docs/ignored/**`, active workbooks, local context snapshots, `.env`, `.env.local`, and dependency caches are not automatically present unless `.worktreeinclude` or another handoff process copies them.

## Required process

1. Identify the target worktree name, base branch, and branch that will receive commits.
2. Identify relevant `docs/ignored/*Documentation.md` files.
3. Identify relevant `docs/ignored/context/**` snapshots.
4. Identify the active workbook folder under `docs/ignored/workbooks/**`.
5. Decide whether each artifact should be copied, regenerated, or omitted.
6. For `.env*`, credentials, secrets, tokens, and private config: ask the human before copying. Reading env files in the main repo is allowed by this pack, but duplicating them into a worktree is still a separate safety decision.
7. Record copied/regenerated/omitted items in the workbook `README.md` activity log.
8. After entering the worktree, verify dependencies, virtualenvs, generated artifacts, and local setup before coding.

## Output

Return:

1. Worktree/base branch decision
2. Context files to copy or regenerate
3. Documentation files to copy or regenerate
4. Workbook files to copy or regenerate
5. Env/config files requiring human confirmation
6. Setup/validation commands to run in the worktree
7. Status: waiting for explicit confirmation before copying secrets or creating/switching worktrees
