---
description: Verify your installed cc-orchestration plugin matches the latest version on GitHub, and tell the user the manual update steps if it doesn't.
---

# /cco-update

A verification + reporting command. Confirms whether the installed `claude-code-orchestration` plugin is current vs. what's on GitHub, and surfaces the exact two-step update sequence the user needs to run themselves if it isn't.

## Important: this command does NOT perform the update

Claude cannot programmatically invoke Claude Code's built-in slash-commands (`/plugin marketplace update`, `/plugin update`) from inside a custom slash-command. Those are interactive CLI built-ins. So this command:

- **Reads** the installed plugin version + the marketplace's current commit + the GitHub remote
- **Reports** whether they're aligned
- **Tells the user** exactly what to run if they're out of date

If you want to actually perform the update, run the two manual commands yourself (shown below).

## What to do when this command runs

1. **Read the installed plugin version**: open `~/.claude/plugins/installed_plugins.json` (or the platform-specific equivalent) and locate the `claude-code-orchestration` entry. Extract its version.

2. **Read the marketplace's current commit**: in `~/.claude/plugins/marketplaces/cc-orchestration/`, run `git log -1 --oneline` and read the marketplace.json's `metadata.version`.

3. **Check the GitHub remote**: from the same marketplace directory, run `git fetch origin main --quiet` and `git rev-parse origin/main` to compare against local HEAD. (Public repo, no auth needed.)

4. **Produce a comparison table** showing:
   - Installed plugin version
   - Local marketplace HEAD (commit + version)
   - Remote `origin/main` (commit)
   - Whether all three agree

5. **If everything matches**: report "up to date" and stop. Optionally mention the most recent release notes (read from the v3.2 / v3.2.1 / etc. changes summary in the marketplace's REQUIREMENTS_SPEC.md or the latest tag annotation).

6. **If the installed version is older than the marketplace**, OR the marketplace is older than origin: instruct the user to run, exactly:
   ```
   /plugin marketplace update cc-orchestration
   /plugin update claude-code-orchestration@cc-orchestration
   ```
   And explain that if the first command reports "unknown command" (older Claude Code versions), to fall back to the full uninstall + re-add + reinstall sequence:
   ```
   /plugin uninstall claude-code-orchestration@cc-orchestration
   /plugin marketplace remove cc-orchestration
   /plugin marketplace add valverdesolera/cc-orchestration
   /plugin install claude-code-orchestration@cc-orchestration
   /reload-plugins
   ```

7. **Always remind**: `/cco-update` only verifies and instructs — the user must run the actual update commands themselves.

## Notes

- This command does NOT cover the official Anthropic plugins (`context7`, `code-review`, etc.). Those follow their own update cycle via `claude-plugins-official`. Their update is `/plugin marketplace update claude-plugins-official` plus `/plugin update <name>@claude-plugins-official` for each, run by the user.
- This command does NOT re-run the per-repo bootstrap. If the bootstrap script itself changed across versions, the user should re-run `bash ~/cc-orchestration/bootstrap/install_repo_bootstrap.sh --yes` from inside each repo they want refreshed. The bootstrap is idempotent.
- If the user pointed the marketplace at a local clone path (`/plugin marketplace add ~/cc-orchestration` instead of `valverdesolera/cc-orchestration`), they should also `cd ~/cc-orchestration && git pull` before the marketplace update so the local clone reflects GitHub. The GitHub URL form does this automatically; the local-path form does not.

## Why not have this command perform the update directly?

I tried. Claude Code's slash-command system doesn't expose a way for one custom command to call another (or to call a built-in `/plugin` command). The alternative — having Claude shell out to manipulate `~/.claude/plugins/` directly via bash — is fragile, depends on Claude Code internals that may change between versions, and is exactly the kind of work the built-in `/plugin update` does correctly. Keeping this command as verifier-only is the honest design: it tells you what to do without pretending to do it.
