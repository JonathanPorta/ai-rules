from pathlib import Path

path = Path("setup.sh")
text = path.read_text(encoding="utf-8")

old_help = """  --check              Validate existing stubs and native agent wiring against
                       this ai-rules version, without writing anything.
                       Reports per platform: matches template / EXTENDED /
                       MODIFIED / missing / NOT OURS. With no --platforms,
                       --check inspects ALL supported platforms (not the
                       ${DEFAULT_PLATFORMS} default used by a normal run).
"""
new_help = """  --check              Validate existing stubs and native agent wiring against
                       this ai-rules version, without writing anything.
                       Stub states: matches template / EXTENDED / MODIFIED /
                       missing / NOT OURS. Native-agent states: linked / copied /
                       DRIFT / missing / NOT OURS. With no --platforms, --check
                       inspects ALL supported platforms (not the
                       ${DEFAULT_PLATFORMS} default used by a normal run).
"""
if old_help not in text:
    raise SystemExit("expected --check help block not found")
text = text.replace(old_help, new_help, 1)

old_warning = """      if [[ \"$FORCE\" != true ]]; then
        echo \"  [warn]   $target_rel — symlink exists but points to '$existing'; use --force to retarget\" >&2
        COUNT_WARN=$((COUNT_WARN + 1))
        continue
      fi
"""
new_warning = """      if [[ \"$FORCE\" != true ]]; then
        if [[ \"$existing\" == \"$link_target\" ]]; then
          echo \"  [warn]   $target_rel — managed symlink is dangling; restore the .ai-rules install or use --force after correcting it\" >&2
        else
          echo \"  [warn]   $target_rel — symlink points to '$existing' instead of '$link_target'; use --force to retarget\" >&2
        fi
        COUNT_WARN=$((COUNT_WARN + 1))
        continue
      fi
"""
position = text.rfind(old_warning)
if position < 0:
    raise SystemExit("expected native-agent symlink warning block not found")
text = text[:position] + new_warning + text[position + len(old_warning):]

path.write_text(text, encoding="utf-8")
