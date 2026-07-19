#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Generate platform-specific stubs and native integrations that
# reference the versioned .ai-rules/ subtree.
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
# Native skills and agents are linked back into the versioned subtree; where
# agent symlinks are unavailable, setup installs a verified copy whose drift is
# reported by --check.
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

# Native platform-agent wiring. The source remains inside the versioned
# .ai-rules dependency while the target lives at the repository-level discovery
# path required by the platform.
#
# platform|source_relative_to_ai_rules|target_relative_to_project|relative_link_target
NATIVE_AGENTS_TABLE=(
  "copilot|.github/agents/implementer-cloud.agent.md|.github/agents/implementer-cloud.agent.md|../../.ai-rules/.github/agents/implementer-cloud.agent.md"
)

COUNT_CREATE=0
COUNT_UPDATE=0
COUNT_SKIP=0
COUNT_WARN=0

usage() {
  local exit_code="${1:-0}"
  cat <<EOF_USAGE
Usage: $(basename "$0") [OPTIONS]

Generate platform-specific config stubs that reference ${RULES_REL}/.

Options:
  --platforms <list>   Comma-separated platforms, e.g. claude,copilot,cursor.
                       Use 'all' for every supported platform, or run --list
                       to see the full set. Defaults to: ${DEFAULT_PLATFORMS}.
  --list               List supported platforms and exit.
  --check              Validate existing stubs and native agent wiring against
                       this ai-rules version, without writing anything.
                       Stub states: matches template / EXTENDED / MODIFIED /
                       missing / NOT OURS. Native-agent states: linked / copied /
                       DRIFT / missing / NOT OURS. With no --platforms, --check
                       inspects ALL supported platforms (not the
                       ${DEFAULT_PLATFORMS} default used by a normal run).
  --dry-run            Show what would happen without writing files.
  --force              Overwrite or retarget managed stubs, skill links, and
                       native agent targets. Use when you intentionally want to
                       replace a drifted or foreign target.
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
  $(basename "$0") --check                           # validate all integrations
  $(basename "$0") --check --platforms copilot       # validate Copilot only
EOF_USAGE
  exit "$exit_code"
}

