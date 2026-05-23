---
name: workbook-management
description: Use when creating or maintaining temporary task workbooks for specs, research, decisions, notes, handoffs, and review artifacts.
---

# Workbook Management

Workbooks are temporary task folders under `docs/ignored/workbooks/<team>/<timestamp>-<task-slug>/`.

They are gitignored and must not be committed.

## Create a workbook

1. Create the folder with a timestamped slug.
2. Copy `.txt` templates from `.claude/templates/workbook/`, renaming them to the required `.md` filenames inside the gitignored workbook folder.
3. Rename copied template files to `README.md`, `research.md`, `design.md`, `handoff.md`, and `notes.md`, then fill metadata in `README.md`.
4. Add an activity log entry for every major event.
5. Put durable facts in the “Durable facts to promote” section for later documentation review.

## Required workbook files

Create these files inside the workbook folder, even though the reusable templates are stored as `.txt` files:

- `README.md` — metadata and activity log.
- `research.md` — options analysis and source notes.
- `design.md` — architecture decisions, contracts, schemas.
- `handoff.md` — context transfer between agents.
- `notes.md` — scratch notes.

## Promotion rule

Workbook content is evidence, not authority. Before promoting a workbook fact, re-verify it against current code, current external documentation/MCP evidence, and current confirmed requirements. If workbook content conflicts with code or verified docs, do not promote it; report the conflict.

Only durable, reviewed facts move into long-lived docs. Operational clutter stays in the workbook.

## Worktree handoff rule

When work happens in a worktree, record whether relevant `docs/ignored/*Documentation.md`, `docs/ignored/context/**`, active workbook files, and environment/config files were copied, regenerated, or intentionally omitted. Never copy secrets or env files into a worktree without human confirmation.
