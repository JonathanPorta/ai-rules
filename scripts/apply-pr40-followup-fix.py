from pathlib import Path

path = Path("setup.sh")
text = path.read_text(encoding="utf-8")

lookup_block = '''lookup_skills() {
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
'''

guard_block = '''
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
'''

if guard_block.strip() not in text:
    if lookup_block not in text:
        raise SystemExit("lookup_skills block not found")
    text = text.replace(lookup_block, lookup_block + guard_block, 1)

call_anchor = '''if [[ "$PLATFORMS" == "all" ]]; then
  PLATFORMS="$(supported_names)"
fi

if [[ ! -f "$AGENTS_MD" ]]; then
'''
call_replacement = '''if [[ "$PLATFORMS" == "all" ]]; then
  PLATFORMS="$(supported_names)"
fi

validate_consumer_install_root

if [[ ! -f "$AGENTS_MD" ]]; then
'''
if "validate_consumer_install_root\n\nif [[ ! -f \"$AGENTS_MD\" ]]" not in text:
    if call_anchor not in text:
        raise SystemExit("consumer guard call anchor not found")
    text = text.replace(call_anchor, call_replacement, 1)

old_copy = '''  rm -f "$target_link" 2>/dev/null || true
  if cp "$source_abs" "$target_link"; then
    AGENT_INSTALL_MODE="copy"
    return 0
  fi

  return 1
'''
new_copy = '''  rm -f "$target_link" 2>/dev/null || true
  if cp "$source_abs" "$target_link" && cmp -s "$source_abs" "$target_link"; then
    AGENT_INSTALL_MODE="copy"
    return 0
  fi

  # A command can report success while leaving an incomplete or altered file
  # (for example, an interrupted or wrapper-provided copy). Never retain or
  # describe that target as verified.
  rm -f "$target_link" 2>/dev/null || true
  return 1
'''
if new_copy not in text:
    if old_copy not in text:
        raise SystemExit("native-agent copy fallback block not found")
    text = text.replace(old_copy, new_copy, 1)

path.write_text(text, encoding="utf-8")
