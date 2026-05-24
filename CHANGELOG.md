# Changelog

All notable changes to `cc-orchestration` are documented here. Format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For the canonical changes summaries (with full rationale and references to specific CLAUDE.md sections), see `docs/REQUIREMENTS_SPEC.md`. This file is the at-a-glance index.

---

## [3.2.4] — 2026-05-24

### Fixed
- **Bootstrap `post-commit` / `post-checkout` hooks: srclight no longer dirties the repo's tracked `.gitignore`.** srclight's `index` command unconditionally appends `.srclight/` to `<repo>/.gitignore` (see `srclight/cli.py::_ensure_gitignore`). The hooks now snapshot `.gitignore` before invoking srclight and restore it byte-for-byte after, so the repo's tracked `.gitignore` is never modified. Keep `.srclight/` in `.git/info/exclude` (local-only) instead. Aligns with `gitignore-local-hygiene` skill guidance ("Never add a pattern that the team would also want excluded — that belongs in `.gitignore`. `.git/info/exclude` is for personal-only patterns.") and with how the bootstrap already handles every other plugin-private pattern.
- **Bootstrap `post-commit` / `post-checkout` hooks: removed bogus `--incremental` flag from `srclight index` invocation.** srclight 0.8.1 has no `--incremental` flag (`srclight index` accepts only `--db` and `--embed`). The flag caused srclight to exit with "No such option" every commit/checkout, silently swallowed by `2>/dev/null || true`. Net effect was that the hooks ran but srclight never actually indexed.

---

## [3.2.3] — 2026-05-24

### Fixed
- **README.md and INSTALL.md** described `/cco-update` as a "one-step shortcut"; it was reframed to verifier-only in 3.2.2 but the user-facing docs were never updated. Now both correctly describe `/cco-update` as a verifier and tell the user to run `/plugin marketplace update` + `/plugin update` themselves.
- **INSTALL.md §9** told the user "To pull updates later: `/cco-update`." — misleading for the same reason. Replaced with the actual two-step flow plus a pointer to §5 for the fallback re-install sequence.
- **plugins/.../reference/README.md** referenced `INSTALL.md §3.1` which no longer exists after the v3.2.1 INSTALL.md rewrite. Updated to point at §4 ("Recommended companion plugins"). Also corrected `_recommendedPlugins` → `_recommendedPluginsSource` to match `plugin.json`.

### Added
- **`LICENSE`** at repo root (MIT, matching the license declared in `plugin.json`). Closes the legal ambiguity gap of having a public repo with no license file.
- **`CHANGELOG.md`** at repo root (this file). Consolidates version history that was previously only buried in `REQUIREMENTS_SPEC.md`.

---

## [3.2.2] — 2026-05-24

### Changed
- **`/cco-update` reframed as verifier-only**. Discovered after shipping v3.2.1 that Claude cannot programmatically invoke Claude Code's built-in slash-commands (`/plugin marketplace update`, `/plugin update`) from inside a custom slash-command. The command now honestly describes what it does: read the installed plugin version, the local marketplace HEAD, and the GitHub remote; produce a comparison table; and tell the user the exact commands to run if out of date. No more pretending to be a one-step shortcut.
- **CI: `actions/checkout` bumped v4 → v5** in `.github/workflows/auto-tag.yml`. Silences the Node 20 deprecation warning. No functional change.

### Added
- **`.gitignore`: `.claude/`** — local Claude Code session state that appears when this repo is opened in Claude Code. Distinct from the plugin's `.claude-plugin/` (which is and should remain committed).

---

## [3.2.1] — 2026-05-24

