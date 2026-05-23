---
name: documentation-refresh
description: Use after implementation or review to find stale, missing, duplicated, or incorrect Markdown documentation under docs/ignored and to promote durable facts from temporary workbooks.
---

# Documentation Refresh

## Scope

- Create or update dependency/integration documentation under `docs/ignored/<CanonicalName>Documentation.md`.
- Before creating a new file, check whether the canonical documentation file already exists.
- Do not create multiple docs for the same service, framework, SDK, API, database, or platform unless the human explicitly asks.
- Durable committed docs outside `docs/ignored/` may be updated only when the human explicitly requested committed documentation.
- Temporary docs under `docs/ignored/**`, workbooks, implementation-stage plans, and codebase context snapshots are not committed. Do not create or update `.module-context.md`; use `docs/ignored/context/**`.

## Required contents

Each `<CanonicalName>Documentation.md` should contain only verified, current, non-conflicting information relevant to that dependency or integration:

- what it is and why this repo uses it
- verified versions, API versions, SDK versions, platform versions, endpoints, interface signatures, config keys, and commands
- official documentation or MCP sources used for verification
- capabilities verified
- constraints, limitations, gotchas, edge cases, and security requirements
- repo integration points with file paths and modules
- architectural decisions and why they were made

## Process

1. Inspect changed files, implementation-stage notes, and workbooks.
2. Check existing `docs/ignored/*Documentation.md` files before creating any new documentation file.
3. Use MCPs and Context7 when relevant, then official documentation and repo evidence.
4. Rewrite stale sections instead of appending contradictory notes.
5. Remove outdated, duplicate, or conflicting content.
6. Treat workbook content as evidence, not authority. Re-verify workbook facts against current code, current external documentation/MCP evidence, and confirmed requirements before promoting them.
7. Promote only durable, reviewed facts from workbooks.
8. Ask the human when docs conflict with code, verified external documentation, or requirements.

## Output

- Documentation files created or updated.
- Summary of documentation changes.
- Stale or duplicate docs removed or cleaned.
- Docs intentionally left unchanged and why.
- Any unresolved contradictions.
