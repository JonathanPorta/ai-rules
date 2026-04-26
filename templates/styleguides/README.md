# Styleguide Templates

These files are **public examples** of the styleguide overlay system
described in [`rules/11-styleguide-overlays.md`](../../rules/11-styleguide-overlays.md).
They demonstrate the overlay loader format and provide generic placeholder
guidance suitable for forking.

## What lives here

- `styleguides.example.yaml` — example loader config showing the schema
  and how to point at one or more styleguide files.
- `example-voice-styleguide.md` — a generic voice styleguide template you
  can copy and adapt.
- `example-work-styleguide.md` — a generic work-tone styleguide template
  for professional/business contexts.

## What does NOT live here

Private styleguides — your actual personal voice, your employer's tone
guide, client-specific style requirements, or anything confidential —
**must not** be committed to a public repository.

The recommended pattern is:

```text
.ai-local/                       # gitignored (see repo .gitignore)
  styleguides.yaml               # your private loader config
  styleguides/
    voice.md                     # your private voice styleguide
    work-voice.md                # your private work-context styleguide
```

The agent loads `.ai-local/styleguides.yaml` if present and applies any
referenced styleguides that exist on disk. Missing optional styleguides
are skipped silently. See rule 11 for the full loader behavior.

## Using these templates

To bootstrap your own private overlay:

1. Copy `styleguides.example.yaml` to `.ai-local/styleguides.yaml` and edit
   the paths to point at your private files.
2. Copy `example-voice-styleguide.md` to your private location and replace
   the placeholder content with your real voice.
3. Confirm `.ai-local/` is in your `.gitignore`.

The public examples here remain in the repo as reference — keep them
generic so they're useful to forkers.
