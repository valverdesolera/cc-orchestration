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

# ---------------------------------------------------------------------------
# Cross-platform Python 3 detection (macOS / Linux / Windows Git Bash)
# ---------------------------------------------------------------------------
# Tries `python3` first, falls back to `python` (verifying it's Python 3.x).
# On Windows, `python` is usually the only command available; the Microsoft
# Store stub at python3.exe will hang the shell, so we explicitly probe
# version output rather than blindly trusting `command -v`.
PYTHON3_CMD=""

detect_python3() {
  # Try python3 first (macOS, Linux, and Windows after the user creates a shim)
  if command -v python3 >/dev/null 2>&1; then
    local ver
    ver="$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)"
    if [[ "$ver" =~ ^3\. ]]; then
      PYTHON3_CMD="python3"
      return 0
    fi
  fi
  # Fall back to `python` (common on Windows; may also exist on macOS/Linux)
  if command -v python >/dev/null 2>&1; then
    local ver
    ver="$(python --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)"
    if [[ "$ver" =~ ^3\. ]]; then
      PYTHON3_CMD="python"
      return 0
    fi
  fi
  return 1
}

ensure_python3() {
  if detect_python3; then
    return 0
  fi
  cat >&2 <<EOF

ERROR: Python 3 is required but was not found in PATH.

Install it for your platform:
  Windows:   winget install Python.Python.3.12
             (then close + reopen Git Bash so PATH refreshes)
  macOS:     brew install python3        (or download from python.org)
  Debian:    sudo apt install python3
  Fedora:    sudo dnf install python3

On Windows, after installing, you may also need to disable the
Microsoft Store stubs that intercept python.exe / python3.exe:
  Settings -> Apps -> Advanced app settings -> App execution aliases
  -> toggle off python.exe and python3.exe

Then re-run this script.
EOF
  exit 1
}

# Optional: on Windows Git Bash, if `python` works but `python3` does not,
# create a python3.exe shim alongside python.exe so future tools (and re-runs
# of this script) can find python3 directly. Best-effort; skipped if the
# directory isn't writable.
ensure_python3_shim_on_windows() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"
  case "$uname_s" in
    MINGW*|MSYS*|CYGWIN*) : ;;
    *) return 0 ;;
  esac
  if [[ "$PYTHON3_CMD" != "python" ]]; then
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    return 0
  fi
  local python_path python_dir python3_path
  python_path="$(command -v python)"
  python_dir="$(dirname "$python_path")"
  python3_path="$python_dir/python3.exe"
  if [[ -f "$python3_path" ]]; then
    return 0
  fi
  if [[ -w "$python_dir" ]]; then
    if cp "$python_path" "$python3_path" 2>/dev/null; then
      echo "Created Windows shim: $python3_path -> python.exe"
      PYTHON3_CMD="python3"
    fi
  fi
}

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
  ensure_python3
  ensure_python3_shim_on_windows
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ref_json="$script_dir/reference/recommended-plugins.json"
  if [[ ! -f "$ref_json" ]]; then
    echo "ERROR: $ref_json not found." >&2
    echo "Expected location: bootstrap/reference/recommended-plugins.json" >&2
    exit 1
  fi
  "$PYTHON3_CMD" - "$ref_json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
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
print('# Plus this plugin (cc-orchestration):')
print('/plugin marketplace add valverdesolera/cc-orchestration')
print('/plugin install claude-code-orchestration@cc-orchestration')
print('')
print('# Additional MCPs (no plugin yet; install manually if needed):')
for m in d['additional_mcps_no_plugin_yet']:
    print(f'#   - {m["name"]}: {m["purpose"]}')
    print(f'#     Install: {m["install"]}')
PYEOF
  exit 0
fi

