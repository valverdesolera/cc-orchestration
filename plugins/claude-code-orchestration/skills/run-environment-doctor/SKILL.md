---
name: run-environment-doctor
description: Manually run the environment doctor in a forked subagent to verify installed plugins, MCP server health, and CLI tool versions against the canonical dependency contract.
disable-model-invocation: true
context: fork
agent: environment-doctor
---

# run-environment-doctor

Run the `environment-doctor` subagent with the following user-supplied context:

```text
$ARGUMENTS
```

Before acting, the subagent must obey `CLAUDE.md`, probe `claude plugin list` + `claude mcp list` + CLI version probes, cross-reference against `reference/recommended-plugins.json`, and report blocking / warning / info findings with exact remediation commands. Do not install or enable anything - diagnose only.
