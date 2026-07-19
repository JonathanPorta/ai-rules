from pathlib import Path

setup_path = Path("setup.sh")
setup = setup_path.read_text(encoding="utf-8")

old_message = '    echo "           Run setup.sh --check after ai-rules upgrades to detect drift."\n'
new_message = '    printf \'           Run %q --check after ai-rules upgrades to detect drift.\\n\' "$0"\n'

if old_message not in setup:
    raise SystemExit("expected hardcoded setup.sh --check fallback message not found")
setup = setup.replace(old_message, new_message, 1)
setup_path.write_text(setup, encoding="utf-8")

fixture_path = Path("scripts/test-cloud-agent-setup.sh")
fixture = fixture_path.read_text(encoding="utf-8")

anchor = '''grep -qF 'managed symlink is dangling' "$SETUP"

# Force the no-symlink fallback through a cp command that returns success but
'''
replacement = '''grep -qF 'managed symlink is dangling' "$SETUP"

# Force a successful no-symlink fallback and verify the diagnostic prints the
# actual invocation path rather than a hardcoded command that may not exist.
COPY_FALLBACK_CONSUMER="$TMP_DIR/copy-fallback-consumer"
copy_repo_without_git "$COPY_FALLBACK_CONSUMER/.ai-rules"
mkdir -p "$COPY_FALLBACK_CONSUMER/fake-bin"
cat > "$COPY_FALLBACK_CONSUMER/fake-bin/ln" <<'EOF_COPY_LN'
#!/bin/sh
exit 1
EOF_COPY_LN
chmod +x "$COPY_FALLBACK_CONSUMER/fake-bin/ln"
cd "$COPY_FALLBACK_CONSUMER"
copy_fallback_out="$(PATH="$COPY_FALLBACK_CONSUMER/fake-bin:$PATH" .ai-rules/setup.sh --platforms copilot --no-skills 2>&1)"
echo "$copy_fallback_out" | grep -qF "$TARGET_AGENT — symlink unavailable; installed verified copy"
echo "$copy_fallback_out" | grep -qF 'Run .ai-rules/setup.sh --check after ai-rules upgrades to detect drift.'
[[ -f "$TARGET_AGENT" && ! -L "$TARGET_AGENT" ]] || {
  echo "FAIL: successful fallback did not install a regular-file copy" >&2
  exit 1
}
cmp -s "$SOURCE_AGENT" "$TARGET_AGENT" || {
  echo "FAIL: successful fallback copy differs from the source profile" >&2
  exit 1
}
cd "$CONSUMER"

# Force the no-symlink fallback through a cp command that returns success but
'''

if anchor not in fixture:
    raise SystemExit("expected fallback-test insertion anchor not found")
fixture = fixture.replace(anchor, replacement, 1)
fixture_path.write_text(fixture, encoding="utf-8")
