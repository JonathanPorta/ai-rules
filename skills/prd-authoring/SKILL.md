---
name: prd-authoring
description: Generate a Product Requirements Document for a feature request, bug report, product change, or other multi-step engineering work. Use when the human asks to plan a feature, write a PRD, define acceptance criteria, or analyze a codebase before implementation. Stops at acceptance-criteria approval — does not implement code.
allowed-tools: Read, Grep, Glob
model: opus
---

# PRD Authoring

Turn a feature request into an approved PRD with verifiable acceptance
criteria. The full process is defined in `.ai-rules/rules/02-prd.md` —
this skill is the trigger shape and the gate enforcer. Read that rule first.

## When this skill should fire

- Human asks to "plan a feature", "write a PRD", "spec this out", "draft
  requirements", or similar.
- Human pastes a bug report, feature idea, or product brief that needs
  structured decomposition before implementation begins.
- An existing PRD needs sharpened acceptance criteria.

Do not fire for: implementation requests, refactors, code review, or work
where a human-approved PRD already exists.

## Required behavior

Follow `.ai-rules/rules/02-prd.md` exactly. The short version:

1. Explore the codebase first. Produce a written **Codebase Analysis**.
2. Present the analysis. **Wait for the human to confirm it before continuing.**
3. Ask 3–8 clarifying questions with lettered options.
4. Generate the PRD.
5. Present acceptance criteria separately. **Wait for human approval.**
6. Stop. Do not generate tasks or write implementation code.

## Progressive disclosure

Load these references only when you need them:

- `references/codebase-analysis.md` — rubric, common failure modes, and a
  worked example for the Codebase Analysis artifact. Load when producing
  step 1.
- `references/acceptance-criteria.md` — rubric, common failure modes, and
  a worked example for verifiable acceptance criteria. Load when drafting
  step 5 or when sharpening vague human-supplied criteria.

The rule file is the source of truth for the process. References here
exist for taste and calibration; they do not duplicate the rule body.

## Hard gates

These gates are non-negotiable. Stop and prompt the human at each one:

- **Codebase Analysis gate** — do not propose a solution before the human
  confirms your reading of the codebase.
- **Acceptance Criteria gate** — do not proceed past the PRD until the
  human explicitly approves the acceptance criteria.

If the human asks you to skip a gate, refuse and explain why. The whole
point of this skill is to preserve the human gates that the conversational
flow would otherwise erode.

## Out of scope

- Task generation. After AC approval, hand off to a task-breakdown skill
  or equivalent in your runner. This skill ends at "AC approved".
- Implementation. Never edit production code under this skill.
