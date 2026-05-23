---
name: run-backend-bug-finder
description: Manually run the backend bug finder in a forked subagent for backend failures, CI errors, logs, APIs, database issues, or queues.
disable-model-invocation: true
context: fork
agent: backend-bug-finder
---

# run-backend-bug-finder

Run the `backend-bug-finder` subagent with the following user-supplied context:

```text
$ARGUMENTS
```

Before acting, the subagent must obey `CLAUDE.md`, use repo/documentation evidence, respect its file mutation boundaries, and report what remains unverified.
