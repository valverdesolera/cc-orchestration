# reference/

Machine-readable lookups referenced from CLAUDE.md, agents, and skills.

CLAUDE.md is the **narrative authority** — it contains the rules and the rationale.
`reference/` files are **single-source-of-truth indexes** that agents consult when they
need a structured lookup (e.g., "which plugin should I use for Microsoft docs?").

| File | Used by | Purpose |
|---|---|---|
| `recommended-plugins.json` | bootstrap (`--print-plugins`), CLAUDE.md §21, `plugin.json` `_recommendedPlugins`, INSTALL.md §3.1, all agents' fallback decisions | The 15 official plugins + their fallback behavior when not installed |

Rules:
- Anything in `reference/` is data, not policy.
- If a rule in CLAUDE.md contradicts a value in `reference/`, CLAUDE.md wins. Update the reference file to match.
- Adding a new reference file requires updating this README.
