# cc-orchestration

A private engineering orchestration overlay for Claude Code: orchestrator + 23 specialist subagents + 36 skills + 5 guardrail hooks + a custom slash-command. Layered on top of the official Anthropic plugins. Enforces a strict requirements-driven coding cycle with mandatory reviews, assumption-validation tests, comment policy, architecture enforcement, and a meta-architecture-reviewer that audits the plugin itself.

## Install (30 seconds, any OS)

Inside Claude Code:

```
/plugin marketplace add valverdesolera/cc-orchestration
/plugin install claude-code-orchestration@cc-orchestration
/reload-plugins
```

That's it. Verify with `/agents` (should list `engineering-orchestrator` + 23 specialists), `/hooks` (5 hooks), `/mcp` (`context7` + any you've added separately).

## Optional: per-repo overlay

For repos where you also want `docs/ignored/` folders, Git hooks (block AI attribution / env files / private artifacts), and branch/worktree wrappers:

```bash
# In any terminal (Git Bash on Windows), inside the repo you want to overlay:
curl -fsSL https://raw.githubusercontent.com/valverdesolera/cc-orchestration/main/bootstrap/install_repo_bootstrap.sh | bash -s -- --yes
```

Or if you have the repo cloned locally:

```bash
bash ~/cc-orchestration/bootstrap/install_repo_bootstrap.sh --repo /path/to/your/repo --yes
```

The bootstrap is idempotent — safe to re-run.

## Updating

Inside Claude Code, run the two built-in commands:

```
/plugin marketplace update cc-orchestration
/plugin update claude-code-orchestration@cc-orchestration
```

After that, you can verify the result with the custom slash-command shipped by this plugin:

```
/cco-update
```

`/cco-update` is a **verifier**, not an updater — Claude Code's plugin system doesn't allow a custom slash-command to invoke built-in slash-commands. The verifier reads the installed plugin version, the local marketplace HEAD, and the GitHub remote, and reports whether all three agree. If you're out of date it tells you the exact commands to run (the two above).

## What's inside

- **Orchestrator + 23 specialist subagents** — requirements analyst, codebase researcher, planner, coder, code reviewer, architecture enforcer, test agent, doc reviewer, bug finders, PR creator, etc. The orchestrator routes work to specialists and enforces the mandatory feedback loop.
- **36 skills** — codebase contextualization, implementation feedback loop, official-docs-first routing, plan-review-cycle, parallel-codebase-research, root-cause-convergence, assumption-validation-tests, and more.
- **5 guardrail hooks** — block edits to team-visible Claude config, block dangerous git/bash, block MCP mutations without approval, gate agent spawning, enforce post-edit comment policy.
- **CLAUDE.md** — the canonical engineering ruleset, loaded on every Claude Code session start. Covers verification before claiming, no assumptions, official docs first, codebase research first, the implementation feedback loop, parallelization opt-in, greenfield-vs-brownfield, comment + commit + PR policy, database safety, documentation hygiene (canonical per-dependency files), and more.
- **Bootstrap script** — installs only what plugins can't: Git hooks, `.git/info/exclude` entries, `docs/ignored/` folders, branch/worktree wrappers.
- **Meta-architecture-reviewer agent** — audits the plugin itself against the spec.

## Designed to compose with official Anthropic plugins

This plugin uses the following as TOOLS (not replacements) — install them separately for the full experience:

`context7` · `code-review` · `feature-dev` · `superpowers` · `github` · `atlassian` · `playwright` · `chrome-devtools-mcp` · `serena` · `claude-md-management` · `commit-commands` · `claude-code-setup` · `pr-review-toolkit` · `microsoft-docs` · `frontend-design`

To install all of them in one go:

```bash
bash ~/cc-orchestration/bootstrap/install_repo_bootstrap.sh --print-plugins
```

This prints the `/plugin install` commands; paste them into Claude Code one at a time.

## Documentation

- [`docs/INSTALL.md`](docs/INSTALL.md) — detailed install, per-OS notes, troubleshooting, uninstall
- [`docs/REQUIREMENTS_SPEC.md`](docs/REQUIREMENTS_SPEC.md) — full requirements spec (functional requirements, acceptance criteria, traceability matrix, guardrails)
- [`plugins/claude-code-orchestration/CLAUDE.md`](plugins/claude-code-orchestration/CLAUDE.md) — the engineering ruleset loaded into every Claude Code session

## Layout

```
.claude-plugin/marketplace.json            Marketplace manifest (root)
plugins/claude-code-orchestration/
  .claude-plugin/plugin.json               Plugin manifest
  CLAUDE.md                                Engineering ruleset
  agents/                                  24 subagents (orchestrator + 23 specialists)
  skills/                                  36 skills
  commands/                                Custom slash-commands (/cco-update)
  hooks/                                   5 guardrail hooks + hooks.json
  reference/recommended-plugins.json       Single source of truth for plugin deps
  settings.json                            Plugin-level settings (default agent)
  .mcp.json                                Plugin MCP servers
bootstrap/install_repo_bootstrap.sh        Repo-level bootstrap (Git hooks, etc.)
bootstrap/reference/recommended-plugins.json   Mirror of plugin's reference
docs/INSTALL.md (+ .docx, .pdf)            Install guide
docs/REQUIREMENTS_SPEC.md (+ .docx, .pdf)  Requirements spec
.github/workflows/auto-tag.yml             CI: auto-tag on version bump
```

## License

MIT.