list_platforms() {
  echo "Supported platforms:"
  local row name desc skills_label
  local agent_row agent_platform _source_rel target_rel _link_target
  local agent_names agent_name
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

    agent_names=""
    for agent_row in "${NATIVE_AGENTS_TABLE[@]}"; do
      IFS='|' read -r agent_platform _source_rel target_rel _link_target <<< "$agent_row"
      [[ "$agent_platform" == "$name" ]] || continue
      agent_name="$(basename "$target_rel")"
      agent_names="${agent_names:+$agent_names, }$agent_name"
    done
    if [[ -n "$agent_names" ]]; then
      printf "  %-10s   agents: %s\n" "" "$agent_names"
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

# Classify a single stub against its template. Sets CHK_STATUS to one of:
#   matches | extended | modified | missing | not-ours
# Returns 0 normally; returns 1 only on an internal error (template missing
# from the install) so the caller can surface a non-zero exit.
#
# extended vs modified hinges on the "… below this line" marker in the
# template: the stub must match the template byte-for-byte up to and including
# that marker. Identical above the marker with extra content below → extended;
# any drift above the marker → modified.
check_platform() {
  local abs_path="$1" template_file="$2"
  CHK_ERROR=""

  # Internal errors (return 1): the template must ship with the install and be
  # readable. These are environment problems, not stub-drift findings.
  if [[ ! -f "$template_file" ]]; then
    CHK_ERROR="template missing from install: $template_file"
    return 1
  fi
  if [[ ! -r "$template_file" ]]; then
    CHK_ERROR="template not readable: $template_file"
    return 1
  fi

  if [[ ! -e "$abs_path" && ! -L "$abs_path" ]]; then
    CHK_STATUS="missing"
    return 0
  fi

  # A non-regular file (directory, symlink to dir, etc.) at the stub path is
  # not one of our stubs.
  if [[ ! -f "$abs_path" ]]; then
    CHK_STATUS="not-ours"
    return 0
  fi

  # A regular file we cannot read is an internal error, not a NOT OURS finding
  # — we genuinely can't classify it.
  if [[ ! -r "$abs_path" ]]; then
    CHK_ERROR="stub not readable: $abs_path"
    return 1
  fi

  if ! grep -qF -- "$REFERENCE_MARKER" "$abs_path" 2>/dev/null; then
    CHK_STATUS="not-ours"
    return 0
  fi

  if cmp -s "$template_file" "$abs_path"; then
    CHK_STATUS="matches"
    return 0
  fi

  # Find the marker's line number in the template (templates ship with exactly
  # one such line). The `|| true` keeps a no-match — or head closing the pipe
  # early — from tripping set -e/pipefail; fall back to the whole template if
  # the marker is (unexpectedly) absent.
  local marker_ln n
  marker_ln=$(grep -n -- 'below this line' "$template_file" 2>/dev/null | head -1 || true)
  n="${marker_ln%%:*}"
  [[ "$n" =~ ^[0-9]+$ ]] || n=$(wc -l < "$template_file")

  if diff -q <(head -n "$n" "$template_file") <(head -n "$n" "$abs_path") >/dev/null 2>&1; then
    CHK_STATUS="extended"
  else
    CHK_STATUS="modified"
  fi
  return 0
}

# Classify one native agent target. A relative symlink is preferred; an exact
# copy is also accepted so setup remains usable on filesystems that reject
# symlinks. Copies become DRIFT as soon as the versioned source changes.
check_native_agent() {
  local source_abs="$1" target_abs="$2" expected_link="$3"
  local existing
  AGENT_CHECK_ERROR=""

  if [[ ! -f "$source_abs" ]]; then
    AGENT_CHECK_ERROR="native agent source missing from install: $source_abs"
    return 1
  fi
  if [[ ! -r "$source_abs" ]]; then
    AGENT_CHECK_ERROR="native agent source not readable: $source_abs"
    return 1
  fi

  if [[ ! -e "$target_abs" && ! -L "$target_abs" ]]; then
    AGENT_CHECK_STATUS="missing"
    return 0
  fi

  if [[ -L "$target_abs" ]]; then
    existing="$(readlink "$target_abs")"
    if [[ "$existing" == "$expected_link" && -f "$target_abs" ]]; then
      AGENT_CHECK_STATUS="linked"
    else
      AGENT_CHECK_STATUS="drift"
    fi
    return 0
  fi

  if [[ -f "$target_abs" ]]; then
    if cmp -s "$source_abs" "$target_abs"; then
      AGENT_CHECK_STATUS="copied"
    else
      AGENT_CHECK_STATUS="drift"
    fi
    return 0
  fi

  AGENT_CHECK_STATUS="not-ours"
  return 0
}

# Read-only validation report over $PLATFORMS. Prints a per-platform line and
# a summary; makes no filesystem changes. Returns 1 only on an internal error
# (a template, stub, or native agent source that is missing/unreadable).
run_check() {
  local version platform label abs_path template
  local n_checked=0 n_match=0 n_ext=0 n_mod=0 n_miss=0 n_notours=0
  local internal_error=0
  local agent_row agent_platform source_rel target_rel link_target
  local source_abs target_abs agent_label
  local n_agent_checked=0 n_agent_sync=0 n_agent_drift=0
  local n_agent_missing=0 n_agent_notours=0

  version="unknown"
  if [[ -f "$SCRIPT_DIR/.version" ]]; then
    version=$(grep '^tag=' "$SCRIPT_DIR/.version" 2>/dev/null | cut -d= -f2- || true)
    [[ -n "$version" ]] || version="unknown"
  fi

  echo "Checking platform stubs against ai-rules ${version} templates:"

  IFS=',' read -ra PLATFORM_LIST <<< "$PLATFORMS"
  for platform in "${PLATFORM_LIST[@]}"; do
    platform="$(echo "$platform" | tr -d '[:space:]')"
    [[ -z "$platform" ]] && continue

    if ! lookup_platform "$platform"; then
      echo "Unknown platform: $platform (skipping)" >&2
      echo "  Run with --list to see supported platforms." >&2
      continue
    fi

    abs_path="$PROJECT_ROOT/$PL_PATH"
    template="$STUBS_DIR/$PL_TEMPLATE"

    if ! check_platform "$abs_path" "$template"; then
      echo "  [error]  $platform — ${CHK_ERROR}" >&2
      internal_error=1
    else
      n_checked=$((n_checked + 1))
      case "$CHK_STATUS" in
        matches)  label="present, matches template"; n_match=$((n_match + 1)) ;;
        extended) label="present, EXTENDED";         n_ext=$((n_ext + 1)) ;;
        modified) label="present, MODIFIED";         n_mod=$((n_mod + 1)) ;;
        missing)  label="missing";                   n_miss=$((n_miss + 1)) ;;
        not-ours) label="present, NOT OURS";         n_notours=$((n_notours + 1)) ;;
      esac
      printf "  %-10s %-36s %s\n" "$platform" "$PL_PATH" "$label"
    fi

    for agent_row in "${NATIVE_AGENTS_TABLE[@]}"; do
      IFS='|' read -r agent_platform source_rel target_rel link_target <<< "$agent_row"
      [[ "$agent_platform" == "$platform" ]] || continue
      source_abs="$SCRIPT_DIR/$source_rel"
      target_abs="$PROJECT_ROOT/$target_rel"

      if ! check_native_agent "$source_abs" "$target_abs" "$link_target"; then
        echo "  [error]  $platform agent — ${AGENT_CHECK_ERROR}" >&2
        internal_error=1
        continue
      fi

      n_agent_checked=$((n_agent_checked + 1))
      case "$AGENT_CHECK_STATUS" in
        linked)   agent_label="present, linked";           n_agent_sync=$((n_agent_sync + 1)) ;;
        copied)   agent_label="present, copied (in sync)"; n_agent_sync=$((n_agent_sync + 1)) ;;
        drift)    agent_label="present, DRIFT";            n_agent_drift=$((n_agent_drift + 1)) ;;
        missing)  agent_label="missing";                   n_agent_missing=$((n_agent_missing + 1)) ;;
        not-ours) agent_label="present, NOT OURS";         n_agent_notours=$((n_agent_notours + 1)) ;;
      esac
      printf "  %-10s %-36s %s\n" "" "$target_rel" "$agent_label"
    done
  done

  echo ""
  echo "Summary: ${n_checked} checked, ${n_match} in sync, ${n_ext} extended, ${n_mod} modified, ${n_miss} missing, ${n_notours} not-ours."
  if (( n_agent_checked > 0 )); then
    echo "Native agents: ${n_agent_checked} checked, ${n_agent_sync} in sync, ${n_agent_drift} drifted, ${n_agent_missing} missing, ${n_agent_notours} not-ours."
  fi

  [[ "$internal_error" == 0 ]]
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

