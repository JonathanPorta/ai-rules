# AI Development Rules

These rules govern how AI agents approach feature development in this project.
They are **mandatory** — not suggestions.

Read and internalize ALL rules before beginning any feature work.

## Rule Index

1. [Workflow Overview](rules/01-workflow-overview.md) — The end-to-end process
2. [PRD Generation](rules/02-prd.md) — How to produce a Product Requirements Document
3. [Task Generation](rules/03-task-generation.md) — How to decompose a PRD into tasks
4. [Validation-First Development](rules/04-validation-first.md) — Writing validation before code
5. [Task Execution](rules/05-task-execution.md) — How to implement and verify tasks

## Core Principles

1. **Nothing ships without acceptance criteria.** Every feature has human-approved
   acceptance criteria before any code is written.

2. **Validation before implementation.** For every task, define how you will prove
   it works BEFORE writing the code.

3. **Observable proof over self-assessment.** "It works" is not validation. Show a
   test passing, a command output, or a verifiable state change.

4. **Human owns acceptance, AI owns validation.** The human defines what "done"
   means. The AI defines how to prove each step got there.

5. **Fail loudly.** If validation fails, stop. Do not mark the task complete. Do
   not proceed to the next task. Report what failed and why.

6. **Read before you write.** Always explore the existing codebase before proposing
   changes. Never guess at file paths, patterns, or architecture.

7. **Scope is sacred.** Do not add, remove, or modify acceptance criteria without
   human approval. If you discover unplanned work, surface it — don't silently do it.
