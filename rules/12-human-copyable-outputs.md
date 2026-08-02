# Human-Copyable Outputs

When generating text intended to be pasted into another tool, write the
output to a temporary file and provide a clipboard command for the human
to run.

Do not automatically copy to the clipboard. Write the file and provide
a clipboard command for the human to run.

When the human asks only for a draft or copyable output, do not infer authority
to submit, post, publish, push, open a PR, or send it. A direct request to take
one of those actions is governed by
`rules/09-git-and-publication-boundaries.md`; this rule does not revoke an
explicit authorization granted there.

## General Rule

The agent may prepare paste-ready text.

The human performs the final copy, paste, submit, send, publish, PR creation,
or deployment action by default. When the human explicitly asks the agent to
perform that final action, follow the authorization, scope, and preflight
requirements in `rules/09-git-and-publication-boundaries.md`.

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

When asked only to generate or draft a PR description:

1. Use GitHub Flavored Markdown.
2. Write the PR description to a temporary markdown file using the filename
   convention above.
3. Do not open the PR.
4. Do not run `gh pr create`.
5. Provide a command the human can run to copy it.

When asked to open, create, or update the PR, the request authorizes the
bounded publication steps defined by `rules/09-git-and-publication-boundaries.md`,
including a normal feature-branch push and `gh pr create` / `gh pr edit` (or
equivalent). Keep the description in the temporary file when a local filesystem
is available, then use it for the authorized PR operation.

Example:

```bash
cat /tmp/ai-ai-rules-pr-description-20260426-103045.md | pbcopy
```

## Slack Posts

When asked only to generate or draft a Slack post:

1. Use Slack `mrkdwn`, not GitHub Flavored Markdown.
2. Write the Slack post to a temporary file using the filename convention.
3. Do not post the message automatically.
4. Provide a command the human can run to copy it.

When asked to send or post it, follow the explicit-authorization requirements
in `rules/09-git-and-publication-boundaries.md` and any destination-specific
recipient or confirmation rules.

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