### Changed
- **Bootstrap** — Cross-platform Python 3 detection. The script now tries `python3` first, falls back to `python` (verifying it's Python 3.x), and on Windows Git Bash auto-creates a `python3.exe` shim alongside `python.exe` when only `python` is available. Fails fast with a platform-specific install command if no Python 3 is found.
- **Bootstrap** — `<github-owner>` placeholder replaced with `valverdesolera` in `--print-plugins` output and the "Next steps" message, now that the repo is public.
- **Bootstrap** — Final-message tip pointing users at the new `/cco-update` slash-command for easier updates.
- **Repo went public.** Eliminated the entire auth flow (SSH keys, PATs, collaborator invites) for cloning, installing, and updating across machines.
- **README.md rewritten** as a 30-second-install landing page with current layout (no more outdated `marketplace/` path; reflects restructured root-level `.claude-plugin/`).
- **INSTALL.md rewritten** around the simple case first, with per-OS notes (macOS / Linux / Windows-Git-Bash) and a focused troubleshooting section.

### Added
- **`/cco-update` custom slash-command** — initially shipped as a "one-step shortcut" that wraps `/plugin marketplace update` and `/plugin update`. (See 3.2.2 for the honest reframing — it turned out Claude cannot invoke built-in slash-commands from a custom one.)
- **CI: GitHub Actions auto-tag workflow** (`.github/workflows/auto-tag.yml`) watches `plugin.json` and `marketplace.json` on push to main; verifies both versions agree; auto-creates and pushes the matching `vX.Y.Z` tag. Idempotent. Eliminates manual `git tag` + `git push` step.

---

## [3.2.0] — 2026-05-24

### Changed (CLAUDE.md parity pass against the user's external global engineering rules)
- **§3** — Added verification-status discipline: unverified external behavior must be labeled UNVERIFIED in pre- and post-implementation responses; not hidden, not a hard stop.
- **§4** — Added "prefer reusing existing utilities and abstractions" as an explicit positive directive in codebase research.
- **§5 step 8** — Lint and type-check are now first-class loop gates alongside tests; the agent reports which gates ran and which were not configured.
- **§11** — Post-implementation response now requires: "Summary of Documentation Changes" (rationale, not just file list), "Tests / Lint / Type-Check Results" (replaces the generic "Validation Run"), "Rule Compliance Self-Check", and explicit inclusion of UNVERIFIED claims in Remaining Risks.
- **§13** — Added "prefer the simplest solution that matches confirmed requirements and current architecture" as a positive directive; complexity must be justified by a confirmed requirement.
- **§15** — Expanded "Canonical per-dependency documentation" subsection: `<CanonicalName>Documentation.md` naming, one-file-per-dependency, check-before-create, required-contents schema, on-change and on-removal rules. Pulled out of the `documentation-refresh` skill into the narrative authority so every agent sees it on every session.

---

## [3.1.0] — 2026-05-23

### Added
- **Bootstrap `clean_stale_personal_config()` function**. Reads `~/.claude.json`, backs it up to `~/.claude.json.backup-pre-cc-orchestration` (one-time, never overwritten), and removes the known-stale `microsoftLearn` MCP entry that duplicates `microsoft-docs@claude-plugins-official`. Generalizable — add new stale entry names to the `STALE_MCP_ENTRIES` array as duplicates surface.
- **Meta-architecture-reviewer agent** — read-only agent that audits the plugin itself for overlap, drift, and unclear handoffs.

### Changed
- **Repo restructured for GitHub-direct install.** `.claude-plugin/marketplace.json` moved to root; `plugins/claude-code-orchestration/...` underneath; `bootstrap/` and `docs/` are root-level siblings. Enables `/plugin marketplace add <owner>/<repo>` without any `--source` indirection.

---

## [3.0.0] — 2026-05-23

### Added
- **Single source of truth for the 15-plugin list** — `reference/recommended-plugins.json`. CLAUDE.md §21, INSTALL.md, `bootstrap/install_repo_bootstrap.sh --print-plugins`, and `plugin.json` `_recommendedPluginsSource` all reference it. Eliminates the 4-way drift in v2.
- **Graceful degradation** — each agent now documents what it falls back to when an official plugin isn't installed (`fallback_when_missing` field in the reference JSON).
- **Hard gates for plan finalization** — `implementation-planner` requires `Limitations.md` (3+ entries) and `EdgeCases.md` (1+ per stage, human-confirmed) plus a `plan-review-cycle` round plus a `Parallelization-Decision` plus mode declaration plus no-drift confirmation plus a not-over-engineered check before producing `Plan-Final.md`.
- **Pre-implementation response template** (CLAUDE.md §10) now includes Edge Cases and Limitations sections; orchestrator waits for explicit confirmation of Assumptions + Edge Cases + Parallelization.
- **Postman MCP section** (CLAUDE.md §20.6) — explicit install/use guidance for MCPs without an official plugin yet.
- **Workbook path decision** (CLAUDE.md §20.7) — documented why this plugin uses `docs/ignored/workbooks/<slug>/` over the original `docs/temp/<team>/` path.

### Changed
- **Consolidated review pipeline** to ONE policy reviewer + ONE bug-finder pass per loop iteration (CLAUDE.md §5). No more 5-reviewer pile-up. Loop bounded by 5 review-fix iterations and 3 validation-fix iterations with escalation.

---

## [2.x] and earlier

See `docs/REQUIREMENTS_SPEC.md` §v2 supplement (and prior version notes inside the spec) for the v2 architecture: the introduction of `architecture-enforcer`, `data-architect`, `comment-policy-checker`, `parallel-research-coordinator`; the `greenfield-vs-brownfield`, `plan-review-cycle`, `parallel-codebase-research-cycle`, `parallelization-decision`, `pr-merge-conflict-wait`, `assumption-validation-tests`, `official-docs-first`, `gitignore-local-hygiene` skills; the new SG10–SG16 guardrails; the plan-folder-organization convention; and the local git hygiene story.

---

## Versioning policy

- **MAJOR** — breaking changes to the engineering ruleset, agent contracts, or repo structure.
- **MINOR** — additive: new agents, new skills, new rules, new commands.
- **PATCH** — bug fixes, doc corrections, dependency bumps, no behavior change for end users.

Version is declared in three places and kept in sync by CI:
- `plugins/claude-code-orchestration/.claude-plugin/plugin.json` → `version`
- `.claude-plugin/marketplace.json` → `metadata.version` and `plugins[0].version`
- `docs/REQUIREMENTS_SPEC.md` → version header

When a version-bump commit lands on `main`, `.github/workflows/auto-tag.yml` automatically creates and pushes the matching `vX.Y.Z` tag.