# Write-mode setup is only valid from the standard consumer installation
# layout. Without this guard, invoking the canonical repository's root-level
# setup.sh would treat its parent directory as PROJECT_ROOT and write there.
validate_consumer_install_root() {
  local expected="$PROJECT_ROOT/.ai-rules"
  if [[ "$SCRIPT_DIR" != "$expected" ]]; then
    echo "Error: setup.sh must be run from a consumer repository's .ai-rules/ directory before it can write files." >&2
    echo "       Detected script directory: $SCRIPT_DIR" >&2
    echo "       Expected installation path: $expected" >&2
    echo "       Install/update ai-rules first, then run .ai-rules/setup.sh from the consumer repository." >&2
    return 1
  fi
  return 0
}

CHECK=false
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
    --check) CHECK=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    --no-skills) NO_SKILLS=true; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

# --check is read-only and short-circuits before any of the write paths. With
# no --platforms it inspects ALL supported platforms (a deliberate divergence
# from the normal-run ${DEFAULT_PLATFORMS} default). --dry-run is redundant
# with --check, and --force is meaningless for a read-only report.
if [[ "$CHECK" == true ]]; then
  if [[ -z "$PLATFORMS" || "$PLATFORMS" == "all" ]]; then
    PLATFORMS="$(supported_names)"
  fi
  if [[ "$FORCE" == true ]]; then
    echo "Note: --force has no effect with --check (read-only)." >&2
  fi
  if run_check; then
    exit 0
  else
    exit 1
  fi
