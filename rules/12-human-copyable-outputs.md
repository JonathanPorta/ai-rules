# Human-Copyable Outputs

When generating text intended to be pasted into another tool, write the
output to a temporary file and provide a clipboard command for the human
to run.

Do not automatically copy to the clipboard unless explicitly asked.

Do not automatically submit, post, publish, push, open PRs, or send messages.

## General Rule

The agent may prepare paste-ready text.

The human performs the final copy, paste, submit, send, publish, PR creation,
or deployment action.

## Destination Format Matrix

| Destination | Required Format | File Extension |
|---|---|---|
| GitHub PR description | GitHub Flavored Markdown | `.md` |
| GitHub issue | GitHub Flavored Markdown | `.md` |
| GitHub release notes | GitHub Flavored Markdown | `.md` |
| Slack post | Slack `mrkdwn` | `.txt` |
| Email | Plain text or HTML, as requested | `.txt` / `.html` |

## Filename Convention

All copyable-output temp files prefix with `ai-` for easy globbing and
cleanup. Include a timestamp so multiple drafts coexist:

```text
/tmp/ai-{repo-name}-pr-description-{YYYYMMDD-HHMMSS}.md
/tmp/ai-{topic-or-project}-slack-post-{YYYYMMDD-HHMMSS}.txt
/tmp/ai-{topic}-{kind}-{YYYYMMDD-HHMMSS}.{ext}
```

## Clipboard Commands

Pick the command matching the human's environment:

| Platform | Copy command |
|---|---|
| macOS | `pbcopy` |
| Linux (X11) | `xclip -selection clipboard` |
| Linux (Wayland) | `wl-copy` |
| Linux (no clipboard tool) | `xsel --clipboard --input` |
| Windows (Git Bash, WSL, Cygwin) | `clip.exe` |

The agent picks the one matching the human's environment when known. If the
environment is unknown, default to `pbcopy` and note the alternatives.

## Pull Request Descriptions

When asked to generate a PR description:

1. Use GitHub Flavored Markdown.
2. Write the PR description to a temporary markdown file using the filename
   convention above.
3. Do not open the PR.
4. Do not run `gh pr create`.
5. Provide a command the human can run to copy it.

Example:

```bash
cat /tmp/ai-ai-rules-pr-description-20260426-103045.md | pbcopy
```

## Slack Posts

When asked to generate a Slack post:

1. Use Slack `mrkdwn`, not GitHub Flavored Markdown.
2. Write the Slack post to a temporary file using the filename convention.
3. Do not post the message automatically.
4. Provide a command the human can run to copy it.

Example:

```bash
cat /tmp/ai-release-announcement-slack-post-20260426-103045.txt | pbcopy
```

## Slack Formatting Reminders

Slack `mrkdwn` is not GitHub Markdown.

Use:

```text
*bold*
_italic_
`inline code`
~strikethrough~
```

Use links like:

```text
<https://example.com|link label>
```

Use triple backticks for code blocks.

Avoid GitHub tables for Slack posts.

Prefer simple bullets and short sections.
