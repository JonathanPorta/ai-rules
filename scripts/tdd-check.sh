#!/usr/bin/env bash
#
# tdd-check.sh — Verify TDD ordering by comparing git commit timestamps
#
# Checks that a test file was committed before or at the same time as its
# corresponding implementation file. This is a supplementary check — it does
# not replace the red-then-green evidence requirement in rules/08-tdd-enforcement.md.
#
# Usage:
#   ./scripts/tdd-check.sh <implementation-file> <test-file>
#
# Examples:
#   ./scripts/tdd-check.sh src/api/users.ts src/api/users.test.ts
#   ./scripts/tdd-check.sh lib/utils.py tests/test_utils.py
#
# Exit codes:
#   0 — TDD order confirmed (test committed before or with implementation)
#   1 — TDD violation detected (implementation committed before tests)
#   2 — Usage error or missing files

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

usage() {
  echo "Usage: $0 <implementation-file> <test-file>"
  echo ""
  echo "Compares git commit timestamps to verify TDD ordering."
  echo "The test file should be committed before or with the implementation file."
  exit 2
}

# Validate arguments
if [[ $# -ne 2 ]]; then
  usage
fi

IMPL_FILE="$1"
TEST_FILE="$2"

# Check we're in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo -e "${RED}Error: Not inside a git repository${NC}"
  exit 2
fi

# Check files exist in git history
if ! git log -1 --format="%at" -- "$IMPL_FILE" &>/dev/null || \
   [[ -z "$(git log -1 --format="%at" -- "$IMPL_FILE" 2>/dev/null)" ]]; then
  echo -e "${YELLOW}Warning: $IMPL_FILE has no git history (not yet committed)${NC}"
  echo "Cannot verify TDD ordering until both files are committed."
  exit 2
fi

if ! git log -1 --format="%at" -- "$TEST_FILE" &>/dev/null || \
   [[ -z "$(git log -1 --format="%at" -- "$TEST_FILE" 2>/dev/null)" ]]; then
  echo -e "${YELLOW}Warning: $TEST_FILE has no git history (not yet committed)${NC}"
  echo "Cannot verify TDD ordering until both files are committed."
  exit 2
fi

# Get the timestamp of the first commit touching each file
IMPL_FIRST_COMMIT=$(git log --diff-filter=A --format="%at" -- "$IMPL_FILE" | tail -1)
TEST_FIRST_COMMIT=$(git log --diff-filter=A --format="%at" -- "$TEST_FILE" | tail -1)

# Fallback: if --diff-filter=A returns nothing (file existed before history),
# use the earliest commit that touched the file
if [[ -z "$IMPL_FIRST_COMMIT" ]]; then
  IMPL_FIRST_COMMIT=$(git log --format="%at" -- "$IMPL_FILE" | tail -1)
fi

if [[ -z "$TEST_FIRST_COMMIT" ]]; then
  TEST_FIRST_COMMIT=$(git log --format="%at" -- "$TEST_FILE" | tail -1)
fi

# Format timestamps for human display
IMPL_DATE=$(git log --diff-filter=A --format="%ai" -- "$IMPL_FILE" | tail -1)
TEST_DATE=$(git log --diff-filter=A --format="%ai" -- "$TEST_FILE" | tail -1)

if [[ -z "$IMPL_DATE" ]]; then
  IMPL_DATE=$(git log --format="%ai" -- "$IMPL_FILE" | tail -1)
fi

if [[ -z "$TEST_DATE" ]]; then
  TEST_DATE=$(git log --format="%ai" -- "$TEST_FILE" | tail -1)
fi

# Compare timestamps
if [[ "$TEST_FIRST_COMMIT" -le "$IMPL_FIRST_COMMIT" ]]; then
  echo -e "${GREEN}✅ Test file was committed before or with implementation${NC}"
  echo "   Test file:      $TEST_FILE (first committed: $TEST_DATE)"
  echo "   Implementation: $IMPL_FILE (first committed: $IMPL_DATE)"
  exit 0
else
  echo -e "${RED}⚠️  Implementation was committed before tests — TDD violation${NC}"
  echo "   Implementation: $IMPL_FILE (first committed: $IMPL_DATE)"
  echo "   Test file:      $TEST_FILE (first committed: $TEST_DATE)"
  exit 1
fi
