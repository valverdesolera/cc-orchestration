#!/usr/bin/env bash
set -euo pipefail
json_input="$(cat)"
parsed="$(JSON_INPUT="$json_input" python3 -c 'import json, os
try: data=json.loads(os.environ.get("JSON_INPUT", "{}"))
except Exception: data={}
ti=data.get("tool_input",{}) or {}
agent=data.get("agent_type") or ""
if not agent and isinstance(data.get("agent"),dict): agent=data["agent"].get("name") or data["agent"].get("type") or ""
if not agent and isinstance(data.get("subagent"),dict): agent=data["subagent"].get("name") or data["subagent"].get("type") or ""
path=ti.get("file_path") or ti.get("notebook_path") or ti.get("path") or ""
print(path); print(agent)' 2>/dev/null || true)"
file_path="$(printf '%s\n' "$parsed" | sed -n '1p')"; agent_type="$(printf '%s\n' "$parsed" | sed -n '2p')"
[[ -z "$file_path" ]] && exit 0
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"; rel_path="$file_path"
case "$rel_path" in "$project_dir"/*) rel_path="${rel_path#$project_dir/}";; ./*) rel_path="${rel_path#./}";; esac
block(){ printf '%s\n' "$1" >&2; exit 2; }
prefix="${CLAUDE_OVERLAY_AGENT_PREFIX:-}"; agent_base="$agent_type"; [[ -n "$prefix" && "$agent_base" == "$prefix"* ]] && agent_base="${agent_base#$prefix}"
case "$rel_path" in .claude/*|CLAUDE.md|.mcp.json) [[ "${CLAUDE_ALLOW_TEAM_CLAUDE_CONFIG_EDIT:-}" == "1" ]] || block "Blocked: private overlay must not edit team-visible Claude Code config ($rel_path).";; esac
case "$rel_path" in .env|.env.*|secrets/*|*/secrets/*|config/secrets.json) [[ "${CLAUDE_ALLOW_ENV_EDIT:-}" == "1" ]] || block "Blocked: reading env/secrets is allowed, but editing requires explicit approval.";; esac
case "$rel_path" in .module-context.md|*/.module-context.md) block "Blocked: use docs/ignored/context/** instead of .module-context.md.";; esac
case "$agent_base" in
  external-documentation-researcher) case "$rel_path" in docs/ignored/*Documentation.md|docs/ignored/workbooks/*|docs/ignored/workbooks/**/*) ;; *) block "Blocked: external-documentation-researcher may write only dependency docs or workbook notes.";; esac;;
  implementation-planner) case "$rel_path" in docs/ignored/implementation/*|docs/ignored/implementation/**/*|docs/ignored/workbooks/*|docs/ignored/workbooks/**/*|docs/ignored/context/*|docs/ignored/context/**/*) ;; *) block "Blocked: implementation-planner may write only docs/ignored planning/context/workbook artifacts.";; esac;;
  codebase-researcher) case "$rel_path" in docs/ignored/context/*|docs/ignored/context/**/*|docs/ignored/workbooks/*|docs/ignored/workbooks/**/*) ;; *) block "Blocked: codebase-researcher may write only docs/ignored/context or workbook notes.";; esac;;
  documentation-reviewer) case "$rel_path" in docs/ignored/*Documentation.md|docs/ignored/context/*|docs/ignored/context/**/*|docs/ignored/workbooks/*|docs/ignored/workbooks/**/*|docs/ignored/implementation/*|docs/ignored/implementation/**/*) ;; *.md|*.markdown) [[ "${CLAUDE_ALLOW_DURABLE_DOC_EDIT:-}" == "1" && "${CLAUDE_ALLOW_MARKDOWN_OUTSIDE_IGNORED:-}" == "1" ]] || block "Blocked: durable committed Markdown edits need explicit override.";; *) block "Blocked: documentation-reviewer should edit only Markdown docs/context/workbooks.";; esac;;
  code-reviewer|backend-bug-finder|frontend-bug-finder|performance-reviewer|pr-reviewer|pre-push-guardian|requirements-product-analyst) block "Blocked: $agent_type is read-only/finder/reviewer scoped.";;
esac
case "$rel_path" in docs/ignored/*.md|docs/ignored/**/*.md|CLAUDE.local.md) exit 0;; *.md|*.markdown) [[ "${CLAUDE_ALLOW_MARKDOWN_OUTSIDE_IGNORED:-}" == "1" ]] || block "Blocked: Markdown docs should be under docs/ignored unless explicitly requested.";; esac
exit 0