fi

if [[ -z "$PLATFORMS" ]]; then
  PLATFORMS="$DEFAULT_PLATFORMS"
  echo "No --platforms specified; defaulting to: $PLATFORMS"
  echo "(Run --list for all supported platforms, or --help for usage.)"
  echo ""
fi

if [[ "$PLATFORMS" == "all" ]]; then
  PLATFORMS="$(supported_names)"
fi

validate_consumer_install_root

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

# Create a relative symlink, emitting an actionable warning if the
# filesystem rejects it (Windows without dev-mode, locked-down sandboxes,
# etc.) instead of aborting all of setup via set -e. Returns 0 on success,
# 1 on failure — the caller decides whether to log a success line.
create_skill_symlink() {
  local link_target="$1" target_link="$2" rel_target="$3"
  if ! ln -s "$link_target" "$target_link" 2>/dev/null; then
    echo "  [warn]   $rel_target — failed to create symlink." >&2
    echo "           Your filesystem or OS may not support symlinks." >&2
    echo "           Re-run with --no-skills, enable symlink support, or" >&2
    echo "           create the link manually:" >&2
    echo "             $rel_target -> $link_target" >&2
    COUNT_WARN=$((COUNT_WARN + 1))
    return 1
  fi
  return 0
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
      if create_skill_symlink "$link_target" "$target_link" "$rel_target"; then
        echo "  [update] $rel_target — retargeted symlink"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
      fi
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
      if create_skill_symlink "$link_target" "$target_link" "$rel_target"; then
        echo "  [force]  $rel_target — replaced with symlink"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
      fi
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "  [dry-run] would link $rel_target -> $link_target"
      COUNT_CREATE=$((COUNT_CREATE + 1))
      continue
    fi
    mkdir -p "$target_abs"
    if create_skill_symlink "$link_target" "$target_link" "$rel_target"; then
      echo "  [link]   $rel_target -> $link_target"
      COUNT_CREATE=$((COUNT_CREATE + 1))
    fi
  done
}

# Prefer a relative symlink for a native agent so updates to the .ai-rules
# subtree are immediately visible. If the filesystem rejects symlinks, install
# an exact copy and let --check report future drift.
install_native_agent_target() {
  local source_abs="$1" target_link="$2" link_target="$3"
  AGENT_INSTALL_MODE=""

  if ln -s "$link_target" "$target_link" 2>/dev/null; then
    AGENT_INSTALL_MODE="link"
    return 0
  fi

  rm -f "$target_link" 2>/dev/null || true
  if cp "$source_abs" "$target_link" && cmp -s "$source_abs" "$target_link"; then
    AGENT_INSTALL_MODE="copy"
    return 0
  fi

  # A command can report success while leaving an incomplete or altered file
  # (for example, an interrupted or wrapper-provided copy). Never retain or
  # describe that target as verified.
  rm -f "$target_link" 2>/dev/null || true
  return 1
}

report_native_agent_install() {
  local action="$1" rel_target="$2" link_target="$3" prefix
  case "$action" in
    link)   prefix="  [link]   " ;;
    update) prefix="  [update] " ;;
    force)  prefix="  [force]  " ;;
    *)      prefix="  [$action] " ;;
  esac
  if [[ "$AGENT_INSTALL_MODE" == "link" ]]; then
    echo "${prefix}${rel_target} -> $link_target"
  else
    echo "  [copy]   $rel_target — symlink unavailable; installed verified copy"
    printf '           Run %q --check after ai-rules upgrades to detect drift.\n' "$0"
  fi
}

