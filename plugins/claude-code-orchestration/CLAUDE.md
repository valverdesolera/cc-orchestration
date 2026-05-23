# Claude Code orchestration — engineering rules

These rules apply whenever this plugin is enabled. They are read by every subagent and by the orchestrator at the start of every session.

**This document is the narrative authority.** Structured lookups (plugin lists, fallback tables) live under `reference/` (machine-readable). If a rule here contradicts a value there, this document wins.

## 0.0) Authority of these rules

**These custom rules are the spec.** The official plugins (`feature-dev`, `superpowers`, `code-review`, `context7`, `microsoft-docs`, `serena`, `github`, `atlassian`, `playwright`, `chrome-devtools-mcp`, `claude-md-management`, `commit-commands`, `claude-code-setup`, `pr-review-toolkit`, `frontend-design`) are TOOLS that the custom agents and skills below use to do their work. They are **never** substitutes for the custom agents or for any rule below.

If an official plugin's workflow conflicts with a rule here, the rule here wins, and the agent must adapt or constrain the plugin's behavior — not skip the custom requirement.

Examples of "uses, not replaces":
- `code-reviewer` (custom) runs its full review against the approved stage, edge cases, architecture, comments policy, and existing patterns. It additionally invokes `/code-review` from `code-review@claude-plugins-official` for the diff-level bug pass. Both must pass.
- `requirements-product-analyst` (custom) enforces NO ASSUMPTIONS and produces acceptance criteria, non-goals, edge cases. It may use `/brainstorming` from `superpowers@claude-plugins-official` as input for the Socratic step. The custom output contract (assumptions list, open questions, etc.) is non-negotiable.
- `architecture-enforcer` (custom) verifies alignment with existing architecture (brownfield) or with the declared design (greenfield). It may consume `code-architect` proposals from `feature-dev@claude-plugins-official` as input, but it always makes the alignment verdict itself.
- `codebase-researcher` (custom) may use `serena`, `codegraphcontext`, `tree-sitter`, `codanna`, `codeql`, `srclight` — whichever is best for the task. It still must produce a `docs/ignored/context/<module>/` snapshot following the schema in §3 of the requirements spec.
- `test-agent` (custom) may invoke `superpowers`' red-green-refactor TDD as the execution shell. It still must produce the pre/post-test artifacts described in §6.
- `pr-creator` (custom) uses `github@claude-plugins-official` for the API + `commit-commands` for safe commit messages. It still must follow the no-Claude-attribution, no-ticket-in-message, repo-convention-detection logic from the custom spec.

## 0.1) Non-interference

- This plugin is personal. Do not create, edit, commit, or push project-level Claude Code config (`.claude/**`, `CLAUDE.md`, `.mcp.json`, committed Claude docs) unless the human explicitly asks to change the team's setup.
- Use `docs/ignored/**` for transient files: implementation plans, workbooks, dependency docs, context snapshots.
- Do not create or edit `**/.module-context.md` in source trees; module contextualization belongs under `docs/ignored/context/**`.

## 1) Verify before claiming

**SUPER-CRITICAL.** Before stating a fact, asserting a behavior, or proposing a fix, verify it.

- For external libs/frameworks/APIs: see §3 (Official docs first).
- For codebase facts: read the actual file. Quote file paths and line ranges in your response.
- For test results: actually run the test, paste the output.
- For "this is impossible": prove it; or admit uncertainty.
- "I believe", "I think", "should be" are flags that you have NOT verified. Either verify or label the claim as a hypothesis.

## 2) No assumptions before planning or coding

Before planning or coding, list uncertainties and missing information. Ask clarifying questions for every unclear point that can affect behavior, interfaces, architecture, data, rollout, validation, or risk. Wait for explicit user confirmation before implementation.

Required pre-implementation response (§10) is non-negotiable.

## 3) Official docs first (IMPERATIVE)

Before analyzing or proposing a change to anything involving a third-party framework, library, SDK, API, CLI, or cloud service, you MUST consult its official documentation through the right plugin/MCP and CITE the source. No claim about external behavior is allowed from training memory alone.

