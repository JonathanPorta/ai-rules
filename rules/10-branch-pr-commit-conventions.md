# Branch, PR, and Commit Conventions

This rule defines optional git naming conventions. Enable it only in repos
that want these conventions.

## Branch Names

Preferred branch format:

```text
{initials}/{type}/short-lower-case-hyphenated-name
```

Where `{initials}` is the author's initials (e.g., `jp` for Jonathan Porta)
and `{type}` is one of:

```text
b = bug
f = feature
d = docs
c = chore
h = hotfix
r = release or deploy
```

Examples:

```text
jp/f/add-styleguide-overlays
jp/b/fix-phase-gate-audit
jp/d/update-agent-docs
jp/c/normalize-rule-loading
jp/h/patch-release-command
jp/r/prepare-v1-release
```

## Slug Rules

Branch slugs should:

- be lowercase
- use hyphens between words
- avoid consecutive hyphens
- be short but descriptive
- avoid issue titles pasted verbatim when they are too long

## PR Titles

Preferred PR title format:

```text
{short type all lowercase}: Title Cased Name
```

The PR-title prefix follows
[Conventional Commits](https://www.conventionalcommits.org/) shortened
forms, not the full word (`feat:` not `feature:`, `fix:` not `bug:`).

| Branch letter | PR / commit prefix |
|---|---|
| `f` (feature) | `feat:` |
| `b` (bug) | `fix:` |
| `d` (docs) | `docs:` |
| `c` (chore) | `chore:` |
| `h` (hotfix) | `hotfix:` |
| `r` (release) | `release:` |

Examples:

```text
feat: Add Styleguide Overlay Support
fix: Resolve Phase Gate Audit Trigger
docs: Document Human Copyable Outputs
chore: Normalize Rule Loading Order
hotfix: Patch Release Boundary Rule
release: Prepare V1 Release
```

Version bumps (major / minor / patch) are controlled by PR labels,
not by commit-message prefixes — see your repo's release tooling for
the specific labels it expects.

## Commit Strategy

Prefer one meaningful commit per branch.

Acceptable exceptions include:

- adding or updating subtrees
- merging upstream changes
- separating mechanical formatting from semantic changes
- preserving reviewable checkpoints during large refactors
- commits required by release tooling

## Merge Strategy

Strongly prefer squash and merge when merging PRs, unless the repository
explicitly documents a different merge strategy.
