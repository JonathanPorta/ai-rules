from pathlib import Path

setup_path = Path("setup.sh")
setup = setup_path.read_text(encoding="utf-8")

old_block = '''    if [[ -e "$target_abs" ]]; then
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
'''

new_block = '''    if [[ -e "$target_abs" ]]; then
      # Match write_stub's safety boundary: even --force must not recursively
      # remove directories, FIFOs, sockets, or other unexpected target types.
      if [[ ! -f "$target_abs" ]]; then
        echo "  [warn]   $target_rel — target exists but is not a regular file; refusing to replace." >&2
        echo "           Remove or rename it manually before re-running setup." >&2
        COUNT_WARN=$((COUNT_WARN + 1))
        continue
      fi
      if cmp -s "$source_abs" "$target_abs"; then
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
      rm -f "$target_abs"
      mkdir -p "$(dirname "$target_abs")"
'''

if new_block not in setup:
    if old_block not in setup:
        raise SystemExit("expected native-agent replacement block not found")
    setup = setup.replace(old_block, new_block, 1)
setup_path.write_text(setup, encoding="utf-8")

fixture_path = Path("scripts/test-cloud-agent-setup.sh")
fixture = fixture_path.read_text(encoding="utf-8")

anchor = '''[[ "$(readlink "$TARGET_AGENT")" == "$EXPECTED_LINK" ]]

grep -qF 'managed symlink is dangling' "$SETUP"
'''

replacement = '''[[ "$(readlink "$TARGET_AGENT")" == "$EXPECTED_LINK" ]]

# A directory at the native-agent target may contain user data. Even --force
# must refuse it rather than recursively deleting it.
NONREGULAR_CONSUMER="$TMP_DIR/nonregular-consumer"
copy_repo_without_git "$NONREGULAR_CONSUMER/.ai-rules"
cd "$NONREGULAR_CONSUMER"
mkdir -p "$TARGET_AGENT"
printf 'USER-DATA\n' > "$TARGET_AGENT/USER-DATA"
nonregular_out="$(.ai-rules/setup.sh --platforms copilot --force --no-skills 2>&1)"
echo "$nonregular_out" | grep -qF "$TARGET_AGENT — target exists but is not a regular file; refusing to replace."
[[ -d "$TARGET_AGENT" ]] || {
  echo "FAIL: --force replaced the non-regular native-agent target" >&2
  exit 1
}
grep -qF 'USER-DATA' "$TARGET_AGENT/USER-DATA" || {
  echo "FAIL: --force deleted user data inside the native-agent target directory" >&2
  exit 1
}
cd "$CONSUMER"

grep -qF 'managed symlink is dangling' "$SETUP"
'''

if replacement not in fixture:
    if anchor not in fixture:
        raise SystemExit("expected non-regular-target test insertion anchor not found")
    fixture = fixture.replace(anchor, replacement, 1)
fixture_path.write_text(fixture, encoding="utf-8")