# Wire native custom-agent profiles into platform discovery paths. Existing
# current symlinks and exact fallback copies are idempotent. Drift or foreign
# content is preserved unless --force explicitly replaces it.
wire_native_agents_for_platform() {
  local platform="$1"
  local row agent_platform source_rel target_rel link_target
  local source_abs target_abs existing

  for row in "${NATIVE_AGENTS_TABLE[@]}"; do
    IFS='|' read -r agent_platform source_rel target_rel link_target <<< "$row"
    [[ "$agent_platform" == "$platform" ]] || continue

    source_abs="$SCRIPT_DIR/$source_rel"
    target_abs="$PROJECT_ROOT/$target_rel"

    if [[ ! -f "$source_abs" ]]; then
      echo "  [warn]   $target_rel — native agent source missing: $source_rel" >&2
      COUNT_WARN=$((COUNT_WARN + 1))
      continue
    fi

    if [[ -L "$target_abs" ]]; then
      existing="$(readlink "$target_abs")"
      if [[ "$existing" == "$link_target" && -f "$target_abs" ]]; then
        echo "  [skip]   $target_rel — symlink already correct"
        COUNT_SKIP=$((COUNT_SKIP + 1))
        continue
      fi
      if [[ "$FORCE" != true ]]; then
        if [[ "$existing" == "$link_target" ]]; then
          echo "  [warn]   $target_rel — managed symlink is dangling; restore the .ai-rules install or use --force after correcting it" >&2
        else
          echo "  [warn]   $target_rel — symlink points to '$existing' instead of '$link_target'; use --force to retarget" >&2
        fi
        COUNT_WARN=$((COUNT_WARN + 1))
        continue
      fi
      if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] would retarget native agent $target_rel -> $link_target"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
        continue
      fi
      rm -f "$target_abs"
      mkdir -p "$(dirname "$target_abs")"
      if install_native_agent_target "$source_abs" "$target_abs" "$link_target"; then
        report_native_agent_install "update" "$target_rel" "$link_target"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
      else
        echo "  [warn]   $target_rel — failed to install native agent" >&2
        COUNT_WARN=$((COUNT_WARN + 1))
      fi
      continue
    fi

    if [[ -e "$target_abs" ]]; then
      if [[ -f "$target_abs" ]] && cmp -s "$source_abs" "$target_abs"; then
        echo "  [skip]   $target_rel — verified copy is current"
        COUNT_SKIP=$((COUNT_SKIP + 1))
        continue
      fi
      if [[ "$FORCE" != true ]]; then
        echo "  [warn]   $target_rel — existing target differs; use --force to replace" >&2
        COUNT_WARN=$((COUNT_WARN + 1))
        continue
      fi
      if [[ "$DRY_RUN" == true ]]; then
        echo "  [dry-run] would replace $target_rel with managed native agent"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
        continue
      fi
      rm -rf "$target_abs"
      mkdir -p "$(dirname "$target_abs")"
      if install_native_agent_target "$source_abs" "$target_abs" "$link_target"; then
        report_native_agent_install "force" "$target_rel" "$link_target"
        COUNT_UPDATE=$((COUNT_UPDATE + 1))
      else
        echo "  [warn]   $target_rel — failed to install native agent" >&2
        COUNT_WARN=$((COUNT_WARN + 1))
      fi
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "  [dry-run] would link native agent $target_rel -> $link_target"
      COUNT_CREATE=$((COUNT_CREATE + 1))
      continue
    fi

    mkdir -p "$(dirname "$target_abs")"
    if install_native_agent_target "$source_abs" "$target_abs" "$link_target"; then
      report_native_agent_install "link" "$target_rel" "$link_target"
      COUNT_CREATE=$((COUNT_CREATE + 1))
    else
      echo "  [warn]   $target_rel — failed to install native agent" >&2
      COUNT_WARN=$((COUNT_WARN + 1))
    fi
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
  wire_native_agents_for_platform "$platform"
  echo ""
done

echo "Summary: $COUNT_CREATE created, $COUNT_UPDATE updated, $COUNT_SKIP skipped, $COUNT_WARN warnings."
if [[ "$DRY_RUN" == true ]]; then
  echo "(dry-run: no files were written)"
else
  echo "Done. Review the generated files and commit them to your project."
fi
