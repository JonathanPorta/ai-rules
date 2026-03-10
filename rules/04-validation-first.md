# Validation-First Development

## The Rule

Before writing any implementation code for a task, you MUST define how you will
validate that the task is correctly completed. This is non-negotiable.

## Why

- Forces clear thinking about expected behavior before coding.
- Prevents "it compiles therefore it works" false confidence.
- Creates a contract the implementation must satisfy.
- Makes it impossible to silently skip edge cases.
- Catches misunderstandings BEFORE code is written, when they are cheap to fix.

## Process (Per Task)

### Step 1: Write the Validation Plan

Before touching any implementation file, produce a validation plan for the task.

```markdown
### Task 2.0: Implement profile update API

**Pre-implementation validation plan:**

1. **Tests exist and fail (red):**
   - Write test: PUT /api/users/1 with valid data -> expects 200 with updated record
   - Write test: PUT /api/users/1 with empty name -> expects 422 with field error
   - Write test: PUT /api/users/999 -> expects 404
   - Run: `npm test -- users.test.ts` -> expect 3 failures

2. **After implementation (green):**
   - Run: `npm test -- users.test.ts` -> expect 3 passes
   - Manual: `curl -X PUT .../api/users/1 -d '{"name":""}' ` -> 422
   - Verify: No TypeScript errors (`npx tsc --noEmit`)
   - Verify: Lint passes (`npm run lint`)

3. **Boundary checks:**
   - SQL injection attempt in name field -> properly escaped/rejected
   - 10,000 character name -> rejected with 422
   - Missing auth token -> 401
```

### Step 2: Present for Review (Optional Gate)

Present the validation plan to the human. If the human has opted into
auto-proceed for this workflow, skip to Step 3.

To opt into auto-proceed, the human says something like:
- "Auto-proceed on validation plans"
- "Skip validation review, I trust you"
- "Go ahead without checking with me on each task"

The default is to present and wait. When in doubt, present.

### Step 3: Write Tests First (When Applicable)

If the validation involves automated tests:

1. Write the test files BEFORE the implementation.
2. Run them.
3. Confirm they fail for the right reasons (not due to syntax errors or import
   issues — they should fail because the functionality does not exist yet).

If the project has no test infrastructure, flag this:

> "No test runner is configured in this project. Should I set one up before
> proceeding, or should validation be manual-only for this feature?"

### Step 4: Implement

Now write the code. The validation plan defines the contract your implementation
must satisfy.

### Step 5: Execute Validation

Run every validation step. Report results using this table format:

```markdown
### Task 2.0 Validation Results

| # | Check                              | Result  | Notes              |
|---|------------------------------------|---------|--------------------|
| 1 | Tests fail before implementation   | PASS    | 3/3 red            |
| 2 | Tests pass after implementation    | PASS    | 3/3 green          |
| 3 | Manual curl returns 422            | PASS    |                    |
| 4 | TypeScript compiles                | PASS    |                    |
| 5 | Lint passes                        | FAIL    | Unused import L:14 |
| 6 | SQL injection escaped              | PASS    |                    |
| 7 | 10k char name rejected             | PASS    | Returns 422        |
| 8 | Missing auth returns 401           | PASS    |                    |
```

### Step 6: Act on Results

**All pass:**
Mark the task complete in the task file (`- [x]`). Proceed to the next task.

**Any fail:**
1. Fix the issue.
2. Re-run ALL validation steps (not just the failed one).
3. Report the updated results table.
4. Only mark complete when all checks pass.

**Cannot validate:**
If a validation step cannot be executed in the current environment (e.g.,
requires a running server, external service, or browser):

> "Cannot validate: [step description]. Reason: [why]. Human verification
> required for this step."

Do not mark the task complete until the human acknowledges the unverifiable step.

**Three-strike escalation:**
If a task fails validation three times, stop and escalate to the human:

1. What you tried (all three attempts).
2. What failed and error output.
3. Your best theory on why.
4. Suggested next steps.

Do not continue attempting. Wait for guidance.

## What Counts as Validation

| Valid | Example |
|-------|---------|
| Test command | `npm test -- users.test.ts` passes |
| CLI command with expected output | `curl -s ... \| jq .status` returns `"ok"` |
| File state check | `src/routes.ts` contains entry for `/profile` |
| Type check | `npx tsc --noEmit` exits 0 |
| Lint check | `npm run lint` exits 0 |
| Build check | `npm run build` exits 0 |
| Database query | Query returns expected rows after operation |
| Process exit code | Command exits with expected code |

## What Does NOT Count as Validation

| Invalid | Why |
|---------|-----|
| "Verify it works correctly" | Not observable or specific |
| "Check that the component renders" | No expected outcome defined |
| "Ensure proper error handling" | Vague — which errors? what handling? |
| Reading the code and deciding it looks right | Self-assessment, not proof |
| "It compiles" | Necessary but not sufficient |
| "No errors in the console" | Absence of evidence is not evidence of absence |
