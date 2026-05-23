---
name: branch-creation
description: Use before creating feature, bugfix, release, PR-update, or worktree branches to infer branch conventions, choose the correct base, and require human confirmation.
---

# Branch Creation

Use this process before creating or switching branches for implementation or worktree work.

## Required checks

1. Run `git status --short --branch` and report uncommitted changes.
2. Identify the default/base branch from `gh repo view --json defaultBranchRef` when available, otherwise from `git symbolic-ref refs/remotes/origin/HEAD`, then `origin/main` or `origin/master` only when supported by repo evidence.
3. Inspect recent branch naming conventions with safe read-only commands such as `git branch -a --format='%(refname:short)' | head -100`.
4. Infer naming conventions only from evidence. If conventions conflict or are unclear, ask the human.
5. Propose the branch name, base branch, and exact command.
6. Wait for explicit human confirmation before creating, switching, pushing, or deleting any branch.

## Worktree branch rules

- For new Claude Code worktrees, prefer the repository default branch / fresh remote base unless the user explicitly requests current `HEAD`.
- Do not copy secrets or gitignored files into a worktree unless `.worktreeinclude` has been reviewed.
- State which branch the worktree will be based on and which branch will receive commits.

## Safety rules

- Do not overwrite an existing branch.
- Do not create branches from dirty state unless the human confirms how to handle uncommitted changes.
- Do not run rebase, reset, clean, force-push, branch deletion, or remote deletion without explicit human instruction.
- Do not invent ticket IDs or branch prefixes.

## Output

Return:

1. Current branch and cleanliness
2. Default/base branch evidence
3. Observed branch naming convention
4. Proposed branch name
5. Exact command to run
6. Status: waiting for explicit confirmation
