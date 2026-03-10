# PRD Generation Rules

## Trigger

When a human provides a feature request, bug report, or improvement idea.

## Process

1. **Analyze the request.** Identify what is being asked, who it is for, and why
   it matters.

2. **Read the codebase.** Before writing anything, explore the relevant parts of
   the project to understand existing architecture, patterns, conventions, and
   dependencies. List what you examined in the PRD's "Background" section.

3. **Ask clarifying questions.** Present 3-8 questions with lettered options
   (A/B/C/D) for quick response. Always include an open-ended option per question.
   Wait for answers before proceeding.

   Example format:
   ```
   1. What scope should this cover?
      A) Only the API layer
      B) API + UI
      C) Full stack including database migrations
      D) Other: ___

   2. Should this support bulk operations?
      A) No, single-item only for now
      B) Yes, up to 100 items
      C) Yes, unlimited with pagination
      D) Other: ___
   ```

4. **Generate the PRD** using the structure below.

5. **Present acceptance criteria separately** and explicitly ask:

   > "Do these acceptance criteria fully capture what 'done' means for this
   > feature? Please modify, add, or remove criteria before I proceed."

6. **Wait for approval.** Do not proceed to task generation until the human
   explicitly approves the acceptance criteria.

## PRD Structure

```markdown
# PRD: <Feature Name>

## Summary
One paragraph. What is being built and why.

## Background
What exists today. What is wrong or missing. Reference specific files, modules,
and patterns discovered during codebase exploration. Cite file paths.

## Goals
- Bulleted list of what this feature achieves
- Each goal should be measurable or observable

## Non-Goals
- Explicitly out-of-scope items
- Prevents scope creep during implementation

## Architecture & Approach
How this fits into the existing codebase. Specific modules, patterns, integration
points, and dependencies identified during codebase exploration. Include:
- Files to be modified (with rationale)
- New files to be created (with purpose)
- External dependencies or services involved
- Data flow or state changes

## Acceptance Criteria
- [ ] AC-1: <Criterion>
- [ ] AC-2: <Criterion>
- [ ] AC-3: <Criterion>

## Open Questions
Anything unresolved that could affect implementation.
```

## Rules for Acceptance Criteria

### Must be verifiable
Every criterion must allow a human to look at it and answer yes or no.

**Good:**
- "Returns 422 with field-level errors when required fields are missing"
- "Profile changes persist across page reloads"
- "API responds within 200ms for 95th percentile under normal load"

**Bad:**
- "Has proper error handling"
- "Works correctly"
- "Is performant"
- "Handles edge cases"

### Must be specific
Include concrete values, status codes, behaviors, or outcomes where possible.

### Must be testable
If you cannot describe a test (manual or automated) that would verify the
criterion, it is too vague. Rewrite it.

### When the human provides vague criteria
Do not silently accept vague acceptance criteria. Ask the human to sharpen them:

> "AC-3 says 'handles errors gracefully.' Could you specify which errors and
> what the user should see? For example: 'When the API returns 500, the UI
> displays a retry button and a user-friendly error message.'"

### Numbering
Use `AC-1`, `AC-2`, etc. These identifiers are referenced throughout the task
list and final verification. They must remain stable once approved.
