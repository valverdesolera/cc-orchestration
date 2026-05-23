#!/usr/bin/env bash
set -euo pipefail

json_input="$(cat)"
tool_name="$(JSON_INPUT="$json_input" python3 -c 'import json, os
try:
    data=json.loads(os.environ.get("JSON_INPUT", "{}"))
except Exception:
    data={}
print(data.get("tool_name") or data.get("tool") or "")' 2>/dev/null || true)"
[[ -z "$tool_name" ]] && exit 0
[[ "$tool_name" != mcp__* ]] && exit 0

block() { printf '%s\n' "$1" >&2; exit 2; }
server_tool="${tool_name#mcp__}"
server="${server_tool%%__*}"
tool="${server_tool#*__}"
tool_lower="$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]')"

case "$tool_lower" in
  get*|list*|read*|search*|fetch*|find*|view*|inspect*|describe*|query*|select*|status*|log*|trace*|metric*|schema*|diff*)
    exit 0
    ;;
esac

if [[ "${CLAUDE_ALLOW_MCP_MUTATION:-}" != "1" ]]; then
  if printf '%s' "$tool_lower" | grep -Eiq '(create|update|delete|write|mutate|merge|close|reopen|comment|approve|deploy|trigger|execute|run|insert|alter|drop|truncate|call|replace|publish|send|post|put|patch|commit|push|rebase|reset|restart|remove|archive|unarchive|assign|label)'; then
    block "Blocked by Claude Code MCP mutation guard: MCP tool ${tool_name} appears to mutate external state on server '${server}'. Ask for explicit human approval and set CLAUDE_ALLOW_MCP_MUTATION=1 outside Claude Code for a confirmed safe call."
  fi
fi
exit 0
