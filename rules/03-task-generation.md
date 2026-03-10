# Task Generation Rules

## Trigger

An approved PRD with finalized acceptance criteria.

## Process

1. **Read the PRD acceptance criteria.** Every task must trace back to at least
   one acceptance criterion. If a task does not serve an AC, it must justify its
   inclusion (infrastructure, testing setup, refactoring prerequisite, etc.).

2. **Explore the codebase.** Identify existing files, patterns, utilities, and
   test infrastructure that will be used or modified. Do not guess file paths.
   Read and confirm they exist.

3. **Generate parent tasks.** Present them to the human for review. Include the
   AC mapping. Wait for confirmation before proceeding.

   > "I have generated the high-level tasks based on your approved PRD. Please
   > review the breakdown and AC mapping. Respond with 'Go' to proceed to
   > detailed sub-tasks, or suggest changes."

4. **Generate sub-tasks with validation criteria.** Each parent task gets a
   "Validates when" block defining observable proof of completion.

5. **Save** to `tasks/tasks-<feature-name>.md`.

## Output Format

The generated task list MUST follow this structure:

```markdown
# Tasks: <Feature Name>

> Generated from [PRD: <Feature Name>](prd-<feature-name>.md)

## Acceptance Criteria Traceability

| AC   | Criterion (short description)           | Tasks        |
|------|-----------------------------------------|--------------|
| AC-1 | Users can edit their profile            | 1.0, 2.0     |
| AC-2 | Invalid input returns 422               | 3.0, 4.0     |
| AC-3 | Changes persist across reloads          | 2.0, 5.0     |

## Relevant Files

(Identified by reading the codebase, not guessing)

- `src/api/users.ts` — Existing user API, will be modified for [reason]
- `src/api/users.test.ts` — Corresponding tests
- `src/components/ProfileForm.tsx` — New file for [purpose]
- `src/components/ProfileForm.test.tsx` — Tests for ProfileForm

### Notes
- Test files live alongside the source files they test.
- Run tests with: `[project-specific test command]`

## Tasks

- [ ] 1.0 <Parent Task Title>                           <- Serves: AC-1
  - [ ] 1.1 [Sub-task description]
  - [ ] 1.2 [Sub-task description]
  - [ ] 1.3 [Sub-task description]
  - **Validates when:**
    - <observable outcome 1>
    - <observable outcome 2>
    - <test command with expected result>

- [ ] 2.0 <Parent Task Title>                           <- Serves: AC-1, AC-3
  - [ ] 2.1 [Sub-task description]
  - [ ] 2.2 [Sub-task description]
  - **Validates when:**
    - <observable outcome>
    - <test command with expected result>

- [ ] 3.0 <Parent Task Title>                           <- Serves: AC-2
  - [ ] 3.1 [Sub-task description]
  - **Validates when:**
    - <specific input> -> <expected output>
    - <edge case input> -> <expected error>
```

## Rules for Validation Criteria

### Ownership
Validation criteria are written by the AI, not the human. The human may review
and adjust them, but the AI is responsible for proposing them.

### Must be observable
Every validation criterion must describe something that can be seen, measured,
or checked — not inferred.

**Good:**
- `npm test -- users.test.ts` passes with 0 failures
- `PUT /api/users/1 {"name": ""}` returns 422 with `{"errors": {"name": "required"}}`
- File `src/config/routes.ts` contains a route entry for `/profile`
- `npx tsc --noEmit` exits with code 0

**Bad:**
- "Verify the component renders correctly"
- "Ensure error handling is in place"
- "Check that it works"

### Must be specific
Include exact inputs, expected outputs, status codes, file paths, and command
invocations.

### Must be executable
The AI must be able to actually run or check these after implementation. If a
validation requires a running server that cannot be started in the current
environment, flag it explicitly and provide an alternative.

### Minimum coverage
At least one validation criterion per parent task. Complex tasks should have
multiple criteria covering the happy path, error cases, and boundary conditions.

## Handling Orphan Tasks

If a task does not map to any acceptance criterion, it must include an explicit
justification:

```markdown
- [ ] 0.0 Set up test infrastructure              <- Prerequisite (no direct AC)
  - [ ] 0.1 Install and configure test runner
  - [ ] 0.2 Create test utilities and fixtures
  - **Justification:** No test runner exists in the project. Required before
    any task validation can be automated.
  - **Validates when:**
    - `npm test` runs without configuration errors
    - A sample test file executes and reports results
```
