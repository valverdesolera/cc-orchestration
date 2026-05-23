#!/usr/bin/env bash
# install_repo_bootstrap.sh
#
# Repo-level bootstrap for the claude-code-orchestration plugin.
# Installs ONLY the things a Claude Code plugin cannot install on its own:
#   - Git hooks (pre-commit, commit-msg, pre-push) that block Claude/AI attribution,
#     env files, private artifacts, and docs/ignored content from being committed/pushed.
#   - docs/ignored/ folders for workbooks, context snapshots, implementation plans.
#   - .git/info/exclude entries so docs/ignored and other private files stay local.
#   - .worktreeinclude so worktrees know to copy docs/ignored and .env*.
#   - Branch / worktree wrapper scripts (~/.local/share/cc-orchestration/).
#
# What this DOES NOT install (because the plugin handles it):
#   - Agents, skills, Claude Code hooks, MCP servers, plugin CLAUDE.md.
#   Install those via:  /plugin install claude-code-orchestration@cc-orchestration
#
# Safe to re-run. Idempotent.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --repo /path/to/repo [--state-dir DIR] [--no-git-hooks] [--no-wrappers] [--yes]

Required:
  --repo PATH         Path to your local git repository.

Optional:
  --state-dir PATH    Where wrapper scripts + git-hook templates live.
                      Default: \$HOME/.local/share/cc-orchestration
  --no-git-hooks      Skip installing Git hooks (still creates docs/ignored, .git/info/exclude).
  --no-wrappers       Skip installing new-branch.sh / new-worktree.sh wrappers.
  --print-plugins     Print the /plugin install commands to run inside Claude Code, then exit.
                      (Use this without --repo. Plugins must be installed from inside Claude Code.)
  --yes, -y           Skip interactive confirmation.
  --help, -h          Show this help.

Examples:
  $0 --repo ~/work/myrepo
  $0 --repo ~/work/myrepo --yes
  $0 --print-plugins                  # show the /plugin install commands
EOF
}

repo=""
state_dir="${HOME}/.local/share/cc-orchestration"
install_git_hooks=1
install_wrappers=1
print_plugins=0
yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --state-dir) state_dir="${2:-}"; shift 2 ;;
    --no-git-hooks) install_git_hooks=0; shift ;;
    --no-wrappers) install_wrappers=0; shift ;;
    --print-plugins) print_plugins=1; shift ;;
    --yes|-y) yes=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

