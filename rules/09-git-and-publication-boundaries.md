# Git and Publication Boundaries

AI agents may prepare local changes, commits, summaries, PR descriptions,
release notes, and human-run commands.

AI agents must not perform publication or remote-mutating actions from an
interactive session.

## Prohibited Actions

The agent must not execute publication-class or remote-mutating commands
from an interactive session, even when asked. The agent provides the exact
command for the human to review and run; the human is the only path to the
remote.

Specifically, the agent must not run:

- `git push`
- `git push --force`
- `git push --force-with-lease`
- `gh pr create`
- `gh pr merge`
- `gh release create`
- package publishing commands such as `npm publish`, `poetry publish`,
  `twine upload`, or equivalent
- container publishing commands such as `docker push`
- deployment commands
- infrastructure mutation commands such as `terraform apply`
- any command that publishes, uploads, deploys, releases, or mutates remote
  state

## Interactive Session Boundary

Interactive AI sessions may prepare work for human review.

Interactive AI sessions must not:

- push branches
- open PRs
- merge PRs
- publish releases
- deploy
- mutate production or shared remote environments

Cloud or CI-based agents may open PRs only when explicitly configured as part
of a trusted automation workflow.

## No LLM Attribution

AI agents must not add LLM attribution to:

- commit messages
- commit trailers
- PR titles
- PR descriptions
- generated changelog entries
- release notes
- code comments
- documentation
- generated project artifacts

Do not include phrases like:

- `Generated with Claude`
- `Generated with ChatGPT`
- `Generated with Copilot`
- `Co-authored-by: Claude`
- `Co-authored-by: ChatGPT`
- `AI-assisted`
- `LLM-generated`

The human operator is responsible for authorship, review, publication, and
submission.

## Human-Owned Final Actions

The agent provides commands for the human to run.

The human performs every copy, paste, submit, send, publish, push, PR
creation, merge, release, and deployment action. There is no "but the
human said it was OK" exception — if the action mutates a remote, the
human types the command.

## Relationship to other rules

- `rules/07-command-surface.md` defines the canonical command surface for a
  project (Makefile or equivalent). This rule is about *who* runs the
  publication-class commands, not about how they're invoked.
- `rules/12-human-copyable-outputs.md` describes the output format for prose
  the human will paste into another tool (PR descriptions, Slack posts,
  release notes). This rule's "no auto-publish" boundary is what makes that
  paste-ready format necessary.