**Routing rule: pick the most-specific source FIRST. Context7 is the generic fallback, NOT the default.**

| If the topic is about… | Use this FIRST | Then fall back to… |
| --- | --- | --- |
| Anything Microsoft / Azure / .NET / VS Code APIs / TypeScript on MS stack | `microsoft-docs@claude-plugins-official` | context7 → WebSearch |
| Jira, Confluence, Atlassian APIs | `atlassian@claude-plugins-official` | context7 → WebSearch |
| GitHub API, Actions, code scanning, GraphQL | `github@claude-plugins-official` | context7 → WebSearch |
| Browser behavior, DOM APIs, web platform | `chrome-devtools-mcp@claude-plugins-official` + `playwright@claude-plugins-official` | MDN via WebSearch → context7 |
| Any other library / framework / SDK with public docs | `context7@claude-plugins-official` (version-aware) | vendor MCP if exists → WebSearch |
| Google Cloud / AWS / other vendors without a dedicated plugin yet | Vendor's own MCP if installed (`/mcp add`) | context7 → vendor's official docs via WebSearch |
| Codebase facts (your own code) | `serena@claude-plugins-official` (semantic) | `codegraphcontext`, `tree-sitter`, `codanna`, `codeql`, `srclight` MCPs → grep |

Rule: if a vendor-specific plugin exists, using context7 instead is a smell. Use the specialist source.

When no plugin exists for a vendor (Google Cloud, AWS, Stripe, Twilio, etc.), the order is:
1. Vendor's own MCP if you've installed it manually via `/mcp add`
2. `context7` with the library identifier (it often has them indexed)
3. `WebSearch` with `site:docs.<vendor>.com` filter, cite the URL

See the `official-docs-first` skill for the full procedure. **Before proposing any fix, run this skill.**

## 4) Repo & codebase research first (use the right tool, not just one)

Before proposing or making changes, research the codebase: architecture, layers, boundaries, naming patterns, utilities, similar implementations, call sites, data flow, config, secrets handling, tests, CI, ownership. Cite repo paths, symbols, and short extracts.

For non-trivial research across >3 modules, use `parallel-research-coordinator` and the `parallel-codebase-research-cycle` skill. **Never silently parallelize — ask first** (see §7).

**Code-exploration tools, by capability — use them in combination, not just one:**

| Task | Preferred tool | Why |
| --- | --- | --- |
| Find symbols, definitions, references, "who calls this function" | `serena@claude-plugins-official` | Semantic, LSP-backed, fast |
| Call graphs, "trace this code path end-to-end" | `codegraphcontext` MCP | Turns the codebase into a queryable graph |
| AST-level structural queries ("find every `useState` in this file") | `tree-sitter` MCP | Real parser, no regex false-positives |
| Implementation tracing across calls | `codanna` MCP | Function discovery + relationships |
| Static analysis / security queries | `codeql` MCP | Full CodeQL query language |
| Cross-repo or large-codebase search | `srclight` MCP | Optimized search index |
| Quick exact-text searches | `Grep` tool (ripgrep) | Fast, no setup |
| File listings, structure | `Glob` tool | Fast, no setup |

Use `serena` first because it has both a plugin install (one command, no manual MCP setup) and semantic understanding. Fall through to the MCPs for tasks `serena` doesn't cover. Use `Grep`/`Glob` only for trivial lookups that don't need semantic understanding.

For a multi-area research pass, the `parallel-research-coordinator` will pick different tools for different areas (e.g., `serena` for one area, `codeql` for a security-related area, `codegraphcontext` for a call-graph-heavy area).

## 5) Canonical implementation feedback loop

**Important distinction**: the LOOP iterates as many times as needed (until reviews pass or human accepts risk). What's bounded is the **number of different review SYSTEMS per iteration**, not the **number of iterations**.

### Per iteration of the loop

Each iteration runs THIS sequence:

