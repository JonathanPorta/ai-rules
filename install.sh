#!/usr/bin/env bash
set -euo pipefail

# install.sh — Install or update ai-rules via git subtree
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/portaj/ai-rules/main/install.sh | bash
#
# What it does:
#   - If .ai-rules/ doesn't exist: git subtree add from latest release tag
#   - If .ai-rules/ exists and is ours: git subtree pull to latest release tag
#   - If .ai-rules/ exists but isn't ours: abort with warning
#

REPO="https://github.com/portaj/ai-rules.git"
REPO_API="https://api.github.com/repos/portaj/ai-rules/releases/latest"
ORIGIN_URL="https://github.com/portaj/ai-rules"
PREFIX=".ai-rules"
VERSION_FILE="${PREFIX}/.version"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[ai-rules]${NC} $*"; }
warn()  { echo -e "${YELLOW}[ai-rules]${NC} $*"; }
error() { echo -e "${RED}[ai-rules]${NC} $*" >&2; }

# -------------------------------------------------------------------
# Preflight checks
# -------------------------------------------------------------------

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  error "Not inside a git repository. Run this from your project root."
  exit 1
fi

# Must be at repo root (subtree requires it)
REPO_ROOT="$(git rev-parse --show-toplevel)"
if [[ "$PWD" != "$REPO_ROOT" ]]; then
  warn "Changing to repository root: $REPO_ROOT"
  cd "$REPO_ROOT"
fi

# Check for uncommitted changes (subtree needs a clean working tree)
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
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
    exit 0
  fi

  info "Updating ai-rules from ${INSTALLED_TAG} to ${LATEST_TAG}..."
  git subtree pull --prefix="$PREFIX" "$REPO" "$LATEST_TAG" --squash

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
