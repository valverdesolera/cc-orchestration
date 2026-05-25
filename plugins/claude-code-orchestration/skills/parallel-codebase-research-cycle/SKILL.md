---
name: parallel-codebase-research-cycle
description: Use when codebase research needs to traverse multiple independent areas of a large codebase, with parallel researcher subagents, a consistency reviewer, gap-fill rounds, and final synthesis. Invoked by the orchestrator (main thread); the orchestrator does all subagent dispatching (per CLAUDE.md §25). `parallel-research-coordinator` contributes the per-round plans and the final synthesis but does not itself dispatch. Each researcher writes its own timestamped .md to its area folder.
---

# Parallel codebase research cycle

This procedure is driven by the **orchestrator** (the main-thread agent — the only agent that can dispatch subagents). The `parallel-research-coordinator` subagent contributes decomposition plans, consistency findings, and the final synthesis. The orchestrator runs this skill in its own context and dispatches every subagent the skill calls for. See CLAUDE.md §25 for why this separation is required.

## When to use
- Codebase research that touches >3 distinct modules or areas
- Pre-implementation contextualization for a feature touching multiple subsystems
- Bug investigation where independent layer hypotheses need parallel exploration

## When NOT to use
- Small changes touching 1–2 files (sequential research is fine)
- Areas where one researcher's finding gates another's exploration (must serialize)

## Decomposition rules

Before launching parallel agents, ALWAYS ask:
> "I propose splitting this research into N areas: [list]. Can these be researched in parallel, or do any depend on another's findings?"

If the human says some dependencies exist, serialize those pairs.

## Round structure

```
┌─────────────────────────────────────────────────────────┐
│ Round 1: Decomposition + parallelization approval        │
│   coordinator -> orchestrator: "propose areas A,B,...".  │
│   orchestrator -> human: "ok to run in parallel?"        │
│   human -> orchestrator: "A,B parallel; C after B"       │
├─────────────────────────────────────────────────────────┤
│ Round 2: orchestrator dispatches N codebase-researchers  │
│   each researcher writes:                                │
│     docs/ignored/context/<area>/Research-<ts>.md         │
├─────────────────────────────────────────────────────────┤
│ Round 3: orchestrator dispatches a consistency reviewer  │
│   reviewer reads all per-area files                      │
│   reviewer writes:                                       │
│     docs/ignored/context/<task>/Consistency-<ts>.md      │
├─────────────────────────────────────────────────────────┤
│ Round 4 (conditional): Gap-fill research                 │
│   orchestrator dispatches targeted researchers per gap   │
│   each appends to its area file with a                   │
│   "## Gap-fill <ts>" header                              │
├─────────────────────────────────────────────────────────┤
│ Round 5: Re-review                                       │
│   orchestrator re-dispatches the consistency reviewer    │
│   if converged -> Round 6; else -> Round 4 (max 3x)      │
├─────────────────────────────────────────────────────────┤
│ Round 6: Final synthesis                                 │
│   coordinator emits synthesis content (read-only agent;  │
│   cannot write files itself).  Orchestrator writes to:   │
│     docs/ignored/context/<task>/Final-Synthesis-<ts>.md  │
└─────────────────────────────────────────────────────────┘
```

## Per-researcher file schema

```
# Research: <area>
Researcher: <agent-id>
Timestamp: <ISO-8601>
Task: <coordinator-supplied task name>

## Question
What the coordinator asked this researcher to answer.

## Method
MCPs / commands / search patterns used (e.g., serena, grep, codegraphcontext).

## Files Inspected
List of file paths.

## Findings
The actual content. Use the Module Context File schema if researching a module.

## Open Questions
Things this researcher couldn't resolve in this round.

## Cross-Area Dependencies Spotted
"Area X mentions table Y, which is owned by area B."
```

## Consistency reviewer checklist

- For every pair of areas, are claims consistent?
- For every cross-area dependency one researcher noted, did the other area's researcher document the same thing?
- Are all of the coordinator's original questions answered?
- Are there silent gaps (researcher said "see other file" without that other file documenting it)?

Output format:
```
## Consistency Findings
- Contradiction: area A says X, area B says ¬X. Evidence: ...
- Gap: area A says "see B for handler", area B does not mention handler.
- Unanswered: original question Q3 not addressed by any researcher.

## Verdict
CONVERGED | GAP_FILL_NEEDED | ESCALATE_TO_HUMAN
```

## Hard rules
- Each researcher file is timestamped and never overwritten. Gap-fill rounds append.
- Final synthesis is the only file downstream agents read by default.
- No researcher may claim a fact about an area another researcher owns — they must cite that researcher's file.
- If the consistency reviewer can't converge in 3 gap-fill rounds, escalate.