1. `coding-agent` implements or fixes (initial pass writes the unit; later passes apply minimal fixes from the previous iteration's feedback).
2. `codebase-contextualization` refreshes touched modules under `docs/ignored/context/**`.
3. `architecture-enforcer` verifies alignment with existing patterns (brownfield) or the declared design (greenfield). Verdict gates the next step.
4. `code-reviewer` (custom) reviews against the approved stage, edge cases, architecture, comment policy, existing patterns, AND placeholder/stub detection. This is the policy review.
5. `/code-review` from `code-review@claude-plugins-official` runs for the diff-level bug pass (line-by-line bugs, removed-behavior audit, cross-file tracer). This is the bug-finding pass.

Per iteration, exactly TWO review systems run (custom `code-reviewer` + `/code-review`). DO NOT also run feature-dev's built-in code-reviewer or pr-review-toolkit here — those are for PR-level review, not unit-level. They appear in step 12 (PR phase), not here.

### Loop control

6. **If either review fails → start a new iteration**: go back to step 1 with the feedback. Repeat steps 1→5.
7. **If both reviews pass on this iteration → proceed to testing** (step 8).
8. `test-agent` runs targeted tests first (per `validation-matrix`), then broader validation. For bug fixes and feature work, `assumption-validation-tests` must produce PreTest (FAIL) and PostTest (PASS) artifacts.
9. **If validation fails → start a new iteration**: go back to step 1 with the test-failure feedback. Repeat steps 1→5 (review), then step 8 again.
10. **If validation passes → finalize**:
    - `documentation-reviewer` updates `docs/ignored/**` and removes stale/contradictory content.
    - `comment-policy-checker` scans the diff + commit message for forbidden references (§14). BLOCKS the unit from advancing if violations found.
11. Unit is "done" only when all gates pass — or the human explicitly accepts a labeled residual risk.

### Iteration limits

- **Max iterations per unit: 5.** If reviews still fail after 5 review-fix iterations, ESCALATE to the human. Do not loop forever.
- If validation has failed 3 times after passing review, ESCALATE — that pattern suggests the test or the architecture is wrong, not the code.
- The orchestrator records each iteration's outcome in the workbook's activity log for audit.

### PR-level phase (separate, not part of this loop)

12. When the unit is done AND we're forming a PR, run the PR-level phase ONCE:
    - `pr-reviewer` (custom) — policy review over the full PR diff
    - `/code-review` — bug pass over the full PR diff
    - `pr-review-toolkit@claude-plugins-official` — additional review angles
    - `pr-merge-conflict-wait` — block PR-submitted status until GH mergeability is CLEAN

### Cardinality summary

| Phase | Reviewers per iteration | Max iterations |
|---|---|---|
| Unit-level loop (steps 1-9) | 2 (custom code-reviewer + /code-review) | 5 review-fix; 3 validation-fix |
| PR-level phase (step 12) | 3 (pr-reviewer + /code-review + pr-review-toolkit) | 1 (PR-level fixes loop back to unit-level if needed) |

## 6) Test-driven validation of assumptions

**Unless you are strictly sure of an issue, write a test first.** The test must FAIL before implementation and PASS after. Compare pre-implementation and post-implementation test results — that comparison is the proof the fix works.

- For bug fixes: the test reproduces the bug.
- For features: the test specifies the behavior.
- For performance: the test is a benchmark with a regression threshold.

Combine with `superpowers@claude-plugins-official` (red-green-refactor TDD enforcement) when installed. Use `assumption-validation-tests` skill for the pre/post comparison artifacts.

## 7) Parallelization is opt-in, never assumed

Before fanning out work to multiple subagents, multiple stages, or multiple researchers, **ask the human** which groups can run in parallel and which must serialize. Default is SERIALIZE. See `parallelization-decision` skill.

Reasons to serialize even when it looks parallel-safe:
- Stages may touch the same files
- Stage B's design depends on Stage A's output
- Race conditions in the workflow itself
- Token budget

## 8) Greenfield vs. brownfield

Identify the mode before planning. Default is **brownfield** (stricter; follow existing patterns). Greenfield uses `feature-dev@claude-plugins-official` for `code-explorer` + `code-architect`. See `greenfield-vs-brownfield` skill.

Drift from existing patterns in brownfield requires:
- Explicit "Drift" declaration in the implementation plan
- Human approval in writing
- Context File update

## 9) Implementation plan + review cycle

Plans go through `plan-review-cycle`: three parallel reviewers (requirements / architecture / feasibility) → consolidation → revision → re-review. Up to 5 rounds; only `Plan-Final.md` is implementable. See `plan-review-cycle` and `plan-folder-organization` skills.

Every feature gets its own folder under `docs/ignored/implementation/<feature-slug>/`. **Slug never contains the ticket ID, branch name, or team-internal identifier.** See `plan-folder-organization`.

## 10) Required pre-implementation response

Before implementation, the orchestrator MUST produce:

```
## Understanding
## Confirmed Constraints
## Assumptions (each flagged as ASSUMED, to be confirmed)
## Repo Findings (with paths and line ranges)
## Documentation / MCP Findings (with citations per §3)
## Relevant Existing docs/ignored Docs
## Docs To Create / Update
## Edge Cases (per stage; EACH must be human-confirmed before implementation)
## Limitations (framework versions, deploy environment, rollback constraints)
## Open Questions
## Mode: greenfield | brownfield | mixed
## Parallelization Proposal (which stages parallel, which serial — human must approve)
## Status: waiting for explicit confirmation of Assumptions + Edge Cases + Parallelization
```

Do not implement until the user explicitly confirms ALL of:
1. Each Assumption (or marks it as "no longer assumed; here's the answer")
2. Each Edge Case (or marks it as "out of scope")
3. The Parallelization Proposal

Implementation that begins without these confirmations is a violation of §2.

## 11) Required post-implementation response per unit

After each unit:
```
## What Changed
## Files Affected
## Documentation Files Created / Updated
## Validation Run
## Pre/Post Test Comparison (per §6)
## Architecture Alignment Verdict (from architecture-enforcer)
## Comment Policy Verdict (from comment-policy-checker)
## Remaining Risks / Open Issues
```

## 12) Root-cause convergence for bugs

For high-impact, production-facing, or uncertain bugs: capture original evidence, split hypotheses by layer when useful, use independent finder agents or agent teams ONLY with user approval, compare findings for convergence before claiming root cause, report divergence instead of forcing a conclusion. After a fix, rerun the original reproduction/test/CI/browser/monitoring/MCP check.

For browser-related bugs, prefer `chrome-devtools-mcp@claude-plugins-official` + `playwright@claude-plugins-official` over manual reproduction.

## 13) Change discipline

Do not change code without understanding surrounding modules, call sites, data flow, and architectural role.

No TODOs, placeholders, pseudo-code, stubs, speculative abstractions, blanket try/except, unnecessary fallbacks, or over-engineered solutions unless discussed with the human reviewer.

**Code comments must explain code behavior only.** Never mention implementation plans, Jira tickets, branches, PRs, Claude, Anthropic, or AI generation. Enforced by `post-edit-policy-check.sh` hook AND the bootstrap's Git pre-commit hook AND the `comment-policy-checker` agent.

## 14) Commit + PR policy

- Use the appropriate git user.
- Never include Claude/Anthropic/AI attribution in commit messages or PR bodies.
- Never include "Co-authored-by: Claude" or equivalent.
- Never reference implementation plans, stages, phases, workbooks, or full branch names in commit messages.
- Ticket-ID trailers (e.g., `Refs: ABC-123`) are allowed ONLY if the repo's CONTRIBUTING/template requires them. Default: no.
- Don't commit/push `docs/ignored/**`, workbooks, plans, context snapshots, env files, logs, temp scripts, repo-level `.claude/**`, repo `CLAUDE.md`, `.mcp.json`, or `.worktreeinclude`.
- `comment-policy-checker` agent runs before every commit. Bootstrap installs Git pre-commit + commit-msg + pre-push hooks enforcing the same.

## 15) Documentation hygiene + every-cycle update

Every cycle of code changes triggers `documentation-reviewer` to update `docs/ignored/**`. Plans that go through multiple revisions accumulate stale info — `documentation-refresh` skill prunes it. Workbook-to-long-lived-doc promotion happens only for re-verified durable facts.

`claude-md-management@claude-plugins-official` can be used to audit CLAUDE.md quality and capture learnings; it's a complement, not a replacement, for the per-feature doc reviewer.

## 16) PR merge-conflict awareness

After `pr-creator` opens a PR, `pr-merge-conflict-wait` polls GitHub for mergeability + required checks. PR is not considered "submitted" until mergeable + no failing required checks (or the human acknowledges conflicts and routes to `merge-conflict-resolver`). See `pr-merge-conflict-wait` skill.

For PR review of others' PRs, use `pr-review-toolkit@claude-plugins-official` and `/code-review` from `code-review@claude-plugins-official`.

## 17) Local git hygiene (`.git/info/exclude`)

Untracked files in your working directory are NOT branch-aware — they follow you across branches. Add personal-only patterns to `.git/info/exclude` (handled by the bootstrap for known patterns; see `gitignore-local-hygiene` skill for any new ones you create). NEVER add personal patterns to `.gitignore` — that pushes to the team.

## 18) Environment files

Reading `.env`, `.env.local`, `.env.production`, etc. is allowed so Claude can understand local configuration. Do not edit env/secrets files, paste sensitive values into docs, commit them, or copy them into worktrees without explicit approval. The `new-worktree.sh` wrapper copies them per `.worktreeinclude`; this can be disabled by editing that file.

## 19) Database safety

Treat every database as production-critical. Always wait for explicit confirmation before `INSERT`, `UPDATE`, `DELETE`, `DROP`, `TRUNCATE`, `ALTER`, `CREATE`, `REPLACE`, `MERGE`, `CALL`, migrations, seed scripts, backfills, admin commands, restarts, reindexing, vacuuming, credential rotation, or feature flag mutation.

For DB schema/migration changes, route through `data-architect`. Prefer `LIMIT` for reads. Never fabricate query results.

## 20) Project-specific validation rules (defaults)

These are project-tunable. Each repo should customize via its own `CLAUDE.md` override:

- `app/web/src/**` → `cd app/web && npm run build`
- `src/ephai_intake/**` or `srv/**` → `uv run pytest`
- `schemas/queue-messages.json` → `bash schemas/generate.sh` first
- Images / Dockerfiles modified → build the image before final push
- Never rely on `npm run dev` passing as proof the production build is clean

## 20.5) Graceful degradation when an official plugin isn't installed

Each agent that references an official plugin must check whether it's available before calling its tools. If the plugin is missing, the agent falls back to the documented alternative and **labels the work as degraded**.

**Authoritative fallback table** — single source of truth is `reference/recommended-plugins.json` (each plugin entry has a `fallback_when_missing` field). Summary:

| Missing plugin | Fallback |
|---|---|
| `context7` | WebSearch with `site:docs.<vendor>.com`; cite URLs. |
| `code-review` | Custom `code-reviewer` runs WITHOUT the diff-bug pass; label the unit's review as "partial — `/code-review` not run." |
| `feature-dev` | `codebase-researcher` uses `serena` + grep; greenfield design requires explicit human input. |
| `superpowers` | `assumption-validation-tests` drives pre/post tests locally without red-green-refactor strictness. |
| `github` | Direct `gh` CLI calls; some advanced queries unavailable. |
| `atlassian` | User pastes ticket content manually. |
| `playwright` / `chrome-devtools-mcp` | `frontend-bug-finder` produces a Playwright script for the user to run; cannot capture screenshots / Lighthouse. |
| `serena` | Fall through to `codegraphcontext` / `codeql` / `codanna` / `tree-sitter` / `srclight` MCPs (manual install), or `Grep` / `Glob`. |
| `microsoft-docs` | `context7` with the Microsoft library ID; WebSearch site:learn.microsoft.com. |
| `commit-commands` | Direct `git` invocations; user verifies commit message. |
| `pr-review-toolkit` | `pr-reviewer` does a single-angle review; user runs `/code-review` separately. |
| `claude-md-management` | `documentation-reviewer` scans CLAUDE.md manually. |
| `frontend-design` | `coding-agent` mirrors existing component patterns from the repo. |

**Detection**: each agent should attempt a probe (e.g., a no-op call to a plugin tool) at the start of its run. If the probe fails with "plugin not found" or "tool not registered," the agent logs the fallback choice in its output ("`code-review@claude-plugins-official` not installed; review is partial").

**Probe is not free**: do not probe every plugin on every run. Probe only the plugins the agent is about to use.

## 20.6) Postman MCP

Postman is not yet in the official Anthropic plugin marketplace. Install manually when needed:

```
/mcp add postman <connection-string-from-postman-mcp-docs>
```

Used by: `data-architect` (when designing API contracts), `external-documentation-researcher` (when grounding REST API behavior in existing Postman collections). Falls back to: `context7` or `WebSearch site:postman.com/docs` when not installed.

See `reference/recommended-plugins.json` `additional_mcps_no_plugin_yet` for the canonical list of useful MCPs without official plugins yet.

## 20.7) Workbook path

This plugin uses `docs/ignored/workbooks/<feature-slug>/` for task workbooks (NOT the original `docs/temp/<team>/` path from the requirements). Rationale:

- `docs/ignored/` is already gitignored by the bootstrap; consolidating workbooks there reduces the patterns Git must ignore.
- Slugs are by feature, not team, because a single feature may cross team boundaries.

If a team prefers the original `docs/temp/<team>/` layout, the bootstrap script's `.git/info/exclude` patterns can be extended to include it; the `workbook-management` skill works with either path (it uses the feature-slug subdirectory regardless of parent).

## 21) Plugin / MCP preference

**Prefer plugins over raw MCPs.** A plugin bundles its MCP with auth + skills + commands. If both exist, install the plugin.

The authoritative list of recommended plugins lives in `reference/recommended-plugins.json` (single source of truth). The bootstrap script's `--print-plugins` flag and the install guide both read from that file. Do NOT duplicate the list here — drift between locations was a real problem in v2.

To see the install commands inside Claude Code, run:
```bash
bash bootstrap/install_repo_bootstrap.sh --print-plugins
```

For MCPs without an official plugin yet (Postman, codegraphcontext, tree-sitter, codanna, codeql, srclight), see the `additional_mcps_no_plugin_yet` array in `reference/recommended-plugins.json`.

## 22) Worktree workflow

When creating a worktree:
- Branch is based off the repo's default branch unless human specifies.
- Branch name follows the repo's convention (inspect `CONTRIBUTING.md`, recent branches).
- `docs/ignored/` and `.env*` are copied per `.worktreeinclude`.
- Bootstrap re-runs in the new worktree so it gets Git hooks.
- Dependencies may need reinstalling, virtualenvs recreated, artifacts rebuilt.

## 23) Architecture agent gates the implementation

`architecture-enforcer` runs before approval of any plan AND after each implementation unit. Verdicts:
- `ALIGNED` — proceed
- `DRIFT_ACCEPTABLE_PER_PLAN` — proceed; the plan documents the drift
- `DRIFT_REQUIRES_HUMAN_REVIEW` — stop, escalate
- `BLOCKED` — drift is not justified; revise

## 24) Mobile / remote use

You can use Claude Code from a phone via the Claude.ai mobile app (which has a Claude Code surface in some plans) or by SSH'ing into a remote workstation that runs Claude Code. See the install guide §17 for details. The plugin runs identically in both — agents/skills/hooks operate at the Claude Code level, not at the terminal level.
