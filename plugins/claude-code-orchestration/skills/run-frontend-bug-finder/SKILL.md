---
name: run-frontend-bug-finder
description: Manually run the frontend bug finder in a forked subagent for browser/UI/runtime/a11y/visual/performance issues.
disable-model-invocation: true
context: fork
agent: frontend-bug-finder
---

# run-frontend-bug-finder

Run the `frontend-bug-finder` subagent with the following user-supplied context:

```text
$ARGUMENTS
```

Before acting, the subagent must obey `CLAUDE.md`, use repo/documentation evidence, respect its file mutation boundaries, and report what remains unverified.
