# How to Use

## For engineering work

1. Read `AGENTS.md`.
2. Start with `rules/02-prd.md` for a single feature, or
   `rules/00-project-planning.md` for multi-feature work.
3. Generate a PRD with clear acceptance criteria.
4. Generate tasks.
5. Define validation before implementation.
6. Implement and verify.
7. Preserve session state as work progresses.

## For issue-assigned GitHub Copilot cloud work

Install or refresh the repository-native Copilot profile through the normal
versioned setup path:

```bash
.ai-rules/setup.sh --platforms copilot
```

That command installs the Copilot instruction stub and skills, then links
`.github/agents/implementer-cloud.agent.md` to the canonical profile inside the
`.ai-rules/` subtree. Do not manually copy the profile; `setup.sh` owns the
repository-level target and its drift state. Re-running setup is idempotent, and
`.ai-rules/setup.sh --check --platforms copilot` reports a missing, current, or
drifted agent target. On filesystems that reject symlinks, setup installs a
verified copy; `--check` detects when that copy later drifts from the versioned
source.

1. Start through one of these explicit paths:
   - **Issue assignment:** assign a clear, bounded GitHub issue and select
     `implementer-cloud`. GitHub normally creates the task branch and pull
     request for this path.
   - **Prompt-started task:** include an explicit instruction such as **“Create
     and maintain a draft pull request for this task”**, then select
     `implementer-cloud`. Do not use a branch-only prompt for this workflow.
2. Let the agent establish the draft pull request before implementation and put
   its scope and validation checklist there.
3. Let the agent choose the lightweight lane only for narrow, unambiguous work
   without API, schema, dependency, security, architecture, migration, or
   deployment changes.
4. Require the full PRD/task/session workflow for larger work. If those approved
   artifacts do not exist, the cloud agent should leave a draft explanation
   rather than inventing approval.
5. Review the draft pull request, validation evidence, and independent reviewer
   result before accepting or merging it.

The cloud profile may commit to its task branch and create or maintain its draft
pull request because those remote mutations are explicitly configured by the
workflow. It must never merge, release, deploy, publish packages, or mutate
production.

## For design work

1. Read `AGENTS.md`.
2. Start with `rules/design/31-ux-brief-and-intent.md`.
3. Capture the user, job, success criteria, emotional goal, and constraints.
4. Define information architecture and map the journey.
5. Enumerate the state inventory.
6. Draft screen specs or concepts.
7. Review for trust, feedback, hierarchy, accessibility, and consistency.
8. Save the outputs using the templates in `templates/design/`.

## For critique of an existing product

1. Use `templates/design/visual-audit-template.md`.
2. Organize observations using the template sections:
   - works well
   - UX patterns
   - UI patterns
   - risks
   - lessons
   - copy / adapt / avoid
3. Capture observations in the matching section so the audit follows the documented template.
