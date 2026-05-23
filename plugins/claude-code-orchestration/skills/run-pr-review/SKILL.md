---
name: run-pr-review
description: Manually run the PR reviewer in a forked subagent for a branch or pull request.
disable-model-invocation: true
context: fork
agent: pr-reviewer
---

# run-pr-review

Run the `pr-reviewer` subagent with the following user-supplied context:

```text
$ARGUMENTS
```

Before acting, the subagent must obey `CLAUDE.md`, use repo/documentation evidence, respect its file mutation boundaries, and report what remains unverified.
