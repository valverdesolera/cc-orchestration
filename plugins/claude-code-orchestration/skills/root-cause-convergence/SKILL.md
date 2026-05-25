---
name: root-cause-convergence
description: Use for high-impact or uncertain backend/frontend bug investigations where multiple independent investigations should converge before claiming a root cause.
---

# Root Cause Convergence

Use this process when a bug is high impact, production-facing, uncertain, or has competing hypotheses.

1. State the bug symptom and evidence available.
2. Split independent hypotheses or investigation angles by layer: backend, frontend, database, observability, CI, browser reproduction, or integration boundary.
3. The orchestrator dispatches independent finder agents (or an agent team) only when the user approves parallel investigation. Per CLAUDE.md §25 only the main thread can dispatch — a finder agent itself cannot spawn additional finders.
4. Each finder must report evidence, reproduction status, suspected file/function/component, confidence level, and regression test recommendation.
5. Compare findings. If findings converge, report the supported root cause. If findings diverge, do not claim final root cause; ask for human review and collect more evidence.
6. A fix may start only after the root cause is sufficiently evidenced or the human accepts the uncertainty.
7. After the fix, rerun the original reproduction command, failing test, browser flow, CI check, monitoring query, or MCP evidence check when possible.

## Iteration limits

- **Max 3 finder dispatch cycles.** If independent finders still diverge on root cause after 3 rounds of evidence gathering, ESCALATE to human review — further parallel investigation rarely converges and burns tokens. The human decides whether to (a) accept a residual-risk fix, (b) re-scope the investigation, or (c) ship a partial mitigation and continue investigating.
- Each cycle records its evidence and confidence in the workbook so the convergence audit trail is reviewable.
