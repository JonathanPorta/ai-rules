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

Use `.github/agents/implementer-cloud.agent.md` as the repository-native
profile. In a consumer repository where ai-rules is installed under
`.ai-rules/`, copy or sync that file to the consumer's top-level
`.github/agents/` directory so GitHub can discover it. The profile is
intentionally manual-selection only and targets GitHub Copilot cloud agent.

1. Assign an issue or explicit task whose scope and expected outcome are already
   clear.
2. Select `implementer-cloud` when starting the cloud-agent task.
3. Let the agent choose the lightweight lane only for narrow, unambiguous work
   without API, schema, dependency, security, architecture, migration, or
   deployment changes.
4. Require the full PRD/task/session workflow for larger work. If those approved
   artifacts do not exist, the cloud agent should leave a draft explanation
   rather than inventing approval.
5. Review the draft pull request, validation evidence, and independent reviewer
   result before accepting or merging it.

The cloud profile may commit to its task branch and maintain a draft pull
request because that remote mutation is explicitly configured by the workflow.
It must never merge, release, deploy, publish packages, or mutate production.

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
