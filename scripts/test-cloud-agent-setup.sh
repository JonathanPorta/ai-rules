#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

copy_repo_without_git() {
  local destination="$1"
  mkdir -p "$destination"
  tar -C "$REPO_ROOT" --exclude='./.git' --exclude='.git' -cf - . |
    tar -C "$destination" -xf -
}

# A normal setup run from the canonical repository root would otherwise treat
# the repository's parent as PROJECT_ROOT. It must fail before previewing or
# writing any repository-level integration target.
guard_log="$TMP_DIR/root-guard.log"
if (cd "$REPO_ROOT" && ./setup.sh --platforms copilot --dry-run >"$guard_log" 2>&1); then
  echo "FAIL: setup.sh accepted a write-mode run outside a consumer .ai-rules directory" >&2
  exit 1
fi
grep -qF "must be run from a consumer repository's .ai-rules/ directory" "$guard_log"

CONSUMER="$TMP_DIR/consumer"
copy_repo_without_git "$CONSUMER/.ai-rules"
cd "$CONSUMER"

SOURCE_AGENT=".ai-rules/.github/agents/implementer-cloud.agent.md"
TARGET_AGENT=".github/agents/implementer-cloud.agent.md"
EXPECTED_LINK="../../.ai-rules/.github/agents/implementer-cloud.agent.md"
SETUP=".ai-rules/setup.sh"

help_out="$($SETUP --help)"
echo "$help_out" | grep -qF 'Native-agent states: linked / copied /'
echo "$help_out" | grep -qF 'DRIFT / missing / NOT OURS'

first_out="$($SETUP --platforms copilot)"
echo "$first_out"
[[ -L "$TARGET_AGENT" ]] || {
  echo "FAIL: Copilot setup did not create the native-agent symlink" >&2
  exit 1
}
[[ "$(readlink "$TARGET_AGENT")" == "$EXPECTED_LINK" ]] || {
  echo "FAIL: $TARGET_AGENT points to $(readlink "$TARGET_AGENT")" >&2
  exit 1
}
[[ -f "$TARGET_AGENT" ]] || {
  echo "FAIL: native-agent symlink does not resolve" >&2
  exit 1
}
[[ -f .ai-rules/AGENTS.md ]] || {
  echo "FAIL: consumer rule root is missing .ai-rules/AGENTS.md" >&2
  exit 1
}
[[ -f .ai-rules/agents/implementer.md ]] || {
  echo "FAIL: consumer full-workflow contract is missing" >&2
  exit 1
}

grep -qF '.ai-rules/AGENTS.md' "$TARGET_AGENT"
grep -qF '.ai-rules/agents/implementer.md' "$TARGET_AGENT"
grep -qF 'AI_RULES_ROOT' "$TARGET_AGENT"

second_out="$($SETUP --platforms copilot)"
echo "$second_out"
echo "$second_out" | grep -qF "$TARGET_AGENT — symlink already correct"

snapshot() {
  find . -path ./.ai-rules -prune -o \( -type f -o -type l \) -print | sort | while IFS= read -r path; do
    if [[ -L "$path" ]]; then
      printf 'L %s -> %s\n' "$path" "$(readlink "$path")"
    else
      sha1sum "$path"
    fi
  done
}

before="$(snapshot)"
check_out="$($SETUP --check --platforms copilot)"
after="$(snapshot)"
echo "$check_out"
[[ "$before" == "$after" ]] || {
  echo "FAIL: --check mutated the consumer tree" >&2
  exit 1
}
echo "$check_out" | grep -qF "$TARGET_AGENT"
echo "$check_out" | grep -qF 'present, linked'
echo "$check_out" | grep -qF 'Native agents: 1 checked, 1 in sync, 0 drifted, 0 missing, 0 not-ours.'

rm "$TARGET_AGENT"
cp "$SOURCE_AGENT" "$TARGET_AGENT"
copy_out="$($SETUP --check --platforms copilot)"
echo "$copy_out"
echo "$copy_out" | grep -qF 'present, copied (in sync)'
repeat_copy_out="$($SETUP --platforms copilot)"
echo "$repeat_copy_out" | grep -qF "$TARGET_AGENT — verified copy is current"

echo 'stale copied profile' > "$TARGET_AGENT"
drift_out="$($SETUP --check --platforms copilot)"
echo "$drift_out"
echo "$drift_out" | grep -qF 'present, DRIFT'

$SETUP --platforms copilot --force >/dev/null
[[ -L "$TARGET_AGENT" ]] || {
  echo "FAIL: --force did not replace a drifted copy with the managed symlink" >&2
  exit 1
}
[[ "$(readlink "$TARGET_AGENT")" == "$EXPECTED_LINK" ]]

grep -qF 'managed symlink is dangling' "$SETUP"

# Force the no-symlink fallback through a cp command that returns success but
# writes incorrect bytes. setup must reject and remove that unverified target.
FALLBACK_CONSUMER="$TMP_DIR/fallback-consumer"
copy_repo_without_git "$FALLBACK_CONSUMER/.ai-rules"
mkdir -p "$FALLBACK_CONSUMER/fake-bin"
cat > "$FALLBACK_CONSUMER/fake-bin/ln" <<'EOF_LN'
#!/bin/sh
exit 1
EOF_LN
cat > "$FALLBACK_CONSUMER/fake-bin/cp" <<'EOF_CP'
#!/bin/sh
printf 'corrupt copy\n' > "$2"
exit 0
EOF_CP
chmod +x "$FALLBACK_CONSUMER/fake-bin/ln" "$FALLBACK_CONSUMER/fake-bin/cp"
cd "$FALLBACK_CONSUMER"
fallback_out="$(PATH="$FALLBACK_CONSUMER/fake-bin:$PATH" .ai-rules/setup.sh --platforms copilot --no-skills 2>&1)"
echo "$fallback_out" | grep -qF "$TARGET_AGENT — failed to install native agent"
[[ ! -e "$TARGET_AGENT" && ! -L "$TARGET_AGENT" ]] || {
  echo "FAIL: setup retained an unverified fallback copy" >&2
  exit 1
}
cd "$CONSUMER"

python3 - "$SOURCE_AGENT" .ai-rules/docs/how-to-use.md <<'PY'
from pathlib import Path
import sys

agent = Path(sys.argv[1]).read_text(encoding="utf-8")
docs = Path(sys.argv[2]).read_text(encoding="utf-8")

required_agent_fragments = [
    "target: github-copilot",
    "disable-model-invocation: true",
    ".ai-rules/AGENTS.md",
    ".ai-rules/agents/implementer.md",
    "For an issue-assigned task",
    "For a prompt-started task",
    "A draft pull request is the durable surface",
]
for fragment in required_agent_fragments:
    if fragment not in agent:
        raise SystemExit(f"FAIL: cloud agent contract missing {fragment!r}")

required_doc_fragments = [
    "## For GitHub Copilot cloud work",
    ".ai-rules/setup.sh --platforms copilot",
    "Do not manually copy the profile",
    "Issue assignment:",
    "Prompt-started task:",
    "and maintain a draft pull request for this task",
    ".ai-rules/setup.sh --check --platforms copilot",
]
for fragment in required_doc_fragments:
    if fragment not in docs:
        raise SystemExit(f"FAIL: cloud-agent docs missing {fragment!r}")
PY

echo "Cloud-agent consumer setup and invocation contract: PASS"