# --print-plugins runs without --repo
# Reads the single source of truth (bootstrap/reference/recommended-plugins.json)
# so this list cannot drift from CLAUDE.md / plugin.json / INSTALL.md.
if [[ "$print_plugins" == 1 ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ref_json="$script_dir/reference/recommended-plugins.json"
  if [[ ! -f "$ref_json" ]]; then
    echo "ERROR: $ref_json not found." >&2
    echo "Expected location: bootstrap/reference/recommended-plugins.json" >&2
    exit 1
  fi
  python3 - "$ref_json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
print('# Recommended plugins (run these from inside Claude Code)')
print(f'# Source: {sys.argv[1]}')
print(f'# Plugin spec version: {d["version"]}')
print('')
print(d['marketplace']['add_command'])
for p in d['plugins']:
    note = '' if not p.get('optional') else '   # optional'
    print(f'/plugin install {p["name"]}@{d["marketplace"]["name"]}{note}')
print('/reload-plugins')
print('')
print('# Plus this plugin (cc-orchestration) - replace <github-owner>:')
print('/plugin marketplace add <github-owner>/cc-orchestration')
print('/plugin install claude-code-orchestration@cc-orchestration')
print('')
print('# Additional MCPs (no plugin yet; install manually if needed):')
for m in d['additional_mcps_no_plugin_yet']:
    print(f'#   - {m["name"]}: {m["purpose"]}')
    print(f'#     Install: {m["install"]}')
PYEOF
  exit 0
fi

[[ -n "$repo" ]] || { usage; exit 1; }

repo="$(cd "$repo" && pwd)"
git -C "$repo" rev-parse --show-toplevel >/dev/null \
  || { echo "Not a git repository: $repo" >&2; exit 1; }
repo_root="$(git -C "$repo" rev-parse --show-toplevel)"

if [[ "$yes" != 1 ]]; then
  echo "About to bootstrap repo: $repo_root"
  echo "State directory:         $state_dir"
  [[ "$install_git_hooks" == 1 ]] && echo "  - install Git hooks: yes" || echo "  - install Git hooks: no"
  [[ "$install_wrappers" == 1 ]] && echo "  - install branch/worktree wrappers: yes" || echo "  - install branch/worktree wrappers: no"
  echo "This will NOT modify .claude/, CLAUDE.md, or .mcp.json in the repo."
  read -r -p "Continue? [y/N] " r
  [[ "$r" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

mkdir -p "$state_dir" "$state_dir/git-hooks-template"

# ---------------------------------------------------------------------------
# 1) docs/ignored/ folders inside the repo (NOT committed; covered by exclude)
# ---------------------------------------------------------------------------
mkdir -p \
  "$repo_root/docs/ignored/implementation" \
  "$repo_root/docs/ignored/workbooks" \
  "$repo_root/docs/ignored/context"

# ---------------------------------------------------------------------------
# 2) .git/info/exclude — local, not committed
# ---------------------------------------------------------------------------
exclude_file="$(git -C "$repo_root" rev-parse --git-path info/exclude)"
mkdir -p "$(dirname "$exclude_file")"
touch "$exclude_file"

add_exclude() {
  local pattern="$1"
  grep -qxF "$pattern" "$exclude_file" 2>/dev/null || echo "$pattern" >> "$exclude_file"
}

# Patterns to keep local-only:
add_exclude "/docs/ignored/"
add_exclude "/CLAUDE.local.md"
add_exclude "/.worktreeinclude"
add_exclude "/.claude-personal/"
add_exclude "/claude_code_architecture_pack*.zip"
add_exclude "/claude_code_private_overlay*.zip"
add_exclude "/Claude_Code_Private_Overlay*.pdf"
add_exclude "/Claude_Code_Private_Overlay*.docx"
add_exclude "/Claude_Code_Improvements*.pdf"
add_exclude "/cc-orchestration*.zip"

# ---------------------------------------------------------------------------
# 3) .worktreeinclude — drives what new-worktree.sh copies into worktrees
# ---------------------------------------------------------------------------
if [[ ! -f "$repo_root/.worktreeinclude" ]]; then
  cat > "$repo_root/.worktreeinclude" <<'WTI'
# Paths copied into new worktrees by new-worktree.sh (one per line, gitignore-style).
# These should normally be in .git/info/exclude already so they never get committed.
docs/ignored/
.env
.env.*
.envrc
WTI
fi

# ---------------------------------------------------------------------------
# 4) Git hooks
# ---------------------------------------------------------------------------
if [[ "$install_git_hooks" == 1 ]]; then
  hooks_dir="$state_dir/git-hooks-template"
  mkdir -p "$hooks_dir"

  cat > "$hooks_dir/pre-commit" <<'HOOK'
#!/usr/bin/env bash
# Blocks Claude/private artifacts, env files, AND comments containing
# ticket IDs / branch names / implementation plan references / AI attribution
# inside the source code being committed.
set -euo pipefail
[[ "${ALLOW_CLAUDE_ARTIFACT_COMMIT:-0}" == "1" ]] && exit 0

blocked_regex='(^|/)(docs/ignored/|CLAUDE\.local\.md$|CLAUDE\.md$|\.worktreeinclude$|\.mcp\.json$|\.claude/|\.claude-personal/|claude_code_architecture_pack.*\.zip$|claude_code_private_overlay.*\.zip$|Claude_Code_Private_Overlay.*\.(pdf|docx)$|cc-orchestration.*\.zip$|APPLY_TO_REPO\.txt$|claude-code\.gitignore\.append$)'

blocked="$(git diff --cached --name-only | grep -E "$blocked_regex" || true)"
if [[ -n "$blocked" ]]; then
  echo "Blocked Claude/private artifacts from commit:" >&2
  echo "$blocked" >&2
  echo "If this is intentional, re-run with ALLOW_CLAUDE_ARTIFACT_COMMIT=1." >&2
  exit 1
fi

env_files="$(git diff --cached --name-only | grep -E '(^|/)\.env($|\.)' || true)"
if [[ -n "$env_files" && "${ALLOW_ENV_COMMIT:-0}" != "1" ]]; then
  echo "Blocked env files from commit:" >&2
  echo "$env_files" >&2
  echo "If this is intentional, re-run with ALLOW_ENV_COMMIT=1." >&2
  exit 1
fi

# Scan staged source diffs for forbidden process metadata in code comments.
# Matches: ticket IDs (Jira-style), implementation plan/stage/phase refs,
# plan filenames, branch-name patterns in source, AI/Claude attribution.
# Skip binary files, docs, lock files.
forbidden_in_code='(\b[A-Z]{2,10}-[0-9]{2,6}\b|ImplementationStep|implementation stage|implementation plan|docs/ignored|workbook|\bphase [0-9]+\b|\bstage [0-9]+\b|Plan(-v[0-9]+|-Final)?\.md|Stage-[0-9]+-[A-Za-z0-9_-]+\.md|see (the )?ticket|per the plan|per the (stage|phase)|(feature|fix|chore|hotfix|release|bugfix)/[A-Za-z0-9_-]+|Claude Code|Co-authored-by.*(claude|anthropic)|AI-generated|generated by Claude|generated by AI|🤖|🧠)'

# We only check added/modified lines in non-doc source files.
violations=""
while IFS= read -r f; do
  # Skip docs, locks, JSON, binaries
  case "$f" in
    *.md|*.markdown|*.txt|*.json|*.lock|*.svg|*.png|*.jpg|*.jpeg|*.gif|*.pdf|*.docx|*.xlsx|docs/ignored/*|docs/temp/*) continue ;;
  esac
  diff_lines="$(git diff --cached -U0 -- "$f" 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
  matched="$(printf '%s\n' "$diff_lines" | grep -inE "$forbidden_in_code" || true)"
  if [[ -n "$matched" ]]; then
    violations+="${f}:\n${matched}\n\n"
  fi
done < <(git diff --cached --name-only --diff-filter=AM)

if [[ -n "$violations" && "${ALLOW_COMMENT_POLICY_BYPASS:-0}" != "1" ]]; then
  printf 'Blocked: source-code comment policy violation. Code must not reference tickets, branches, plans, stages, or AI attribution.\n' >&2
  printf '%b' "$violations" >&2
  printf 'If a match is a legitimate string literal (not a comment), set ALLOW_COMMENT_POLICY_BYPASS=1 for this commit.\n' >&2
  exit 1
fi
HOOK

  cat > "$hooks_dir/commit-msg" <<'HOOK'
#!/usr/bin/env bash
# Blocks Claude/AI attribution AND implementation-plan / stage / branch refs in commit messages.
# Allowed: ticket-ID trailers if the repo convention requires them (Refs: ABC-123, Closes: #42).
# We block plan/stage references and AI attribution unconditionally.
set -euo pipefail
msg_file="$1"
content="$(cat "$msg_file")"

# AI attribution patterns
if printf '%s' "$content" | grep -Eiq '(co-authored-by:.*(claude|anthropic|gpt|copilot)|generated with (claude|ai|gpt)|claude code|ai-generated|generated by ai|🤖|🧠)'; then
  echo "Blocked: Claude/AI attribution in commit message." >&2
  exit 1
fi

# Implementation plan / stage / phase / workbook references in commit body
if printf '%s' "$content" | grep -Eiq '(implementation plan|implementation stage|docs/ignored|workbook|Plan-v[0-9]+\.md|Plan-Final\.md|Stage-[0-9]+-[A-Za-z0-9_-]+\.md|per the plan|see the plan|see the workbook|per the (stage|phase)|as per (stage|phase))'; then
  echo "Blocked: commit message references implementation plans, stages, phases, or workbooks. Commit messages must describe the change, not the process." >&2
  exit 1
fi

# Long branch-name patterns inside the message body (not allowed; the branch is in the git command, not the message)
# We allow short refs like #123 or 'Refs: ABC-123' but flag full branch names.
if printf '%s' "$content" | grep -Eq '(^|[[:space:]])(feature|fix|chore|hotfix|release|bugfix)/[A-Za-z0-9_-]+'; then
  echo "Blocked: commit message contains a full branch name. Remove it." >&2
  exit 1
fi
HOOK

  cat > "$hooks_dir/pre-push" <<'HOOK'
#!/usr/bin/env bash
# Scans all outgoing commits for Claude/private artifacts and AI attribution.
set -euo pipefail
blocked_regex='(^|/)(docs/ignored/|CLAUDE\.local\.md$|CLAUDE\.md$|\.worktreeinclude$|\.mcp\.json$|\.claude/|\.claude-personal/|claude_code_architecture_pack.*\.zip$|claude_code_private_overlay.*\.zip$|Claude_Code_Private_Overlay.*\.(pdf|docx)$|cc-orchestration.*\.zip$|APPLY_TO_REPO\.txt$|claude-code\.gitignore\.append$)'
zero='0000000000000000000000000000000000000000'

while read -r local_ref local_sha remote_ref remote_sha; do
  [[ "$local_sha" == "$zero" ]] && continue
  if [[ "$remote_sha" == "$zero" ]]; then
    range="$local_sha"
  else
    range="$remote_sha..$local_sha"
  fi
  files="$(git log --name-only --format='' "$range" | sed '/^$/d' | sort -u || true)"
  blocked="$(printf '%s\n' "$files" | grep -E "$blocked_regex" || true)"
  if [[ -n "$blocked" ]]; then
    echo "Blocked push: Claude/private artifacts found in outgoing commits:" >&2
    echo "$blocked" >&2
    exit 1
  fi
  if git log --format='%B' "$range" | grep -Eiq '(co-authored-by:.*(claude|anthropic)|generated with claude|claude code|ai-generated|generated by ai|🤖|🧠)'; then
    echo "Blocked push: Claude/AI attribution found in outgoing commits." >&2
    exit 1
  fi
done
HOOK

  chmod +x "$hooks_dir"/pre-commit "$hooks_dir"/commit-msg "$hooks_dir"/pre-push

  # Configure core.hooksPath only if it isn't already set to something else.
  existing="$(git -C "$repo_root" config --get core.hooksPath || true)"
  if [[ -z "$existing" || "$existing" == "$hooks_dir" ]]; then
    git -C "$repo_root" config core.hooksPath "$hooks_dir"
    echo "Configured git core.hooksPath -> $hooks_dir"
  else
    echo "WARNING: core.hooksPath already set to '$existing'. Not overriding." >&2
    echo "         To use this bootstrap's hooks: git -C '$repo_root' config core.hooksPath '$hooks_dir'" >&2
  fi
fi

# ---------------------------------------------------------------------------
# 5) Branch + worktree wrapper scripts
# ---------------------------------------------------------------------------
if [[ "$install_wrappers" == 1 ]]; then
  cat > "$state_dir/new-branch.sh" <<'WRAP'
#!/usr/bin/env bash
# new-branch.sh <branch-name> [base-ref]
# Creates a branch from origin/<default-branch> by default.
set -euo pipefail
branch="${1:?Usage: new-branch.sh <branch-name> [base-ref]}"
base="${2:-}"
repo="$(git rev-parse --show-toplevel)"
cd "$repo"
if [[ -z "$base" ]]; then
  default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
  [[ -z "$default_branch" ]] && default_branch=main
  base="origin/$default_branch"
fi
git fetch origin
git switch -c "$branch" "$base"
WRAP

  cat > "$state_dir/new-worktree.sh" <<'WRAP'
#!/usr/bin/env bash
# new-worktree.sh <branch-name> <path> [base-ref]
# Creates a worktree from origin/<default-branch>, copies docs/ignored and .env*
# according to .worktreeinclude, and runs install_repo_bootstrap.sh in the new tree.
set -euo pipefail
branch="${1:?Usage: new-worktree.sh <branch-name> <path> [base-ref]}"
path="${2:?path required}"
base="${3:-}"
repo="$(git rev-parse --show-toplevel)"
cd "$repo"
if [[ -z "$base" ]]; then
  default_branch="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
  [[ -z "$default_branch" ]] && default_branch=main
  base="origin/$default_branch"
fi
git fetch origin
git worktree add -b "$branch" "$path" "$base"

# Copy paths listed in .worktreeinclude (gitignore-style; lines starting with # are comments).
if [[ -f "$repo/.worktreeinclude" ]]; then
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    if [[ "$pattern" == */ ]]; then
      # Directory pattern
      src="$repo/${pattern%/}"
      dst="$path/${pattern%/}"
      [[ -d "$src" ]] && { mkdir -p "$dst"; rsync -a --ignore-existing "$src/" "$dst/"; }
    else
      # Glob pattern; copy matching files
      shopt -s nullglob
      for f in "$repo"/$pattern; do
        [[ -f "$f" ]] && cp -n "$f" "$path/" || true
      done
      shopt -u nullglob
    fi
  done < "$repo/.worktreeinclude"
fi

# Run bootstrap in the new worktree so it gets the same Git hooks + excludes.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "$script_dir/../install_repo_bootstrap.sh" ]]; then
  "$script_dir/../install_repo_bootstrap.sh" --repo "$path" --yes
fi
WRAP

  chmod +x "$state_dir/new-branch.sh" "$state_dir/new-worktree.sh"

  # Convenience: drop a symlink to install_repo_bootstrap.sh next to the wrappers.
  script_self="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install_repo_bootstrap.sh"
  [[ -f "$script_self" ]] && cp -f "$script_self" "$state_dir/install_repo_bootstrap.sh"
fi

echo ""
echo "Repo bootstrap complete."
echo "  Repo:        $repo_root"
echo "  State dir:   $state_dir"
echo ""
echo "Next steps:"
echo "  1. Inside Claude Code, add the marketplace and install the plugin:"
echo "       /plugin marketplace add <github-owner>/cc-orchestration"
echo "       /plugin install claude-code-orchestration@cc-orchestration"
echo "  2. Reload plugins:"
echo "       /reload-plugins"
echo "  3. Verify the orchestrator is active:"
echo "       /agents      (expect engineering-orchestrator listed)"
echo "       /hooks       (expect 5 hooks from claude-code-orchestration)"
echo "       /mcp         (expect context7 + any MCPs you added)"
echo ""
[[ "$install_wrappers" == 1 ]] && echo "Branch / worktree wrappers: $state_dir/new-branch.sh, $state_dir/new-worktree.sh"