# Python 3 is required for the rest of the script (config cleanup uses it).
ensure_python3
ensure_python3_shim_on_windows

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
# 0) Personal Claude Code config cleanup (~/.claude.json)
#    Removes known-stale MCP server entries that duplicate official plugins.
#    Runs on every bootstrap invocation (idempotent). Always backed up first.
#    Generalizes: add new stale entry names to STALE_MCP_ENTRIES below.
# ---------------------------------------------------------------------------
clean_stale_personal_config() {
  local cfg="$HOME/.claude.json"
  [[ ! -f "$cfg" ]] && return 0

  # One-time backup (never overwritten)
  local backup="$cfg.backup-pre-cc-orchestration"
  if [[ ! -f "$backup" ]]; then
    cp "$cfg" "$backup"
    echo "Backed up ~/.claude.json to $backup"
  fi

  # Use Python 3 (detected at script start) to safely edit JSON.
  # Add more entries to STALE_MCP_ENTRIES as duplicates surface.
  "$PYTHON3_CMD" - "$cfg" <<'PYCLEAN'
import json, sys
STALE_MCP_ENTRIES = ["microsoftLearn"]  # add more as needed

cfg_path = sys.argv[1]
try:
    with open(cfg_path, encoding="utf-8") as f:
        data = json.load(f)
except Exception as e:
    print(f"WARN: could not parse {cfg_path}; skipping cleanup. ({e})", file=sys.stderr)
    sys.exit(0)

mcp_servers = data.get("mcpServers") or {}
removed = []
for name in STALE_MCP_ENTRIES:
    if name in mcp_servers:
        del mcp_servers[name]
        removed.append(name)

if removed:
    data["mcpServers"] = mcp_servers
    with open(cfg_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print(f"Removed stale MCP entries from ~/.claude.json: {', '.join(removed)}")
    print("(superseded by official plugins; original backed up)")
PYCLEAN
}

clean_stale_personal_config

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
  # Appends a bare gitignore pattern to .git/info/exclude (idempotent).
  # We intentionally do NOT use leading-slash patterns (e.g. /foo) because
  # they are silently ignored by git 2.x on Windows/Git-Bash � git reads
  # the file but the leading slash is not treated as a repo-root anchor.
  # Bare patterns (foo, docs/ignored/) match everywhere in the tree, which
  # is fine given how specific these names are in practice.
  local pattern="$1"
  # Also remove any old leading-slash variant already written by a prior
  # bootstrap run, so the file does not accumulate both forms.
  # grep -vxF handles special chars (*, ., etc.) safely as literal strings.
  local tmp
  tmp="$(mktemp)"
  grep -vxF "/$pattern" "$exclude_file" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$exclude_file"
  grep -qxF "$pattern" "$exclude_file" 2>/dev/null || echo "$pattern" >> "$exclude_file"
}

# Patterns to keep local-only (bare � no leading slash; see add_exclude note above):
add_exclude "docs/ignored/"
add_exclude "CLAUDE.md"
add_exclude "CLAUDE.local.md"
add_exclude ".worktreeinclude"
add_exclude ".claude-personal/"
add_exclude "claude_code_architecture_pack*.zip"
add_exclude "claude_code_private_overlay*.zip"
add_exclude "Claude_Code_Private_Overlay*.pdf"
add_exclude "Claude_Code_Private_Overlay*.docx"
add_exclude "Claude_Code_Improvements*.pdf"
add_exclude "cc-orchestration*.zip"

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

  cat > "$hooks_dir/post-commit" <<'HOOK'
#!/usr/bin/env bash
# Keeps the srclight code-intelligence index fresh after each commit.
# No-op if srclight is not installed or this repo has not been indexed yet.
if command -v srclight >/dev/null 2>&1 && [[ -d ".srclight" ]]; then
  srclight index --incremental 2>/dev/null || true
fi
HOOK

  cat > "$hooks_dir/post-checkout" <<'HOOK'
#!/usr/bin/env bash
# Keeps the srclight code-intelligence index fresh after branch switches.
# No-op if srclight is not installed or this repo has not been indexed yet.
# $3 = 1 means branch checkout (not file checkout); skip file-only checkouts.
[[ "${3:-0}" == "1" ]] || exit 0
if command -v srclight >/dev/null 2>&1 && [[ -d ".srclight" ]]; then
  srclight index --incremental 2>/dev/null || true
fi
HOOK

  chmod +x "$hooks_dir"/pre-commit "$hooks_dir"/commit-msg "$hooks_dir"/pre-push "$hooks_dir"/post-commit "$hooks_dir"/post-checkout

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

# Mark .mcp.json as skip-worktree if it is tracked. Lets each worktree have its
# own local MCP config without dirtying git status or tripping the pre-commit
# hook. No-op if .mcp.json is not tracked in this repo.
if git -C "$path" ls-files --error-unmatch .mcp.json >/dev/null 2>&1; then
  git -C "$path" update-index --skip-worktree .mcp.json
  echo "Applied skip-worktree to .mcp.json in $path"
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
echo "       /plugin marketplace add valverdesolera/cc-orchestration"
echo "       /plugin install claude-code-orchestration@cc-orchestration"
echo "  2. Reload plugins:"
echo "       /reload-plugins"
echo "  3. Verify the orchestrator is active:"
echo "       /agents      (expect engineering-orchestrator listed)"
echo "       /hooks       (expect 5 hooks from claude-code-orchestration)"
echo "       /mcp         (expect context7 + any MCPs you added)"
echo ""
echo "Tip: after future updates, run /cco-update inside Claude Code to pull"
echo "     the latest plugin version in one step."
echo ""
[[ "$install_wrappers" == 1 ]] && echo "Branch / worktree wrappers: $state_dir/new-branch.sh, $state_dir/new-worktree.sh"
