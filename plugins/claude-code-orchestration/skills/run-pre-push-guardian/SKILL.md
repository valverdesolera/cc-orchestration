---
name: run-pre-push-guardian
description: Manually run the pre-push guardian in a forked subagent before commit or push.
disable-model-invocation: true
context: fork
agent: pre-push-guardian
---

# run-pre-push-guardian

Run the `pre-push-guardian` subagent with the following user-supplied context:

```text
$ARGUMENTS
```

Before acting, the subagent must obey `CLAUDE.md`, use repo/documentation evidence, respect its file mutation boundaries, and report what remains unverified.
