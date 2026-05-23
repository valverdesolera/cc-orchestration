---
name: gitignore-local-hygiene
description: Use whenever Claude or the human creates files in the working directory that should not be committed (analysis notes, scratch scripts, prompt drafts, exported data, etc.). Adds them to `.git/info/exclude` (local-only, never pushed) so they don't follow you across branches. Solves the "untracked files polluting every branch" problem.
---

# Local Git hygiene with `.git/info/exclude`

## The problem this skill exists to solve

When you work on a branch in git, untracked files are not owned by any branch. Git only manages files that have been committed — untracked files physically sit in your working directory regardless of which branch you are on.

Real example: You're on branch `feature/A` doing analysis work (transcripts, prompt drafts, verification scripts, etc.) but never commit those files. You then create `feature/B` with `git checkout -b feature/B`. **All those untracked feature/A files follow you into feature/B** — because git had no idea they existed.

The result: `feature/B`'s `git status` is polluted with files that have nothing to do with B's work. Worse — if you carelessly `git add .`, you can accidentally commit them.

## The solution

`.git/info/exclude` is a local-only ignore file that behaves exactly like `.gitignore`, but:

- Lives inside `.git/` so it is **never committed**.
- Is **never pushed** to remote.
- Is **invisible to all other team members** (it's not in the repo tree).
- Is **permanent for your local copy** of the repo.

This is the key distinction from `.gitignore`: a `.gitignore` change is a committed file that gets pushed and affects the whole team. `.git/info/exclude` is purely personal.

## When to add to `.git/info/exclude`

Any time you create something in the working directory that is:
- Your own analysis notes / scratchpad
- A prompt draft, transcript, or generated text file
- A throwaway script for a specific debug session
- Exported data, fixtures, or test artifacts you want locally but not in version control
- Anything under `docs/ignored/` (already handled by the repo bootstrap, but verify)
- Any file you find yourself manually `.gitignore`-ing on a one-off basis

## Procedure

Step 1 — Find the local exclude file:
```bash
git rev-parse --git-path info/exclude
```
This handles bare repos, worktrees, and submodules correctly.

Step 2 — Append the pattern, with a comment:
```bash
echo "# <reason>" >> "$(git rev-parse --git-path info/exclude)"
echo "<pattern>" >> "$(git rev-parse --git-path info/exclude)"
```

Step 3 — Verify it's now ignored:
```bash
git check-ignore -v <path>
```
The output should reference `.git/info/exclude`.

Step 4 — Verify `git status` no longer shows the file.

## Pattern conventions

- Prefer specific patterns over wildcards. `analysis-transcript-2026-05-23.txt` over `*.txt`.
- For groups of related files, use a directory + trailing slash: `my-scratchpad/`.
- For test exports: `/tmp-exports/`, `/local-fixtures/`.
- For "any file matching this name anywhere": `<filename>` (no leading slash).
- For "this file only at repo root": `/<filename>` (leading slash).

## Hard rules

- Never add the same pattern to both `.gitignore` and `.git/info/exclude` — it's redundant and confusing.
- Never add a pattern that the team would also want excluded — that belongs in `.gitignore`. `.git/info/exclude` is for personal-only patterns.
- The bootstrap script for this plugin already populates `.git/info/exclude` with the standard patterns (`docs/ignored/`, `CLAUDE.local.md`, etc.). Don't duplicate those.
- When in doubt, ask the human. Adding a pattern is reversible; mis-committing a file may not be.

## Cleanup

To stop excluding a pattern, edit `$(git rev-parse --git-path info/exclude)` and delete the line. There's no `git exclude rm`.

## Worktrees

Each worktree has its own `.git/info/exclude` (under the worktree's `.git/` redirect). When you create a new worktree with the bundled `new-worktree.sh`, the bootstrap re-populates `.git/info/exclude` in the new tree with the standard patterns. Personal patterns you added to the main repo's exclude file do NOT carry over automatically — re-add them if needed.

## Common patterns to add proactively

When you start a new task, before creating any scratch files, add these patterns up front:
```
# Personal scratch for this task — never push
/scratch-<task-slug>/
/notes-<task-slug>.md
/draft-*.md
```
This is much easier than tracking down files later.
