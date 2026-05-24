---
description: One-step update for the cc-orchestration plugin (refreshes marketplace + updates installed plugin in one shot).
---

# /cco-update

Pull the latest version of `claude-code-orchestration` from the `cc-orchestration` marketplace and re-install it. Wraps the two-step manual flow (`/plugin marketplace update` then `/plugin update`) into one.

## What to do when this command runs

1. Run `/plugin marketplace update cc-orchestration` to refresh the marketplace's cached view of the GitHub repo. This is what triggers the underlying `git pull`.
2. Run `/plugin update claude-code-orchestration@cc-orchestration` to update the installed plugin to whatever version the marketplace now points to.
3. After both succeed, report back with:
   - The new installed version (read from the plugin's metadata)
   - Any version-change notes available in the marketplace.json or plugin.json metadata
   - A reminder to run `/reload-plugins` if any agents, skills, or hooks were added or removed in this update (otherwise reload is not required)

## Fallback if the marketplace update command is unavailable

Some older Claude Code versions do not support `/plugin marketplace update`. If that command errors with "unknown command" or similar, fall back to:

1. `/plugin uninstall claude-code-orchestration@cc-orchestration`
2. `/plugin marketplace remove cc-orchestration`
3. `/plugin marketplace add valverdesolera/cc-orchestration`
4. `/plugin install claude-code-orchestration@cc-orchestration`

Report which path was used.

## Notes

- This command does NOT update the official Anthropic plugins (`context7`, `code-review`, etc.). Those follow their own update cycle via `claude-plugins-official`. To update everything in one go, also run `/plugin marketplace update claude-plugins-official` and update each official plugin individually.
- This command does NOT re-run the per-repo bootstrap. If the bootstrap script itself was updated (which can happen across versions), the user should re-run `bash ~/cc-orchestration/bootstrap/install_repo_bootstrap.sh --yes` from inside each repo they want refreshed. The bootstrap is idempotent.
- If the user is on a machine where they cloned `~/cc-orchestration` locally and pointed the marketplace at the clone path (`/plugin marketplace add ~/cc-orchestration`), they should also run `cd ~/cc-orchestration && git pull` BEFORE `/cco-update` so the marketplace sees the latest commits.
