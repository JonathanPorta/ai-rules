#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Generate platform-specific stub files that reference .ai-rules/.
#
# Intended to be run from inside a consumer project's .ai-rules/ subtree:
#
#   .ai-rules/setup.sh --platforms cursor,windsurf,copilot
#   .ai-rules/setup.sh --platforms all
#   .ai-rules/setup.sh --list
#
# Idempotency: if a stub already contains the reference marker it is left
# untouched. If a file exists at the target path without the marker, the
# stub is prepended — UNLESS the existing file starts with YAML frontmatter,
# in which case the script warns and skips rather than corrupt the file.
#
# Platform definitions live in PLATFORMS_TABLE below; stub bodies live in
# templates/platform-stubs/. To add or modify a platform, edit both.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STUBS_DIR="$SCRIPT_DIR/templates/platform-stubs"
AGENTS_MD="$SCRIPT_DIR/AGENTS.md"
RULES_REL=".ai-rules"

REFERENCE_MARKER="ai-rules-reference"

# Used by usage() and the no-args path. Single source of truth so the
# help text never drifts from the runtime default.
DEFAULT_PLATFORMS="claude,copilot"

# name|relative_path|template_filename|description
# Keep in sync with templates/platform-stubs/ and README.md platform table.
PLATFORMS_TABLE=(
  "claude|CLAUDE.md|claude.md|Claude Code (root CLAUDE.md with @import)"
  "cursor|.cursor/rules/ai-rules.mdc|cursor.mdc|Cursor (.cursor/rules/*.mdc with MDC frontmatter)"
  "windsurf|.windsurf/rules/ai-rules.md|windsurf.md|Windsurf (.windsurf/rules/*.md with YAML frontmatter)"
  "copilot|.github/copilot-instructions.md|copilot.md|GitHub Copilot (.github/copilot-instructions.md)"
  "amp|AGENTS.md|amp.md|Amp (root AGENTS.md)"
)

# Skill wiring per platform. Native-skills platforms get one symlink per
# skill folder under .ai-rules/skills/ into their discovery directory.
# Reference-only platforms have no auto-discovery mechanism; their stubs
# carry a text reference to .ai-rules/skills/ instead.
#
# name|skills_target_dir|wiring_mode
#   symlink-dir → symlink <target>/<skill> → ../../.ai-rules/skills/<skill>
#   reference   → no filesystem wiring; stub template carries the reference
SKILLS_TABLE=(
  "claude|.claude/skills|symlink-dir"
  "windsurf|.windsurf/skills|symlink-dir"
  "copilot|.github/skills|symlink-dir"
  "cursor||reference"
  "amp||reference"
)

SKILLS_SRC_DIR="$SCRIPT_DIR/skills"

COUNT_CREATE=0
COUNT_UPDATE=0
COUNT_SKIP=0
COUNT_WARN=0

usage() {
  local exit_code="${1:-0}"
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate platform-specific config stubs that reference ${RULES_REL}/.

Options:
  --platforms <list>   Comma-separated platforms, e.g. claude,copilot,cursor.
                       Use 'all' for every supported platform, or run --list
                       to see the full set. Defaults to: ${DEFAULT_PLATFORMS}.
  --list               List supported platforms and exit.
  --dry-run            Show what would happen without writing files.
  --force              Overwrite existing stubs unconditionally — skips the
                       reference-marker check and the YAML-frontmatter
                       safety check. Use when you know you want to clobber
                       whatever is at the target path.
  --no-skills          Skip per-platform skills wiring (default: enabled
                       for native-skills platforms — Claude Code, Windsurf,
                       and Copilot). Cursor and Amp are reference-only and
                       are unaffected by this flag.
  -h, --help           Show this help message.

Examples:
  $(basename "$0")                                   # defaults to ${DEFAULT_PLATFORMS}
  $(basename "$0") --platforms claude,copilot,cursor
  $(basename "$0") --platforms all
  $(basename "$0") --platforms cursor --force        # rewrite Cursor stub
  $(basename "$0") --list
EOF
  exit "$exit_code"
}

list_platforms() {
  echo "Supported platforms:"
  local row name desc skills_label
  for row in "${PLATFORMS_TABLE[@]}"; do
    IFS='|' read -r name _ _ desc <<< "$row"
    printf "  %-10s - %s\n" "$name" "$desc"
    if lookup_skills "$name"; then
      if [[ "$SK_MODE" == "reference" ]]; then
        skills_label="reference only (stub points at .ai-rules/skills/)"
      else
        skills_label="native at $SK_DIR/"
      fi
      printf "  %-10s   skills: %s\n" "" "$skills_label"
    fi
  done
  exit 0
}

supported_names() {
  local row name names=""
  for row in "${PLATFORMS_TABLE[@]}"; do
    IFS='|' read -r name _ _ _ <<< "$row"
    names="${names:+$names,}$name"
  done
  echo "$names"
}

