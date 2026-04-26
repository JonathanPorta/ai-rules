#!/usr/bin/env bash
set -euo pipefail

# claim-fork.sh — One-shot interactive script for forks of ai-rules.
#
# Detects this clone's git origin, derives HOST/OWNER/REPO from it, and
# rewrites install.sh's DEFAULT_* lines + README URL mentions to match.
# Re-runnable: if everything already matches origin, exits as a no-op.
#
# Run this once after cloning your fork. The release workflow does NOT do
# this for you (it used to; we removed that to keep release-time CI from
# mutating installer code).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Original upstream identity. Used to detect stale README references in
# forks where install.sh has been claimed but README hasn't been updated
# (and to substitute upstream URLs during the standard claim flow). Forks
# of forks should edit these to match their direct upstream if they want
# claim-fork.sh to detect staleness against that upstream.
UPSTREAM_HOST="github.com"
UPSTREAM_OWNER="JonathanPorta"
UPSTREAM_REPO="ai-rules"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# All user-facing output goes to stderr so stdout remains clean for command
# substitution inside helpers like prompt_with_default.
info()  { echo -e "${GREEN}[claim-fork]${NC} $*" >&2; }
warn()  { echo -e "${YELLOW}[claim-fork]${NC} $*" >&2; }
error() { echo -e "${RED}[claim-fork]${NC} $*" >&2; }
ask()   { echo -ne "${CYAN}[claim-fork]${NC} $*" >&2; }

DRY_RUN=false
NO_COMMIT=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-commit) NO_COMMIT=true ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--dry-run] [--no-commit]

Walks you through replacing the upstream repo identity (host, owner, repo)
with your fork's identity in install.sh and README.md. Re-running on an
already-claimed clone is a no-op unless README.md still contains stale
upstream references.

Options:
  --dry-run     Print the planned host/owner/repo values and which files
                would change. Does not write a unified diff.
  --no-commit   Apply changes but do not create a git commit.
  -h, --help    Show this help.
EOF
      exit 0 ;;
    *)
      error "Unknown argument: $arg"
      exit 1 ;;
  esac
done

# -------------------------------------------------------------------
# Read current defaults from install.sh — these are the upstream values
# we'll be replacing.
# -------------------------------------------------------------------

INSTALL_SH="$SCRIPT_DIR/install.sh"
README_MD="$SCRIPT_DIR/README.md"

if [[ ! -f "$INSTALL_SH" ]]; then
  error "install.sh not found at $INSTALL_SH"
  error "Run claim-fork.sh from the ai-rules repo root."
  exit 1
fi

read_default() {
  # Extracts the value of DEFAULT_<KEY>="..." from install.sh.
  local key="$1"
  grep -E "^DEFAULT_${key}=\"" "$INSTALL_SH" | head -1 | sed -E 's/^DEFAULT_'"$key"'="(.*)"$/\1/'
}

CURRENT_HOST="$(read_default HOST)"
CURRENT_OWNER="$(read_default OWNER)"
CURRENT_REPO="$(read_default REPO)"

if [[ -z "$CURRENT_HOST" || -z "$CURRENT_OWNER" || -z "$CURRENT_REPO" ]]; then
  error "Could not read DEFAULT_HOST/DEFAULT_OWNER/DEFAULT_REPO from install.sh."
  error "The script may have been edited in a way claim-fork.sh doesn't understand."
  exit 1
fi

# -------------------------------------------------------------------
# Derive proposed values from git origin.
# -------------------------------------------------------------------

ORIGIN_URL="$(git -C "$SCRIPT_DIR" config --get remote.origin.url 2>/dev/null || true)"

DETECTED_HOST=""
DETECTED_OWNER=""
DETECTED_REPO=""

