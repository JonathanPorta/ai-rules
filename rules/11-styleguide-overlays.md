# Styleguide Overlays

Styleguide overlays are optional writing-style inputs that can be loaded in
addition to the core AI rules.

This repo must not require private styleguides to exist.

This repo must not include private personal or work styleguides.

## Goals

Styleguide overlays allow a project to use additional writing guidance for:

- README content
- marketing copy
- PR descriptions
- release notes
- Slack posts
- emails
- documentation
- website copy
- user-facing prose

## Privacy Boundary

Do not commit private styleguides to public repositories.

Public repositories may include:

- example styleguides
- schemas
- template config files
- setup instructions

Public repositories must not include:

- private personal voice styleguides
- private work styleguides
- confidential company communication guidance
- client-specific style material

## Optional Loading Behavior

When styleguide overlays are configured:

1. Load `.ai-local/styleguides.yaml` if present.
2. Load any referenced styleguide files that exist.
3. If a referenced styleguide is missing and `required: false`, continue
   without error.
4. If a referenced styleguide is missing and `required: true`, ask the human
   before producing style-sensitive prose.
5. Never invent private styleguide content.
6. Never fail unrelated coding tasks because a private styleguide is
   unavailable.

## Path Resolution

Paths inside `.ai-local/styleguides.yaml` are resolved **relative to the
consuming repository root** — the directory containing `.git/` and (when
ai-rules is installed as a subtree) the `.ai-rules/` directory.

This means:

- A private styleguide at `.ai-local/styleguides/voice.md` is referenced
  as `path: .ai-local/styleguides/voice.md`.
- A public template that ships with ai-rules is referenced as
  `path: .ai-rules/templates/styleguides/example-voice-styleguide.md` —
  not `templates/styleguides/...`, which only works inside the ai-rules
  source repo itself.

Always use forward slashes; do not use absolute paths or `~`.

## Recommended Local Structure

```text
.ai-local/
  styleguides.yaml
  styleguides/
    voice.md
    work-voice.md
```

`.ai-local/` should be gitignored.

## Example Config

```yaml
styleguides:
  - name: voice
    path: .ai-local/styleguides/voice.md
    required: false
  - name: work
    path: .ai-local/styleguides/work-voice.md
    required: false
```

## Public Example Config

Public repos may include:

```text
templates/styleguides/styleguides.example.yaml
```

Example (note the `.ai-rules/` prefix, per the Path Resolution section
above — paths are resolved relative to the consuming repo root, where
ai-rules lives at `.ai-rules/`):

```yaml
styleguides:
  - name: example
    path: .ai-rules/templates/styleguides/example-voice-styleguide.md
    required: false
```

## Agent Behavior

If no styleguide is configured, continue normally.

If a styleguide is configured and available, apply it to prose-writing tasks.

If multiple styleguides are configured, apply the most relevant one for the
requested output.

If styleguides conflict, prefer the most task-specific styleguide.