# Sets PL_PATH and PL_TEMPLATE for the requested platform. Returns 1 on miss.
lookup_platform() {
  local target="$1" row name path template _desc
  for row in "${PLATFORMS_TABLE[@]}"; do
    IFS='|' read -r name path template _desc <<< "$row"
    if [[ "$name" == "$target" ]]; then
      PL_PATH="$path"
      PL_TEMPLATE="$template"
      return 0
    fi
  done
  return 1
}

# Sets SK_DIR and SK_MODE for the requested platform. Returns 1 on miss.
lookup_skills() {
  local target="$1" row name skills_dir mode
  for row in "${SKILLS_TABLE[@]}"; do
    IFS='|' read -r name skills_dir mode <<< "$row"
    if [[ "$name" == "$target" ]]; then
      SK_DIR="$skills_dir"
      SK_MODE="$mode"
      return 0
    fi
  done
  return 1
}

DRY_RUN=false
FORCE=false
NO_SKILLS=false
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
    --force) FORCE=true; shift ;;
    --no-skills) NO_SKILLS=true; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

if [[ -z "$PLATFORMS" ]]; then
  PLATFORMS="$DEFAULT_PLATFORMS"
  echo "No --platforms specified; defaulting to: $PLATFORMS"
  echo "(Run --list for all supported platforms, or --help for usage.)"
  echo ""
fi

if [[ "$PLATFORMS" == "all" ]]; then
  PLATFORMS="$(supported_names)"
fi

if [[ ! -f "$AGENTS_MD" ]]; then
  echo "Warning: $AGENTS_MD not found." >&2
  echo "         Stubs will reference ${RULES_REL}/AGENTS.md but the source is missing." >&2
fi

has_reference() {
  local file="$1"
  [[ -f "$file" ]] && grep -qF -- "$REFERENCE_MARKER" "$file"
}

has_frontmatter() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  [[ "$(grep -v -- '^[[:space:]]*$' "$file" | head -n 1)" == "---" ]]
}

write_stub() {
  local abs_path="$1" template_file="$2" platform="$3" rel_path="$4"

  if [[ ! -f "$template_file" ]]; then
    echo "  [warn]   template missing: $template_file — skipping $platform" >&2
    COUNT_WARN=$((COUNT_WARN + 1))
    return 0
  fi

  # Refuse to write through anything that isn't a regular file. Catches
  # directories, FIFOs, sockets, and broken symlinks at the target path
  # — without this, `cp` would happily copy the template *into* a
  # directory of the same name, and -f checks below would silently lie.
  if [[ ( -e "$abs_path" || -L "$abs_path" ) && ! -f "$abs_path" ]]; then
    echo "  [warn]   $rel_path — target exists but is not a regular file; skipping." >&2
    echo "           Remove or rename it before re-running setup." >&2
    COUNT_WARN=$((COUNT_WARN + 1))
    return 0
  fi

  # --force path: clobber whatever is at the target with the template, no
  # reference-marker check, no frontmatter safety. Use when you know you
  # want to refresh the stub (template body changed, etc.).
  if [[ "$FORCE" == true ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      if [[ -f "$abs_path" ]]; then
        echo "  [dry-run] would overwrite $rel_path ($platform, --force)"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
      else
        echo "  [dry-run] would create $rel_path ($platform)"
        COUNT_CREATE=$((COUNT_CREATE + 1))
      fi
      return 0
    fi
    mkdir -p "$(dirname "$abs_path")"
    local existed=false
    [[ -f "$abs_path" ]] && existed=true
    if [[ "$existed" == true ]]; then
      # Preserve target's inode and mode by writing through a redirect.
      cat "$template_file" > "$abs_path"
      echo "  [force]  $rel_path — overwrote existing file"
      COUNT_UPDATE=$((COUNT_UPDATE + 1))
    else
      cp "$template_file" "$abs_path"
      echo "  [create] $rel_path"
      COUNT_CREATE=$((COUNT_CREATE + 1))
    fi
    return 0
  fi

  if has_reference "$abs_path"; then
    echo "  [skip]   $rel_path — already has ai-rules reference"
    COUNT_SKIP=$((COUNT_SKIP + 1))
    return 0
  fi

  if [[ -f "$abs_path" ]] && has_frontmatter "$abs_path"; then
    echo "  [warn]   $rel_path — existing file has YAML frontmatter; cannot safely prepend." >&2
    echo "           Add '<!-- $REFERENCE_MARKER -->' manually after the frontmatter," >&2
    echo "           remove the file to regenerate, or re-run with --force to overwrite." >&2
    COUNT_WARN=$((COUNT_WARN + 1))
    return 0
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ -f "$abs_path" ]]; then
      echo "  [dry-run] would update $rel_path ($platform)"
      COUNT_UPDATE=$((COUNT_UPDATE + 1))
    else
      echo "  [dry-run] would create $rel_path ($platform)"
      COUNT_CREATE=$((COUNT_CREATE + 1))
    fi
    return 0
  fi

  mkdir -p "$(dirname "$abs_path")"

  if [[ -f "$abs_path" ]]; then
    local tmp
    tmp="$(mktemp)"
    { cat "$template_file"; printf '\n'; cat "$abs_path"; } > "$tmp"
    # Use redirection (not mv) so $abs_path keeps its original inode, mode, and ACLs.
    cat "$tmp" > "$abs_path"
    rm -f "$tmp"
    echo "  [update] $rel_path — prepended ai-rules reference"
    COUNT_UPDATE=$((COUNT_UPDATE + 1))
  else
    cp "$template_file" "$abs_path"
    echo "  [create] $rel_path"
    COUNT_CREATE=$((COUNT_CREATE + 1))
  fi
}

