# cc-orchestration

Claude Code orchestration plugin + repo bootstrap.

## Quick start

Inside Claude Code:
```
/plugin marketplace add <github-owner>/cc-orchestration
/plugin install claude-code-orchestration@cc-orchestration
/reload-plugins
```

Outside Claude Code, once per repo:
```bash
bash bootstrap/install_repo_bootstrap.sh --repo /path/to/your/repo
```

For details: see `docs/INSTALL.md` (also available as `docs/INSTALL.docx`).
For requirements: see `docs/REQUIREMENTS_SPEC.md` (also `.docx`).

## Layout
- `marketplace/` — the Claude Code marketplace (push this to GitHub)
- `bootstrap/install_repo_bootstrap.sh` — repo-level bootstrap (Git hooks, docs/ignored, wrappers)
- `docs/INSTALL.md` + `.docx` — install guide
- `docs/REQUIREMENTS_SPEC.md` + `.docx` — engineering spec
