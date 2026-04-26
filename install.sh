#!/usr/bin/env bash
set -euo pipefail

# install.sh — Install or update ai-rules via git subtree
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/JonathanPorta/ai-rules/main/install.sh | bash
#
# What it does:
#   - If .ai-rules/ doesn't exist: git subtree add from latest release tag
#   - If .ai-rules/ exists and is ours: git subtree pull to latest release tag
#   - If .ai-rules/ exists but isn't ours: abort with warning
#

# DEFAULT_HOST, DEFAULT_OWNER, DEFAULT_REPO point at the upstream repo this
# script was distributed from. Forks rewrite these locally by running
# claim-fork.sh once after cloning; see README's "Forking" section.
DEFAULT_HOST="github.com"
DEFAULT_OWNER="JonathanPorta"
DEFAULT_REPO="ai-rules"

# Runtime override via env vars; otherwise the stamped defaults above.
HOST="${AI_RULES_HOST:-$DEFAULT_HOST}"
OWNER="${AI_RULES_OWNER:-$DEFAULT_OWNER}"
REPO_NAME="${AI_RULES_REPO:-$DEFAULT_REPO}"

# Clone-mode auto-detect: if install.sh is being executed from a file inside
# what looks like an ai-rules checkout (has setup.sh + AGENTS.md as sentinels),
# derive HOST/OWNER/REPO_NAME from that clone's git origin. Skipped under
# curl|bash because BASH_SOURCE[0] is not a real file path in that flow.
if [[ -z "${AI_RULES_HOST:-}" && -z "${AI_RULES_OWNER:-}" && -z "${AI_RULES_REPO:-}" \
      && -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  _script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$_script_dir/setup.sh" && -f "$_script_dir/AGENTS.md" ]]; then
    _detected="$(git -C "$_script_dir" config --get remote.origin.url 2>/dev/null || true)"
    _parsed_host=""; _parsed_owner=""; _parsed_repo=""
    if [[ "$_detected" =~ ^https?://([^/]+)/([^/]+)/([^/]+)$ ]]; then
      _parsed_host="${BASH_REMATCH[1]}"
      _parsed_owner="${BASH_REMATCH[2]}"
      _parsed_repo="${BASH_REMATCH[3]%.git}"
    elif [[ "$_detected" =~ ^git@([^:]+):([^/]+)/([^/]+)$ ]]; then
      _parsed_host="${BASH_REMATCH[1]}"
      _parsed_owner="${BASH_REMATCH[2]}"
      _parsed_repo="${BASH_REMATCH[3]%.git}"
    fi
    # Only adopt parsed values if the host looks like a real domain
    # (contains a dot). SSH config aliases like "gh-alt" must not become
    # API hosts — fall back to stamped defaults instead.
    if [[ -n "$_parsed_host" && "$_parsed_host" == *.* ]]; then
      HOST="$_parsed_host"
      OWNER="$_parsed_owner"
      REPO_NAME="$_parsed_repo"
    fi
    unset _detected _parsed_host _parsed_owner _parsed_repo
  fi
  unset _script_dir
fi

# Derive the three URL bases from HOST. github.com uses dedicated subdomains
# for the API and raw content; GitHub Enterprise serves both under the same
# host (api/v3 and /raw paths).
if [[ "$HOST" == "github.com" ]]; then
  API_BASE="https://api.github.com"
else
  API_BASE="https://${HOST}/api/v3"
fi
WEB_BASE="https://${HOST}"

REPO="${WEB_BASE}/${OWNER}/${REPO_NAME}.git"
REPO_API="${API_BASE}/repos/${OWNER}/${REPO_NAME}/releases/latest"
ORIGIN_URL="${WEB_BASE}/${OWNER}/${REPO_NAME}"
PREFIX=".ai-rules"
VERSION_FILE="${PREFIX}/.version"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[ai-rules]${NC} $*"; }
warn()  { echo -e "${YELLOW}[ai-rules]${NC} $*"; }
error() { echo -e "${RED}[ai-rules]${NC} $*" >&2; }

# Idempotently ensure the consuming repo's root .gitignore protects
# private styleguide overlays (the .ai-local/ convention). Called from
# every success path so existing repos pick up the entry on update,
# not only on fresh install.
ensure_ai_local_gitignore() {
  local marker="# ai-rules-local-config"
  if [[ -f .gitignore ]] && grep -qF "$marker" .gitignore; then
    return 0
  fi
  {
    if [[ -f .gitignore ]] && [[ -n "$(tail -c 1 .gitignore)" ]]; then
      echo ""
    fi
    echo "$marker"
    echo ".ai-local/"
  } >> .gitignore
  info "Added .ai-local/ to .gitignore (private styleguide overlays)."
}

# -------------------------------------------------------------------
# Preflight checks
# -------------------------------------------------------------------

# Must have git
if ! command -v git &>/dev/null; then
  error "git is not installed."
  exit 1
fi

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  error "Not inside a git repository. Run this from your project root."
  exit 1
fi

# Must have git subtree available.
# git subtree is a contrib shell script, not a binary — 'command -v git-subtree'
# won't find it. Invoking 'git subtree' with no args prints usage to stdout
# but exits non-zero, so we check if the output contains 'usage' regardless of
# exit code.
SUBTREE_CHECK=$(git subtree 2>&1 || true)
if ! echo "$SUBTREE_CHECK" | grep -qi 'usage'; then
  error "'git subtree' is not available on this system."
  error "On Debian/Ubuntu: sudo apt-get install git-subtree"
  error "On macOS: it is included with git from Homebrew (brew install git)"
  error "On other systems: check your git installation or install git-subtree separately."
  exit 1
fi

# Must be at repo root (subtree requires it)
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [[ "$PWD" != "$REPO_ROOT" ]]; then
  warn "Changing to repository root: $REPO_ROOT"
  cd "$REPO_ROOT"
fi

# Check for uncommitted changes (subtree needs a clean working tree)
if ! git rev-parse HEAD &>/dev/null; then
  error "Repository has no commits. Create an initial commit before installing."
  exit 1
fi
if ! git diff-index --quiet HEAD --; then
  error "You have uncommitted changes. Commit or stash them before installing."
  exit 1
fi

# -------------------------------------------------------------------
# Fetch latest release tag
# -------------------------------------------------------------------

info "Fetching latest release..."

if command -v curl &>/dev/null; then
  LATEST_TAG=$(curl -fsSL "$REPO_API" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')
elif command -v wget &>/dev/null; then
  LATEST_TAG=$(wget -qO- "$REPO_API" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')
else
  error "Neither curl nor wget found. Install one and try again."
  exit 1
fi

if [[ -z "$LATEST_TAG" ]]; then
  error "No releases found. The repository may not have any tagged releases yet."
  error "You can install from main instead:"
  error "  git subtree add --prefix=${PREFIX} ${REPO} main --squash"
  exit 1
fi

info "Latest release: ${LATEST_TAG}"

# -------------------------------------------------------------------
# Determine action: install, update, or abort
# -------------------------------------------------------------------

if [[ ! -d "$PREFIX" ]]; then
  # Fresh install
  info "Installing ai-rules ${LATEST_TAG}..."
  git subtree add --prefix="$PREFIX" "$REPO" "$LATEST_TAG" --squash

  ensure_ai_local_gitignore

  info "Installation complete."
  info ""
  info "Next steps:"
  info "  1. Run: ${PREFIX}/setup.sh --platforms cursor,windsurf,copilot"
  info "  2. Commit the generated platform stubs"
  info "  3. Read ${PREFIX}/AGENTS.md to understand the rules"

elif [[ -f "$VERSION_FILE" ]]; then
  # Directory exists — check if it's ours
  INSTALLED_ORIGIN=$(grep '^origin=' "$VERSION_FILE" 2>/dev/null | cut -d= -f2- || true)

  if [[ "$INSTALLED_ORIGIN" != "$ORIGIN_URL" ]]; then
    error "${PREFIX}/ exists but its origin doesn't match."
    error "  Expected: ${ORIGIN_URL}"
    error "  Found:    ${INSTALLED_ORIGIN:-<none>}"
    error ""
    error "Remove ${PREFIX}/ manually if you want to reinstall."
    exit 1
  fi

  # It's ours — check current version
  INSTALLED_TAG=$(grep '^tag=' "$VERSION_FILE" 2>/dev/null | cut -d= -f2- || true)

  if [[ "$INSTALLED_TAG" == "$LATEST_TAG" ]]; then
    info "Already up to date at ${LATEST_TAG}."
    ensure_ai_local_gitignore
    exit 0
  fi

  info "Updating ai-rules from ${INSTALLED_TAG} to ${LATEST_TAG}..."
  git subtree pull --prefix="$PREFIX" "$REPO" "$LATEST_TAG" --squash

  ensure_ai_local_gitignore

  info "Update complete: ${INSTALLED_TAG} → ${LATEST_TAG}"

else
  # Directory exists but no .version file — not ours
  error "${PREFIX}/ directory exists but has no .version file."
  error "This directory was not installed by ai-rules."
  error ""
  error "If you want to install ai-rules here, remove the directory first:"
  error "  rm -rf ${PREFIX}"
  error "Then run this script again."
  exit 1
fi
