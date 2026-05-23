---
name: plan-folder-organization
description: Use whenever a new feature or change is started. Defines the folder layout for `docs/ignored/implementation/<feature>/` so plans, reviews, research, and progress for different features never get tangled. Every feature gets its own sub-folder.
---

# Plan folder organization

Every feature or change gets its own folder. Plans, reviews, research, workbooks, and the activity log all live under that folder. Never mix two features into one folder.

## Folder layout per feature

```
docs/ignored/
├── implementation/
│   └── <feature-slug>/                       ← one folder per feature
│       ├── README.md                          ← metadata + activity log + index
│       ├── Requirements.md                    ← from requirements-product-analyst
│       ├── Plan-v1.md
│       ├── Plan-v2.md                         ← after plan-review-cycle round 3
│       ├── Plan-Final.md                      ← only after convergence
│       ├── Review-1-requirements-<ts>.md
│       ├── Review-1-architecture-<ts>.md
│       ├── Review-1-feasibility-<ts>.md
│       ├── Review-Consolidated-1-<ts>.md
│       ├── Review-2-*.md ...
│       ├── Parallelization-<ts>.md           ← from parallelization-decision
│       ├── Limitations.md                     ← framework/library/version caveats
│       ├── EdgeCases.md
│       ├── Stages/
│       │   ├── Stage-1-<title>.md
│       │   ├── Stage-2-<title>.md
│       │   └── ...
│       ├── Progress.md                        ← updated after each stage
│       └── PostMortem.md                      ← after feature ships, lessons learned
├── workbooks/
│   └── <feature-slug>/                        ← mirror name, holds transient stuff
│       ├── research.md
│       ├── design.md
│       ├── handoff.md
│       ├── notes.md
│       └── README.md (activity log)
└── context/
    └── <module>/                              ← shared across features
        └── <Module>Context-<ts>.md
```

## Feature slug rules

- Use kebab-case.
- DO NOT use the ticket ID, branch name, or any team-internal identifier.
  - Good: `oauth-login`, `db-migration-v3`, `pdf-export`
  - Bad: `dprd-3519`, `feature-dprd-3519-oauth`, `JIRA-1234-fix`
- The reason: the slug appears in commit-adjacent areas. Including the ticket ID risks it leaking into a comment or commit message.

## README.md schema

```markdown
# <Feature>
Status: planning | implementing | review | done
Created: <ts>
Last updated: <ts>
Mode: greenfield | brownfield | mixed
Final plan: Plan-Final.md (or "in review")

## Activity Log
| Date | Agent | Action |
| --- | --- | --- |

## Files
- Requirements.md
- Plan-Final.md
- Stages/
- (etc.)

## Cross-references
- Module Context Files touched: ...
- Workbook: docs/ignored/workbooks/<feature-slug>/
```

## When two features overlap

If a new feature overlaps with an in-flight feature:
1. Do not mix files. Create a new folder for the new feature.
2. In each `README.md`, add a `Cross-references` line pointing at the other.
3. Use `parallelization-decision` to determine whether they can be worked on in parallel or whether one must wait.

## Cleanup
- After a feature ships and the PostMortem is written, the folder is archived (move to `docs/ignored/implementation/_archive/<feature-slug>/`).
- Never delete — audit trail.
