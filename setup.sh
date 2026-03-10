#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Generate platform-specific stub files that reference .ai-rules/
#
# Usage:
#   .ai-rules/setup.sh --platforms cursor,windsurf,copilot
#   .ai-rules/setup.sh --platforms all
#   .ai-rules/setup.sh --list
#
# This script is idempotent. If a stub already exists and contains the
# reference line, it is left untouched (preserving project-specific additions).
# If the file exists but lacks the reference, the reference is prepended.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_REL=".ai-rules"

REFERENCE_MARKER="# ai-rules-reference"

SUPPORTED_PLATFORMS="claude,cursor,windsurf,copilot,amp"

usage() {
  local exit_code="${1:-0}"
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate platform-specific config stubs that reference ${RULES_REL}/.

Options:
  --platforms <list>   Comma-separated platforms: claude,cursor,windsurf,copilot,amp
                       Use 'all' for every supported platform.
  --list               List supported platforms and exit.
  --dry-run            Show what would be created without writing files.
  -h, --help           Show this help message.

Examples:
  $(basename "$0") --platforms cursor,windsurf
  $(basename "$0") --platforms all
  $(basename "$0") --list
EOF
  exit "$exit_code"
}

list_platforms() {
  echo "Supported platforms:"
  echo "  claude     - Claude Code (auto-discovers AGENTS.md, stub optional)"
  echo "  cursor     - Cursor (.cursorrules)"
  echo "  windsurf   - Windsurf (.windsurfrules)"
  echo "  copilot    - GitHub Copilot (.github/copilot-instructions.md)"
  echo "  amp        - Amp (.amp/rules/ai-rules.md)"
  exit 0
}

DRY_RUN=false
PLATFORMS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --platforms)
      if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
        echo "Error: --platforms requires a value." >&2
        usage 1
      fi
      PLATFORMS="$2"; shift 2 ;;
    --list) list_platforms ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

if [[ -z "$PLATFORMS" ]]; then
  echo "Error: --platforms is required."
  echo "Run with --list to see supported platforms, or --help for usage."
  exit 1
fi

if [[ "$PLATFORMS" == "all" ]]; then
  PLATFORMS="$SUPPORTED_PLATFORMS"
fi

# Check if file already contains our reference marker
has_reference() {
  local file="$1"
  [[ -f "$file" ]] && grep -q "$REFERENCE_MARKER" "$file"
}

# Write or update a stub file
write_stub() {
  local file="$1"
  local content="$2"
  local platform="$3"

  if has_reference "$file"; then
    echo "  [skip] $file — already has ai-rules reference"
    return
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] would create/update $file ($platform)"
    return
  fi

  local dir
  dir="$(dirname "$file")"
  [[ -d "$dir" ]] || mkdir -p "$dir"

  if [[ -f "$file" ]]; then
    # File exists but lacks reference — prepend
    local tmp
    tmp="$(mktemp)"
    printf '%s\n\n' "$content" | cat - "$file" > "$tmp"
    mv "$tmp" "$file"
    echo "  [update] $file — prepended ai-rules reference"
  else
    printf '%s\n' "$content" > "$file"
    echo "  [create] $file"
  fi
}

echo "Setting up ai-rules platform stubs..."
echo ""

IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"
for platform in "${PLATFORM_LIST[@]}"; do
  platform="$(echo "$platform" | tr -d '[:space:]')"
  case "$platform" in
    claude)
      echo "Claude Code:"
      echo "  [info] Claude Code auto-discovers ${RULES_REL}/AGENTS.md — no stub needed."
      echo "  [info] To add an explicit reference, create a root AGENTS.md that imports it."
      ;;
    cursor)
      echo "Cursor:"
      STUB="${REFERENCE_MARKER}
# Read and follow all rules in ${RULES_REL}/AGENTS.md and the files it
# references before beginning any feature work.
@file ${RULES_REL}/AGENTS.md

# Project-specific Cursor rules below this line"
      write_stub "$PROJECT_ROOT/.cursorrules" "$STUB" "cursor"
      ;;
    windsurf)
      echo "Windsurf:"
      STUB="${REFERENCE_MARKER}
Before starting any feature work, read and follow the rules defined in
${RULES_REL}/AGENTS.md and all referenced rule files in ${RULES_REL}/rules/.

Project-specific Windsurf rules below this line:"
      write_stub "$PROJECT_ROOT/.windsurfrules" "$STUB" "windsurf"
      ;;
    copilot)
      echo "GitHub Copilot:"
      STUB="<!-- ${REFERENCE_MARKER} -->
## AI Development Rules

Follow the AI development rules defined in \`${RULES_REL}/AGENTS.md\`.
Read all referenced rule files before beginning feature work.

<!-- Project-specific Copilot instructions below this line -->"
      write_stub "$PROJECT_ROOT/.github/copilot-instructions.md" "$STUB" "copilot"
      ;;
    amp)
      echo "Amp:"
      STUB="${REFERENCE_MARKER}
Read and follow all rules in ${RULES_REL}/AGENTS.md and the files it
references before beginning any feature work.

Project-specific Amp rules below this line:"
      write_stub "$PROJECT_ROOT/.amp/rules/ai-rules.md" "$STUB" "amp"
      ;;
    *)
      echo "Unknown platform: $platform (skipping)"
      echo "  Run with --list to see supported platforms."
      ;;
  esac
  echo ""
done

echo "Done. Review the generated files and commit them to your project."
