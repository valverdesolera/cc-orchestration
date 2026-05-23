---
name: validation-matrix
description: Use when deciding which tests, builds, schema generation, image builds,
  lint checks, or manual validation must run for changed files.
---
# Validation Matrix

Determine validation from the files changed and the repository’s actual commands.

## Baseline process

1. Run `git status --short` and inspect changed paths.
2. Discover available commands from package files, pyproject, Makefiles, CI workflows, Dockerfiles, and docs.
3. Prefer targeted tests for each completed implementation stage.
4. Run broader builds/tests before final push.
5. If verification cannot run, state exactly what remains unverified.

## Project-specific checks to preserve when relevant

- For `app/web/src/**`, run: `cd app/web && npm run build`.
- For `src/ephai_intake/**` or `srv/**`, run: `uv run pytest`.
- For `schemas/queue-messages.json`, run `bash schemas/generate.sh` first, then run both affected frontend/backend checks.
- If images or containers are modified, build the image before final push.
- Never treat `npm run dev` as proof that the production build is clean.

## Output format

```markdown
## Validation Plan

| Area | Changed paths | Command | Why | Status |
|---|---|---|---|---|

## Manual checks

## Not run / risks
```


## Required post-implementation response

After each implementation unit, report:

1. What changed
2. Files affected
3. Documentation files created or updated
4. Summary of documentation changes
5. Validation run: tests, lint, type-check, builds, schema generation, image builds, or manual checks
6. Rule re-check
7. Remaining risks or open issues

## Failure loop

If validation fails, do not proceed to the next implementation unit. Return exact failure evidence to the orchestrator/coding-agent. After a fix, run code review again before rerunning validation. Repeat until validation passes or the human explicitly accepts the remaining risk.
