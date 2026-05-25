#!/usr/bin/env bash
set -euo pipefail
json_input="$(cat)"
parsed="$(JSON_INPUT="$json_input" python3 -c 'import json, os
try: data=json.loads(os.environ.get("JSON_INPUT", "{}"))
except Exception: data={}
ti=data.get("tool_input",{}) or {}
agent=data.get("agent_type") or ""
if not agent and isinstance(data.get("agent"),dict): agent=data["agent"].get("name") or data["agent"].get("type") or ""
requested=ti.get("agent_type") or ti.get("subagent_type") or ti.get("type") or ti.get("name") or ""
print(agent); print(requested)' 2>/dev/null || true)"
caller_agent="$(printf '%s\n' "$parsed" | sed -n '1p')"
requested_agent="$(printf '%s\n' "$parsed" | sed -n '2p')"
[[ -z "$requested_agent" ]] && exit 0
block(){ printf '%s\n' "$1" >&2; exit 2; }
prefix="${CLAUDE_OVERLAY_AGENT_PREFIX:-}"
strip(){ local v="$1"; if [[ -n "$prefix" && "$v" == "$prefix"* ]]; then printf '%s' "${v#$prefix}"; else printf '%s' "$v"; fi; }
caller_base="$(strip "$caller_agent")"; requested_base="$(strip "$requested_agent")"
# NOTE: this allowlist MUST track the prose "Allowed specialist agents:" list in
# agents/engineering-orchestrator.md. Drift was a real defect in v3.2.6 — the
# hook silently lacked the 5 agents added in v2 (architecture-enforcer,
# data-architect, comment-policy-checker, parallel-research-coordinator,
# meta-architecture-reviewer) and would have blocked their dispatch had the
# caller-detection logic been populating agent_type at the time.
allowed=' requirements-product-analyst external-documentation-researcher codebase-researcher implementation-planner coding-agent code-reviewer test-agent documentation-reviewer performance-reviewer refactor-cleanup-agent git-version-control-agent merge-conflict-resolver pr-creator pr-reviewer backend-bug-finder frontend-bug-finder pre-push-guardian worktree-manager architecture-enforcer data-architect comment-policy-checker parallel-research-coordinator meta-architecture-reviewer '
case "$caller_base" in
  engineering-orchestrator) [[ "$allowed" == *" $requested_base "* ]] || block "Blocked: orchestrator may spawn only approved specialists. Requested: $requested_agent." ;;
  requirements-product-analyst|external-documentation-researcher|codebase-researcher|implementation-planner|coding-agent|code-reviewer|test-agent|documentation-reviewer|performance-reviewer|refactor-cleanup-agent|git-version-control-agent|merge-conflict-resolver|pr-creator|pr-reviewer|backend-bug-finder|frontend-bug-finder|pre-push-guardian|worktree-manager|architecture-enforcer|data-architect|comment-policy-checker|parallel-research-coordinator|meta-architecture-reviewer) block "Blocked: specialist '$caller_agent' must not spawn nested agents; return a handoff to the orchestrator." ;;
  *) exit 0 ;;
esac