# Wire each skill folder under .ai-rules/skills/ into a platform's native
# discovery directory via relative symlinks. Idempotent: existing correct
# symlinks are left alone; foreign content at the target path triggers a
# warning unless --force is set. Reference-only platforms are no-ops here.
wire_skills_for_platform() {
  local platform="$1" skills_target_dir="$2" mode="$3"

  if [[ "$mode" == "reference" ]]; then
    return 0
  fi

  if [[ ! -d "$SKILLS_SRC_DIR" ]]; then
    # No skills shipped with this installation; nothing to wire.
    return 0
  fi

  local target_abs="$PROJECT_ROOT/$skills_target_dir"
  local skill_path skill_name target_link link_target existing rel_target

  for skill_path in "$SKILLS_SRC_DIR"/*/; do
    [[ -d "$skill_path" ]] || continue
    skill_name="$(basename "$skill_path")"
    target_link="$target_abs/$skill_name"
    rel_target="$skills_target_dir/$skill_name"

    # All native-skills targets sit two directories deep
    # (.claude/skills, .windsurf/skills, .github/skills), so the relative
    # link target is uniformly ../../.ai-rules/skills/<skill>.
    link_target="../../.ai-rules/skills/$skill_name"

    if [[ -L "$target_link" ]]; then
      existing="$(readlink "$target_link")"
      if [[ "$existing" == "$link_target" ]]; then
        echo "  [skip]   $rel_target — symlink already correct"
        COUNT_SKIP=$((COUNT_SKIP + 1))
        continue
      fi
      if [[ "$FORCE" != true ]]; then
        echo "  [warn]   $rel_target — symlink exists but points to '$existing'; use --force to retarget" >&2
        COUNT_WARN=$((COUNT_WARN + 1))
        continue
      fi
      if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] would retarget symlink $rel_target -> $link_target"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
        continue
      fi
      rm -f "$target_link"
      ln -s "$link_target" "$target_link"
      echo "  [update] $rel_target — retargeted symlink"
      COUNT_UPDATE=$((COUNT_UPDATE + 1))
      continue
    fi

    if [[ -e "$target_link" ]]; then
      if [[ "$FORCE" != true ]]; then
        echo "  [warn]   $rel_target — non-symlink path exists; use --force to replace" >&2
        COUNT_WARN=$((COUNT_WARN + 1))
        continue
      fi
      if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] would replace $rel_target with symlink -> $link_target"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
        continue
      fi
      mkdir -p "$target_abs"
      rm -rf "$target_link"
      ln -s "$link_target" "$target_link"
      echo "  [force]  $rel_target — replaced with symlink"
      COUNT_UPDATE=$((COUNT_UPDATE + 1))
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "  [dry-run] would link $rel_target -> $link_target"
      COUNT_CREATE=$((COUNT_CREATE + 1))
      continue
    fi
    mkdir -p "$target_abs"
    ln -s "$link_target" "$target_link"
    echo "  [link]   $rel_target -> $link_target"
    COUNT_CREATE=$((COUNT_CREATE + 1))
  done
}

echo "Setting up ai-rules platform stubs..."
echo ""

IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"
for platform in "${PLATFORM_LIST[@]}"; do
  platform="$(echo "$platform" | tr -d '[:space:]')"
  [[ -z "$platform" ]] && continue

  if ! lookup_platform "$platform"; then
    echo "Unknown platform: $platform (skipping)" >&2
    echo "  Run with --list to see supported platforms." >&2
    echo ""
    COUNT_WARN=$((COUNT_WARN + 1))
    continue
  fi

  echo "$platform:"
  write_stub "$PROJECT_ROOT/$PL_PATH" "$STUBS_DIR/$PL_TEMPLATE" "$platform" "$PL_PATH"
  if [[ "$NO_SKILLS" != true ]] && lookup_skills "$platform"; then
    wire_skills_for_platform "$platform" "$SK_DIR" "$SK_MODE"
  fi
  echo ""
done

echo "Summary: $COUNT_CREATE created, $COUNT_UPDATE updated, $COUNT_SKIP skipped, $COUNT_WARN warnings."
if [[ "$DRY_RUN" == true ]]; then
  echo "(dry-run: no files were written)"
else
  echo "Done. Review the generated files and commit them to your project."
fi
