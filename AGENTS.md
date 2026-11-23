# Repository guidance: Awepeeps .github

Scope: **every file in this repository**.

## What this repository is

The organization's default community files (`CONTRIBUTING.md`, `SUPPORT.md`,
the pull request template, the issue forms) and the profile README, plus the
repository standard shared by the five owner accounts.

## Standards

- `standards/core.md` is copied byte-for-byte from the shared source. Do not
  edit it. Change it only through one pull request per owner that applies the
  same bytes to all five `.github` repositories, then run `just core-drift`.
- `standards/owner.md` is this owner's profile: scope, protection, required
  checks and owner rules.
- `scripts/core-drift.ts` is copied unchanged as well.

## Commands

- `just` lists the recipes.
- `just fmt`, `just fmt-check` format the files this repository owns.
  `standards/core.md`, `scripts/core-drift.ts` and `profile/README.md` are
  excluded in `.prettierignore`.
- `just check` runs what CI requires.
- `just core-drift` compares the core copy with the other four owners.

## Rules

- Keep the profile and the community files generic and short.
- Do not add a workflow here to make another repository conform. Workflows and
  settings live in each repository.
- No secrets, host paths, player names or instance values anywhere, including
  examples.
