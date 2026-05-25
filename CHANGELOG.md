# Changelog

All notable changes to `cc-orchestration` are documented here. Format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

For the canonical changes summaries (with full rationale and references to specific CLAUDE.md sections), see `docs/REQUIREMENTS_SPEC.md`. This file is the at-a-glance index.

---

## [3.2.6] — 2026-05-25

### Fixed
- **Orchestrator dispatch was completely broken in Claude Code 2.1.150** due to `engineering-orchestrator.md`'s `tools: Agent(name1, name2, ...)` allowlist using bare agent names. Plugin agents register under scoped identifiers (`claude-code-orchestration:codebase-researcher`), and the parenthetical allowlist's bare names did not resolve against those scoped names — the allowlist filtered the dispatch set to empty, blocking every `Agent` tool call from the orchestrator including the built-in `general-purpose`. Fix: drop the parenthetical, declare `tools: Agent, Read, Grep, Glob, Bash, PowerShell, Skill` (matches every Anthropic plugin agent's pattern). Anthropic's own official plugins (`feature-dev` 3 agents, `pr-review-toolkit` 6 agents) never use the `Agent(...)` allowlist form — they declare bare tool names only.

  **Behavior change you should know about:** the previous tool-level enforcement of "the orchestrator can only spawn these 23 specialists" is now prose-only — enforced by the "Allowed specialist agents:" line in the orchestrator's system prompt + the `meta-architecture-reviewer` audit. If you need hard tool-level enforcement, add `permissions.deny: ["Agent(forbidden-agent-name)"]` rules to your user-scope `~/.claude/settings.json` per Anthropic's "Disable specific subagents" documentation. Plugin-shipped agents cannot ship hooks (per the plugins-reference docs), so hook-based enforcement must live at user scope, not in this plugin.

  **You must restart Claude Code for this fix to take effect.** Plugin agent definitions are read at session start.

- **Documented the underlying platform constraint** that motivated the fix: per Anthropic's official sub-agents documentation, "**subagents cannot spawn other subagents**" (stated three times in three different sections). Only the main-thread agent (the orchestrator, by default) can invoke the `Agent` tool. This rule was previously implicit in the plugin's design but not stated — leading several agent descriptions and CLAUDE.md sections to imply nested dispatch was possible. New CLAUDE.md §25 makes the constraint explicit and cross-links from §4 (parallel research), §9 (plan review cycle), and other workflows that fan out.

### Changed
- **`parallel-research-coordinator.md`** — description rewritten to "read-only planner/synthesizer." Frontmatter `disallowedTools` now includes `Agent` (was `Edit, Write, NotebookEdit`). Body preamble explicitly states "you cannot dispatch — the orchestrator does." The agent's algorithm was already correct (its Round 2 algorithm step already said "The orchestrator spawns N codebase-researcher subagents"); only the surrounding language needed clarifying.
- **`engineering-orchestrator.md`** — workflow step 3 (parallel research) reworded to make explicit that the orchestrator runs the cycle and dispatches the `codebase-researcher` subagents directly. `parallel-research-coordinator` is invoked as a planning/synthesis input, not as a dispatch handoff. The "Allowed specialist agents:" prose list now includes all 23 specialists (previously had 18; the 5 added in v2 — `architecture-enforcer`, `data-architect`, `comment-policy-checker`, `parallel-research-coordinator`, `meta-architecture-reviewer` — were missing from the prose copy even though the tool-level allowlist had them).
- **`parallel-codebase-research-cycle/SKILL.md`** and **`plan-review-cycle/SKILL.md`** — description fields and round-by-round text reworded to make "the orchestrator spawns/dispatches" subject explicit. Previously the skills used passive voice ("Spawn three independent reviewer subagents") that read as if the skill or coordinator did the spawning. Skills run in the calling thread's context — when invoked from a subagent the dispatch instructions silently no-op, so the explicit subject matters.
- **`CLAUDE.md`** — §4 (parallel research paragraph and code-exploration table footer) and §9 (plan review cycle) reworded to attribute dispatching to the orchestrator. New §25 documents the platform constraint with citations, cross-references, and footguns (user/project agent shadowing of plugin scope).
- **`meta-architecture-reviewer.md`** — §7 audit rewritten: (a) flag any agent with `tools: Agent(...)` parenthetical form as the bad-pattern smell that caused this bug; (b) count the orchestrator's PROSE "Allowed specialist agents:" list instead of the (now non-existent) tool-level allowlist. New §13 audit: nested-dispatch claims grep across non-orchestrator agents (catches future regressions where a contributor writes "this agent will dispatch X" in a subagent body). New §14 audit: plugin-agent frontmatter field whitelist per the official plugins-reference (`hooks`, `mcpServers`, `permissionMode` are silently ignored when set on plugin-shipped agents).
- **`docs/REQUIREMENTS_SPEC.md`** — A23 (parallel-research-coordinator description), AC-6.13 (acceptance criterion), and OQ10 (open question — RESOLVED in this release) updated to reflect the corrected design. OQ10 in particular predicted the problem (overlapping subagent names) but the actual issue turned out to be more fundamental: bare names in the allowlist did not resolve at all, regardless of overlap.
- **Version sync**: `plugin.json` was at 3.2.5 (matched `marketplace.json`). Both bump to 3.2.6 together. The installed cache may still show 3.2.3 for users who haven't run `/plugin update` since 3.2.4 — they'll need both `/plugin marketplace update` AND `/plugin update` to reach 3.2.6.

### Second-pass review (same release)
After the dispatch fix landed, an audit of the modified files found additional issues, all fixed in this same release:

- **Stale CLAUDE.md section cross-references** — `agents/data-architect.md` cited "database safety in §8" (§8 is Greenfield vs. brownfield; correct is §19). `agents/comment-policy-checker.md` cited "Change discipline §5" (§5 is the feedback loop; correct is §13). Both fixed.
- **`agents/pr-creator.md` workflow numbering** — two consecutive steps numbered "6" (the renumber from `6, 6, 7, 8, 9` to `6, 7, 8, 9, 10` was applied).
- **Passive-voice dispatch wording in shared skills** — `skills/implementation-feedback-loop/SKILL.md`, `skills/root-cause-convergence/SKILL.md`, `skills/plan-review-cycle/SKILL.md` line 67, `CLAUDE.md` §5 step list, and `agents/parallel-research-coordinator.md` rounds 3/5 all had wording that implied a non-orchestrator agent dispatches the next step. All reworded so the orchestrator is the explicit dispatcher, consistent with §25.
- **CLAUDE.md §25 reinforced with verified primary-source citations** — added the exact quote "A fork cannot spawn further forks" from the official sub-agents docs, plus the documented behavior of `disable-model-invocation: true` ("prevents the skill from being preloaded into subagents") which makes the plugin's 5 `run-*` skills safe by construction.
- **`agents/meta-architecture-reviewer.md` §14 extended** — formerly audited only agent frontmatter against the 11-field whitelist. Now also audits skill frontmatter against the documented 15-field whitelist (`name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `shell`) per <https://code.claude.com/docs/en/skills>. Canonical reference written to `docs/ignored/AnthropicClaudeCodeSkillsDocumentation.md` (gitignored).
- **CHANGELOG self-fact-check** — original 3.2.6 entry cited "line 24" of `parallel-research-coordinator.md`; after the `disallowedTools: Agent` edit shifted lines, the quoted text is no longer at line 24. Replaced with a line-number-free reference ("its Round 2 algorithm step") to prevent future drift.

### Verification
The investigation supporting this release is recorded at `docs/ignored/workbooks/subagent-dispatch-platform-constraint/Investigation.md` (~530 lines). It cites every claim against primary sources (Anthropic docs URLs + file paths + line numbers), logs the open questions that remain (scoped-name allowlist behavior, plugin-scope `settings.json` `agent` field documentation gap, hooks/ audit), and provides a reviewer checklist. The investigation was performed by a single sequential session — the very bug under investigation blocked parallel subagent verification — so the workbook structure prioritizes independent re-verifiability of every finding.

### Post-update steps
1. `/plugin marketplace update`
2. `/plugin update`
3. **Restart Claude Code** (plugin agent files are read at session start)
4. Verify dispatch works: `@agent-claude-code-orchestration:codebase-researcher` in the typeahead, or ask the orchestrator to run a codebase-researcher on a small task

### Known limitations and future work
- Whether `tools: Agent(claude-code-orchestration:name1, ...)` (scoped names inside the parenthetical) would have worked is unverified — no Anthropic docs example uses this form, no Anthropic plugin uses it. If hard enforcement returns as a need, this is the first thing to test.
- The plugin relies on Claude Code honoring the `agent` key from a plugin-scope `settings.json` to auto-activate `engineering-orchestrator` as the main thread. This is observed working but not explicitly documented by Anthropic. Fallback if it ever breaks: `claude --agent engineering-orchestrator`.
- A separate audit pass over the `implementation-feedback-loop`, `root-cause-convergence`, and `documentation-refresh` skill bodies is recommended to ensure they also explicitly attribute dispatching to the orchestrator. Not blocking; tracked as Rec 4 in the investigation workbook.

---

## [3.2.5] — 2026-05-24

### Added
- **Bootstrap now adds `.srclight/` to the repo's `.git/info/exclude` automatically.** Completes the v3.2.4 fix: srclight's index/embeddings directory is now ignored locally in every bootstrapped repo, with no manual `git update-index` or hand-editing required. Matches the treatment of every other plugin-private pattern (`docs/ignored/`, `CLAUDE.md`, `CLAUDE.local.md`, `.worktreeinclude`, `.claude-personal/`, archive globs). Existing bootstrapped repos pick up the new pattern on the next `install_repo_bootstrap.sh` run.

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
