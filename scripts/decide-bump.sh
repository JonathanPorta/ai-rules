#!/usr/bin/env bash
set -euo pipefail

# decide-bump.sh — decide the semver bump for a release from PR labels,
# falling back to commit-message prefixes when no version label is present.
#
# Usage:
#   printf '%s\n' "$LABELS" | BUMP_COMMITS="$COMMITS" scripts/decide-bump.sh
#
# Input:
#   stdin           PR labels, one per line (collected from every PR merged
#                   since the last release tag). Blank/unrelated lines are
#                   ignored.
#   $BUMP_COMMITS   (optional) newline-separated commit messages since the
#                   last tag, used only as a fallback when no version label
#                   is found.
#
# Output (stdout): exactly one of: major | minor | patch
#
# Label precedence (highest wins): major > minor > patch. Recognized label
# forms are case-insensitive and match a whole line:
#   version: major / version:major
#   version: minor / version:minor
#   version: patch / version:patch
#
# Only the namespaced `version:` labels are release-significant. Bare
# `major`/`minor`/`patch` are intentionally NOT honored — they are deprecated
# in the Blessed-CICD label standard (its setup-labels template doesn't create
# them and its docs mark them for deletion), so treating them as release
# instructions here would resurrect a label family the portfolio is retiring.
#
# Fallback (no version label) scans $BUMP_COMMITS:
#   BREAKING or major:  → major
#   feat: or minor:     → minor
#   anything else       → patch
#
# This mirrors rules/10-branch-pr-commit-conventions.md: version bumps are
# controlled by PR labels, not commit-message prefixes — the prefix scan is
# only a safety net for PRs that merged without a version label.

LABELS="$(cat)"
labels_lc="$(printf '%s' "$LABELS" | tr '[:upper:]' '[:lower:]')"

# Here-strings (not pipes) keep `grep -q`'s early exit from racing a writer
# into a SIGPIPE that pipefail would surface as a spurious failure.
if grep -qE '^[[:space:]]*version:[[:space:]]*major[[:space:]]*$' <<< "$labels_lc"; then
  echo major
elif grep -qE '^[[:space:]]*version:[[:space:]]*minor[[:space:]]*$' <<< "$labels_lc"; then
  echo minor
elif grep -qE '^[[:space:]]*version:[[:space:]]*patch[[:space:]]*$' <<< "$labels_lc"; then
  echo patch
else
  commits="${BUMP_COMMITS:-}"
  if grep -qiE '(BREAKING|major:)' <<< "$commits"; then
    echo major
  elif grep -qiE '(feat:|minor:)' <<< "$commits"; then
    echo minor
  else
    echo patch
  fi
fi
