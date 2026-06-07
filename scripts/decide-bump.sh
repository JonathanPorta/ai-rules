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
#   major          / minor          / patch          (bare)
#   version: major / version: minor  / version: patch (namespaced)
#   version:major  / version:minor   / version:patch  (namespaced, no space)
#
# Both forms are accepted on purpose. Blessed-CICD's live PR-label validator
# (templates/.github/workflows/pr-labels.yml) requires a BARE major/minor/patch
# label and nags contributors to add one — so honoring bare labels makes the
# label the portfolio already mandates actually drive the release bump (closing
# the "false affordance" gap its docs/labels.md describes). The namespaced
# `version:` form is also accepted for forward-compatibility in case the
# standard later disambiguates these from priority/size labels. See
# https://github.com/JonathanPorta/blessed-cicd (label docs vs. validator
# inconsistency tracked upstream).
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
if grep -qE '^[[:space:]]*(version:[[:space:]]*major|major)[[:space:]]*$' <<< "$labels_lc"; then
  echo major
elif grep -qE '^[[:space:]]*(version:[[:space:]]*minor|minor)[[:space:]]*$' <<< "$labels_lc"; then
  echo minor
elif grep -qE '^[[:space:]]*(version:[[:space:]]*patch|patch)[[:space:]]*$' <<< "$labels_lc"; then
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
