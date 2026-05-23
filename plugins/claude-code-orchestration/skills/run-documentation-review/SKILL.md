---
name: run-documentation-review
description: Manually run the documentation reviewer in a forked subagent to check or refresh docs after code, dependency, or workbook changes.
disable-model-invocation: true
context: fork
agent: documentation-reviewer
---

# run-documentation-review

Run the `documentation-reviewer` subagent with the following user-supplied context:

```text
$ARGUMENTS
```

Before acting, the subagent must obey `CLAUDE.md`, use repo/documentation evidence, respect its file mutation boundaries, and report what remains unverified.
