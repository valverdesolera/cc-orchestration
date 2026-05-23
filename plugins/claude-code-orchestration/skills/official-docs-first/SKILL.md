---
name: official-docs-first
description: Use ALWAYS before analyzing, planning a change to, or fixing anything involving a third-party framework, library, SDK, API, CLI, or cloud service. Forces the agent to consult official documentation via the proper MCP/plugin first and ground its claims in cited sources. No claim about external behavior is allowed without a citation.
---

# Official docs first

**Rule, in plain words**: If you're going to make a claim about how a framework, library, API, SDK, CLI, or cloud service works, you must first consult its official documentation through the right plugin/MCP, and cite the source.

This applies to:
- "React batches state updates this way…"
- "Postgres handles this lock like…"
- "AWS S3's strong consistency means…"
- "Next.js middleware runs on the edge runtime…"
- "Stripe's webhook signature uses HMAC-SHA256…"
- Any version-specific behavior of any dependency.

It does NOT apply to:
- Generic computer-science facts ("a hash table has O(1) average lookup").
- The codebase's own code (use `serena`, `codegraphcontext`, `codanna`, or just read it).

## Routing: pick the MOST-SPECIFIC source first

The single most common mistake is reaching for `context7` for everything. It's the GENERIC fallback. If a vendor-specific plugin exists, use it.

| Topic | Use FIRST | Then fall back to |
| --- | --- | --- |
| Microsoft / Azure / .NET / VS Code APIs / TypeScript on MS stack | `microsoft-docs@claude-plugins-official` | context7 → WebSearch (`site:learn.microsoft.com`) |
| Jira / Confluence / Atlassian APIs | `atlassian@claude-plugins-official` | context7 → WebSearch |
| GitHub API / Actions / GraphQL / code scanning | `github@claude-plugins-official` | context7 → WebSearch |
| Web platform / DOM APIs / browser behavior | `chrome-devtools-mcp@claude-plugins-official` + `playwright@claude-plugins-official` | MDN via WebSearch → context7 |
| Any library / framework / SDK with public docs (React, Next.js, Django, Stripe, etc.) | `context7@claude-plugins-official` (version-aware) | vendor MCP if installed → WebSearch |
| Google Cloud / AWS / other vendors without a plugin | Vendor's own MCP if installed (`/mcp add`) | context7 → WebSearch (`site:docs.<vendor>.com`) |
| Postman / API collection lookups | Postman MCP (manual `/mcp add`) | context7 → WebSearch |

**Plugins are preferred over raw MCPs** because they bundle the MCP, auth, and skills together. If both exist, install the plugin.

If you find yourself reaching for context7 for a Microsoft/Azure topic, stop — use `microsoft-docs` instead. The vendor-specific source is more accurate and version-tracked.

## Required output shape

Every external claim must look like:

```
According to <source, with version + URL or plugin tool name>, <claim>.
```

Examples:
- "According to context7 (`/vercel/next.js`, v14 docs, `app/route.ts` page), middleware runs on the edge runtime by default."
- "According to microsoft-docs (`Azure CosmosDB`, partition key article), point reads are O(1) within a partition."

## Procedure

1. Before any claim about external behavior, identify the dependency + version. Get the version from `package.json`, `requirements.txt`, `go.mod`, etc.
2. Pick the right plugin/MCP from the list above.
3. Query for the specific behavior. Capture the URL or tool-call signature you used.
4. Restate the behavior in your own words, with the citation attached.
5. If the docs disagree with the codebase's apparent usage, surface that as a finding — don't paper over it.

## Hard rules

- Never make a claim about a library's behavior from training memory alone.
- If the doc lookup fails (MCP returns nothing, version not indexed, etc.), say so explicitly. Don't fabricate.
- For security-critical behaviors (auth, signing, crypto, ACLs), require TWO sources: official docs + the library's source code (via the plugin's source-link or the project's `node_modules` / equivalent).
- If a fix proposal hinges on a vendor behavior that you couldn't verify, STOP and ask the human.
- "Before proposing any fix" → this skill runs first. The fix proposal must include the citations.

## Where to capture the citations

In the workbook (`docs/ignored/workbooks/<feature>/research.md`) and again in any implementation plan or PR body that depends on the cited behavior. Citations are reproducible evidence; they must survive the workbook-to-long-lived-doc promotion in `documentation-refresh`.