if [[ -n "$ORIGIN_URL" ]]; then
  if [[ "$ORIGIN_URL" =~ ^https?://([^/]+)/([^/]+)/([^/]+)$ ]]; then
    DETECTED_HOST="${BASH_REMATCH[1]}"
    DETECTED_OWNER="${BASH_REMATCH[2]}"
    DETECTED_REPO="${BASH_REMATCH[3]%.git}"
  elif [[ "$ORIGIN_URL" =~ ^git@([^:]+):([^/]+)/([^/]+)$ ]]; then
    DETECTED_HOST="${BASH_REMATCH[1]}"
    DETECTED_OWNER="${BASH_REMATCH[2]}"
    DETECTED_REPO="${BASH_REMATCH[3]%.git}"
  fi
fi

# An SSH alias (e.g., 'gh-alt') will not contain a dot. Real hostnames do.
# When the parsed host doesn't look like a domain, ask the user for the real one.
HOST_LOOKS_REAL=true
if [[ -n "$DETECTED_HOST" && "$DETECTED_HOST" != *.* ]]; then
  HOST_LOOKS_REAL=false
fi

# -------------------------------------------------------------------
# Idempotency check — already claimed AND README clean?
# -------------------------------------------------------------------

# README is stale if (a) we're not the upstream ourselves and (b) README
# still contains the upstream's URL form. This catches the case where
# someone manually edited install.sh's defaults (or a previous run only
# touched install.sh) and left README with original-upstream links.
README_HAS_STALE_UPSTREAM=false
if [[ -f "$README_MD" ]] \
   && [[ "$CURRENT_HOST" != "$UPSTREAM_HOST" \
         || "$CURRENT_OWNER" != "$UPSTREAM_OWNER" \
         || "$CURRENT_REPO"  != "$UPSTREAM_REPO" ]]; then
  if grep -qF "${UPSTREAM_HOST}/${UPSTREAM_OWNER}/${UPSTREAM_REPO}" "$README_MD" \
     || grep -qF "raw.githubusercontent.com/${UPSTREAM_OWNER}/${UPSTREAM_REPO}" "$README_MD"; then
    README_HAS_STALE_UPSTREAM=true
  fi
fi

if [[ -n "$DETECTED_HOST" && "$HOST_LOOKS_REAL" == true \
      && "$DETECTED_HOST" == "$CURRENT_HOST" \
      && "$DETECTED_OWNER" == "$CURRENT_OWNER" \
      && "$DETECTED_REPO" == "$CURRENT_REPO" \
      && "$README_HAS_STALE_UPSTREAM" == false ]]; then
  info "install.sh defaults already match origin and README has no stale upstream references."
  info "  host=${CURRENT_HOST}  owner=${CURRENT_OWNER}  repo=${CURRENT_REPO}"
  info "Nothing to claim. Exiting."
  exit 0
fi

# -------------------------------------------------------------------
# Walk-through prompts.
# -------------------------------------------------------------------

echo
info "Current install.sh defaults (upstream):"
info "  host=${CURRENT_HOST}  owner=${CURRENT_OWNER}  repo=${CURRENT_REPO}"
echo

if [[ -n "$ORIGIN_URL" ]]; then
  info "This clone's git origin: ${ORIGIN_URL}"
  if [[ -n "$DETECTED_HOST" ]]; then
    if [[ "$HOST_LOOKS_REAL" == true ]]; then
      info "Parsed: host=${DETECTED_HOST}  owner=${DETECTED_OWNER}  repo=${DETECTED_REPO}"
    else
      warn "Parsed host '${DETECTED_HOST}' does not look like a real domain"
      warn "(SSH alias?). You'll be asked for the actual host below."
    fi
  else
    warn "Could not parse host/owner/repo from origin URL."
    warn "You'll be asked to enter values manually."
  fi
else
  warn "No git remote 'origin' configured for this clone."
  warn "You'll be asked to enter all values manually."
fi
echo

prompt_with_default() {
  # Reads a value with a suggested default; suggested is shown in [brackets].
  # Empty input keeps the default.
  local label="$1" suggested="$2" reply
  ask "${label} [${suggested}]: "
  read -r reply
  if [[ -z "$reply" ]]; then
    echo "$suggested"
  else
    echo "$reply"
  fi
}

# Suggest detected values if the host parsed successfully and looks real;
# otherwise suggest the current upstream defaults so the user has something
# concrete to either accept or replace.
if [[ "$HOST_LOOKS_REAL" == true && -n "$DETECTED_HOST" ]]; then
  SUGGEST_HOST="$DETECTED_HOST"
  SUGGEST_OWNER="$DETECTED_OWNER"
  SUGGEST_REPO="$DETECTED_REPO"
else
  SUGGEST_HOST="$CURRENT_HOST"
  SUGGEST_OWNER="${DETECTED_OWNER:-$CURRENT_OWNER}"
  SUGGEST_REPO="${DETECTED_REPO:-$CURRENT_REPO}"
fi

NEW_HOST="$(prompt_with_default "GitHub host" "$SUGGEST_HOST")"
NEW_OWNER="$(prompt_with_default "Owner / org" "$SUGGEST_OWNER")"
NEW_REPO="$(prompt_with_default "Repo name" "$SUGGEST_REPO")"

# -------------------------------------------------------------------
# Validate the new values.
# -------------------------------------------------------------------

validate_identifier() {
  local label="$1" value="$2" pattern="$3"
  if [[ ! "$value" =~ $pattern ]]; then
    error "Invalid ${label}: '${value}'"
    exit 1
  fi
}

# Hostnames may include alphanumerics, dots, hyphens, and an optional :port.
validate_identifier "host"  "$NEW_HOST"  '^[A-Za-z0-9.-]+(:[0-9]+)?$'
# GitHub usernames/orgs: alphanumeric + hyphens, max 39 chars, can't start/end with hyphen.
validate_identifier "owner" "$NEW_OWNER" '^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$'
# Repo names: alphanumerics, dots, underscores, hyphens.
validate_identifier "repo"  "$NEW_REPO"  '^[A-Za-z0-9._-]+$'

# Same-as-current? Two sub-cases:
#  1. install.sh AND README are both already correct → nothing to do.
#  2. install.sh is correct but README has stale upstream refs → still need
#     to repair README, just don't touch install.sh.
SKIP_INSTALL_SH_REWRITE=false
if [[ "$NEW_HOST" == "$CURRENT_HOST" && "$NEW_OWNER" == "$CURRENT_OWNER" && "$NEW_REPO" == "$CURRENT_REPO" ]]; then
  if [[ "$README_HAS_STALE_UPSTREAM" == false ]]; then
    info "Values match the current defaults. Nothing to change."
    exit 0
  fi
  info "install.sh is already claimed for ${CURRENT_OWNER}/${CURRENT_REPO} — leaving it alone."
  info "README.md still has upstream references; will rewrite README only."
  SKIP_INSTALL_SH_REWRITE=true
fi

# -------------------------------------------------------------------
# Show the planned change and confirm.
# -------------------------------------------------------------------

echo
info "Planned change:"
info "  host:  ${CURRENT_HOST} → ${NEW_HOST}"
info "  owner: ${CURRENT_OWNER} → ${NEW_OWNER}"
info "  repo:  ${CURRENT_REPO} → ${NEW_REPO}"
echo
info "Files that will be edited:"
info "  install.sh   (DEFAULT_HOST / DEFAULT_OWNER / DEFAULT_REPO lines)"
info "  README.md    (URL mentions of ${CURRENT_HOST}/${CURRENT_OWNER}/${CURRENT_REPO})"
echo

if [[ "$DRY_RUN" == true ]]; then
  info "Dry-run mode — no files will be modified."
  exit 0
fi

ask "Apply these changes? [y/N]: "
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  info "Aborted. No files modified."
  exit 0
fi

# -------------------------------------------------------------------
# Apply the changes.
# -------------------------------------------------------------------

# Choose sed in-place flag (BSD sed needs '', GNU sed doesn't).
if sed --version >/dev/null 2>&1; then
  SED_INPLACE=(-i)
else
  SED_INPLACE=(-i '')
fi

# install.sh: rewrite the three DEFAULT_* lines (unless we're in the
# README-only repair path).
if [[ "$SKIP_INSTALL_SH_REWRITE" == true ]]; then
  info "Skipped $INSTALL_SH (already claimed for ${CURRENT_OWNER}/${CURRENT_REPO})."
else
  sed "${SED_INPLACE[@]}" \
    -e "s|^DEFAULT_HOST=.*|DEFAULT_HOST=\"${NEW_HOST}\"|" \
    -e "s|^DEFAULT_OWNER=.*|DEFAULT_OWNER=\"${NEW_OWNER}\"|" \
    -e "s|^DEFAULT_REPO=.*|DEFAULT_REPO=\"${NEW_REPO}\"|" \
    "$INSTALL_SH"
  info "Updated $INSTALL_SH"
fi

# README.md: rewrite URL patterns. We rewrite specific URL forms (not bare
# tokens) so unrelated text — credit lines, license, etc. — is never
# touched. Substitute BOTH the upstream patterns and the current-claim
# patterns to the new values; this handles first-claim, re-claim (changing
# fork identity), and stale-README-only repair in one pass.
if [[ -f "$README_MD" ]]; then
  CUR_WEB="${CURRENT_HOST}/${CURRENT_OWNER}/${CURRENT_REPO}"
  NEW_WEB="${NEW_HOST}/${NEW_OWNER}/${NEW_REPO}"
  UP_WEB="${UPSTREAM_HOST}/${UPSTREAM_OWNER}/${UPSTREAM_REPO}"

  raw_for_host() {
    if [[ "$1" == "github.com" ]]; then
      printf 'raw.githubusercontent.com/%s/%s' "$2" "$3"
    else
      printf '%s/raw/%s/%s' "$1" "$2" "$3"
    fi
  }
  CUR_RAW="$(raw_for_host "$CURRENT_HOST" "$CURRENT_OWNER" "$CURRENT_REPO")"
  NEW_RAW="$(raw_for_host "$NEW_HOST" "$NEW_OWNER" "$NEW_REPO")"
  UP_RAW="$(raw_for_host "$UPSTREAM_HOST" "$UPSTREAM_OWNER" "$UPSTREAM_REPO")"

  sed "${SED_INPLACE[@]}" \
    -e "s|${UP_RAW}|${NEW_RAW}|g" \
    -e "s|${UP_WEB}|${NEW_WEB}|g" \
    -e "s|${CUR_RAW}|${NEW_RAW}|g" \
    -e "s|${CUR_WEB}|${NEW_WEB}|g" \
    "$README_MD"
  info "Updated $README_MD"
else
  warn "README.md not found — skipped."
fi

# -------------------------------------------------------------------
# Optional commit.
# -------------------------------------------------------------------

if [[ "$NO_COMMIT" == true ]]; then
  info "Done. Review the diff with: git diff"
  info "(skipped commit due to --no-commit)"
  exit 0
fi

if ! git -C "$SCRIPT_DIR" diff --quiet -- install.sh README.md 2>/dev/null; then
  ask "Create a commit with these changes? [y/N]: "
  read -r commit_confirm
  if [[ "$commit_confirm" =~ ^[Yy]$ ]]; then
    git -C "$SCRIPT_DIR" add install.sh README.md
    git -C "$SCRIPT_DIR" commit -m "chore: claim fork for ${NEW_OWNER}/${NEW_REPO}"
    info "Committed. Push when ready: git push"
  else
    info "Done. Review with: git diff && git add install.sh README.md && git commit"
  fi
else
  info "No diff in tracked files — nothing to commit."
fi
