---
name: agent-team-decision
description: Use before choosing subagents, agent view, agent teams, or worktrees
  for parallel Claude Code work.
---
# Agent Team Decision

Use this decision checklist before starting parallel Claude Code work.

## Prefer subagents when

- The task is focused and only the result matters.
- The work would flood the main context with search results, logs, or file contents.
- The worker should have restricted tools or permissions.
- Communication only needs to flow back to the main agent.
- Work is sequential: research, then plan, then code, then review, then tests.

## Prefer agent view when

- The human wants several independent Claude Code sessions to run in the background.
- Tasks do not need direct communication with each other.
- Each session may be monitored, renamed, attached to, or stopped separately.
- Independent bug investigation, PR review, and feature planning can run in parallel.

## Prefer agent teams when

- Teammates need to message each other directly or share a task list.
- Multiple hypotheses should be tested in parallel and challenged against each other.
- The change spans independent frontend, backend, test, documentation, or infrastructure areas.
- New modules or features can be split so each teammate owns a separate area without file conflicts.

## Avoid agent teams when

- The work is simple, sequential, same-file-heavy, or strongly dependent step by step.
- The main goal is to save tokens or reduce overhead.
- The team cannot operate independently.
- The user has not explicitly approved using experimental agent teams.

## Required cautions

- Agent teams are experimental and disabled by default. Confirm the user wants them enabled before using them.
- Agent teams use more tokens because each teammate is a separate Claude instance.
- Only one team can run per lead at a time. Do not create nested teams.
- If a teammate uses a subagent definition, the definition's `skills` and `mcpServers` frontmatter do not apply to the teammate. Confirm required skills and MCP servers are available through project/user settings.
- Give teammates clear names, file ownership boundaries, expected outputs, and validation requirements.
- Avoid overlapping same-file edits. Use worktrees or clear ownership boundaries when editing in parallel.

## Root-cause convergence use case

For high-impact or uncertain bugs, agent teams or multiple independent subagents can be useful when different teammates can test separate hypotheses or layers. Use this only when the user approves the parallel strategy. Compare evidence before claiming a root cause. If findings diverge, report the conflict instead of forcing a conclusion.
