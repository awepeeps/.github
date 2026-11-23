# awepeeps repository standard

`awepeeps` is the owner's friend-group organization on the GitHub Free plan. It
holds the group's tools, plugins, server setup and deployment data for Minecraft,
Archipelago, World of Warcraft and Discord. Friends contribute by pull request;
the owner merges and deploys. [`core.md`](core.md) applies in full unless a
**(profile)** rule is adjusted below.

## Scope

All 13 repositories owned by `awepeeps`, as listed by
`gh repo list awepeeps --limit 200` on 2026-11-23:

| Repository                 | Visibility       | Kind                           | Notes                                                               |
| -------------------------- | ---------------- | ------------------------------ | ------------------------------------------------------------------- |
| `.github`                  | public           | org defaults and this standard | Community files, profile README, `standards/`.                      |
| `minecraft-setup`          | public           | Minecraft templates            | Public half of the two-repository split; placeholders only.         |
| `minecraft-deployment`     | private          | live server instance           | Private half; the only home of live pins and instance values.       |
| `archipelago`              | public           | session archive and tooling    | Discussions on; `just` is the session entry point.                  |
| `awepeeps-bridgeipelago`   | public fork      | Discord bridge for Archipelago | Upstream on `main`; work on `awepeeps-patches`, the default branch. |
| `bluemap-compass`          | public fork      | Paper plugin                   | Unlicensed, matching the unlicensed upstream.                       |
| `chestcleaner`             | public fork      | Paper plugin                   | Keeps upstream GPL-3.0.                                             |
| `nicknames`                | private          | Paper plugin                   | Never published to a public jar host.                               |
| `spawn-kit`                | public           | Paper plugin                   |                                                                     |
| `test-discord`             | private          | Discord staging tooling        | Production guild is read-only.                                      |
| `wow-forever-guild-report` | public           | TypeScript CLI and report      | Refreshes a configured Google Sheet after merges.                   |
| `navigator`                | public, archived | retired Paper plugin           | Replaced by `bluemap-compass`.                                      |
| `whitelist-gate`           | public, archived | retired Paper plugin           | Replaced by the native Paper/Floodgate whitelist.                   |

## Plan and protection

The organization is on **GitHub Free**. Branch rulesets work on public
repositories only. The three private repositories (`minecraft-deployment`,
`nicknames`, `test-discord`) cannot be protected on Free, so there C2.1 is
enforced by a local hook plus a detective workflow.

### Public repositories

One ruleset named `protect-main`, targeting the default branch
(`awepeeps-patches` in `awepeeps-bridgeipelago`):

| Rule                                  | Value                                                                                                                   |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Require a pull request before merging | on, **0** required approvals                                                                                            |
| Required status checks                | `check` and `secrets` where the repository runs those jobs (see [Required checks](#required-checks)); none in `.github` |
| Require branches to be up to date     | off; `update branch` is available when a rebase is needed                                                               |
| Require signed commits                | on (C2.7)                                                                                                               |
| Block force pushes                    | on                                                                                                                      |
| Restrict deletions                    | on                                                                                                                      |
| Bypass list                           | empty; the owner is not a bypass actor                                                                                  |

Repository settings that complete the ruleset: squash merge only (merge and
rebase disabled), squash title and message from the pull request, delete head
branch on merge, update branch enabled, auto-merge enabled, "require actions to
be pinned to a full-length commit SHA" enabled, workflow token read-only and
unable to approve pull requests.

`awepeeps-bridgeipelago` adds a second ruleset, `preserve-upstream-main`, which
blocks deletion of `main` and nothing else. Force pushes to `main` stay allowed
so the branch can be re-synced to upstream. All work goes to
`awepeeps-patches`, which carries the full `protect-main` ruleset.

Dependency updates: native auto-merge merges Dependabot minor and patch pull
requests once every check on the exact head commit has passed (C3.3). Major
updates are never auto-merged.

Security, on every public repository: secret scanning and push protection on;
CodeQL default setup on; no `codeql.yml` file unless default setup cannot
express the needed query set, recorded in `docs/exceptions.md`.

### Private repositories

`minecraft-deployment`, `nicknames` and `test-discord` use three controls:

1. `hooks/core.yml` and `hooks/owner.yml`, loaded through Lefthook at the
   `hooks-v3` tag and installed by `just hooks`, refuse any push to
   `refs/heads/main` and run `gitleaks` over the outgoing commits. The hook
   configuration is committed, so it survives a clone; `just hooks` runs
   `lefthook install` and asserts the remote jobs are present (C7.8).
2. `.github/workflows/direct-push-guard.yml` runs on `push` to `main` and fails
   when the pushed commit has no merged pull request associated with it (a
   commits API lookup). A red run means the commit must be reverted and redone
   through a pull request.
3. `.github/workflows/automerge.yml` provides label-driven auto-merge: a pull
   request carrying `automerge` and not `major-update` is squash-merged after
   every check passes on its head commit. The job alone gets
   `contents: write` and `pull-requests: write`.

The guard is detective, not preventive; the hook is the preventive control. A
direct push to a private repository cannot leak public data, but it still skips
the checks, so the guard run is part of the review of `main`.

Free private repositories have no GitHub secret scanning or CodeQL, so
`gitleaks` runs in the `pre-push` hook and on the pull request diff in CI (C6.2).

## Profile choices

- **C1.5** — Issues are on. Wiki and Projects are off. Discussions are on only
  in `archipelago`, where sessions are coordinated; everywhere else they are
  off. A fork that sends bugs upstream states that in its README and records
  the issue setting in `docs/exceptions.md`.
- **C2.7** — Commits are signed. The owner's local Git config signs with SSH
  (`gpg.format = ssh`), so owner commits are signed. Friends contributing by
  pull request do not have to sign: the squash commit is created and signed by
  GitHub, and a private-repository pull request merged by the automerge
  workflow is squash-merged the same way.

## Required checks

Required check names are identical in every repository, so the ruleset contents
are copyable. Where a repository runs the jobs, both checks run on the pull
request head and in parallel.

| Check     | Job       | Recipe         | Scope                                                                 |
| --------- | --------- | -------------- | --------------------------------------------------------------------- |
| `check`   | `check`   | `just check`   | Every fast gate: format, lint, type check, test, build.               |
| `secrets` | `secrets` | `just secrets` | Gitleaks on the pull request diff; full history on `main` and weekly. |

What `just check` runs, by repository kind:

| Kind              | Repositories                                                | Recipes behind `check`                                                                                                                                                                         |
| ----------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Java plugin       | `bluemap-compass`, `chestcleaner`, `nicknames`, `spawn-kit` | `fmt-check`, `test`, `build` — JDK 25 Temurin, Gradle wrapper (`chestcleaner` keeps upstream Maven), one build per pull request                                                                |
| Python and shell  | `minecraft-setup`, `archipelago`, `awepeeps-bridgeipelago`  | `fmt-check`, `lint`, `test` — shellcheck and YAML validation in `minecraft-setup`; the repository validator and `compileall` in `archipelago`; `unittest discover` in `awepeeps-bridgeipelago` |
| TypeScript        | `wow-forever-guild-report`                                  | `fmt-check`, `lint`, `typecheck`, `test`                                                                                                                                                       |
| No required check | `.github`, `minecraft-deployment`, `test-discord`           | No ruleset applies. `minecraft-deployment` and `test-discord` get `check` and `secrets` with their first workflow; `.github` has only the recipes in its `justfile`.                           |

The reproducibility job is not required. It builds twice, compares the two
artifacts with `cmp`, and prints the SHA-256 to the job summary. It runs on
`main` and on release pull requests only, so a normal pull request stays inside
the 60-second target (C5.1, C5.4). A plugin whose required checks still exceed
60 seconds records the measured median in `docs/exceptions.md` (C5.5); today
that is `nicknames`, at 85 seconds.

## Git hooks

Hooks run through Lefthook, pinned in `mise.toml` as `"aqua:evilmartians/lefthook"` (C7.8). Each
repository's `lefthook.yml` loads `hooks/core.yml` and `hooks/owner.yml` from this repository
through `remotes` at the annotated tag `hooks-v3`, and adds its own jobs under names that never
start with `core-` or `owner-`. Repositories migrate from the old `.githooks` launchers to Lefthook
per core C7.8.

This owner's `hooks/owner.yml` job runs before every commit:

| Job                 | Recipe                    | Behaviour                                                                                                                                                                                                        |
| ------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `owner-public-data` | `just public-data-staged` | In a public repository, fails when a staged file contains a host path, an IP address, world coordinates, a seed, or a server or instance ID. Exits 0 in a private repository, where instance values are allowed. |

`just hooks` removes a local `core.hooksPath` only when it equals `.githooks`, refuses any other
value or a global one, runs `lefthook install`, and then asserts that `lefthook dump` contains the
`core-*` and `owner-*` jobs, because a failed remote fetch only warns. `lefthook-local.yml` is
git-ignored, and agents never skip hooks: no `LEFTHOOK=0`, no `--no-verify` (C7.11).

## Owner rules

1. **Public repositories carry no instance values.** No host paths, usernames,
   IP addresses, seeds, world coordinates, server or instance IDs, logs, config
   dumps, backups or secrets. Use placeholders such as `<SERVER_HOST>`,
   `<instance-data>`, `/srv/minecraft` and `CHANGE_ME`. A file ported from the
   private deployment is edited line by line; private history is never merged
   into a public repository.
2. **Pins live only in `minecraft-deployment`.** A release is the exact merge
   commit of a public plugin plus the SHA-256 of its jar, recorded in
   `config/*-source.env` and `config/plugins.list` of the private repository.
   Never pin a moving branch or a tag. The plugin repositories publish no GitHub
   Release; the CI artifact is the release.
3. **Java plugins build with JDK 25 Temurin.** Gradle wrapper, except inherited
   forks that keep Maven. `just` recipes wrap the build tool; no workflow calls
   `./gradlew` or `mvn` directly.
4. **Forks keep their upstream shape.** `awepeeps-bridgeipelago` keeps upstream
   on `main` and the group's work on `awepeeps-patches`, the default branch,
   which is never deleted after a merge. `chestcleaner` keeps GPL-3.0.
   `bluemap-compass` has no `LICENSE` file because upstream publishes none; its
   README and `AGENTS.md` say so.
5. **Retirement is a three-part record.** Description starts
   `Retired (archived):` and names the replacement, the README starts with a
   `> **Retired.**` note, and `AGENTS.md` says "do not reactivate". Scheduled
   workflows are disabled before archiving.
6. **Skills live in `.agents/skills/<name>/SKILL.md`.** `.github/skills/` is not
   a skill path here. `.claude/skills/<name>` is a relative symlink to the same
   skill (C8.3), installed and checked by `just agent-files`.
7. **Labels.** GitHub's default labels, plus `dependencies` (C3.5), `major-update`
   (C3.4), and `automerge` (private repositories only). Dependabot applies the
   first two; the private-repository automerge workflow reads the third.
8. **`just` is the only entry point.** Humans, agents and CI run recipes.
   Repository scripts are implementation details; a failure is fixed, never
   weakened to get green.
9. **Agent docs use one shape.** `AGENTS.md` opens with the repository title, a
   scope line that names every file, then purpose and layout, invariants,
   build/test commands, and a privacy or read-only section where it applies. A
   repo-local skill adds only the workflow that `AGENTS.md` does not cover.

## Superseded

This standard replaces the following documents. They stay in place; each one
gets a link to this standard in a follow-up, and the duplicated rules are
removed.

| Older document                                                                                                                 | Now covered by                              | What changed                                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `minecraft-setup/README.md` "The two-repository rule" and the `portable-template-change` skill                                 | Rules 1 and 2                               | The split and the privacy list move into the standard. The skill keeps the porting procedure only.                                  |
| `minecraft-deployment/README.md` "Public vs. private, and the configuration model"                                             | Rules 1 and 2                               | Same rules, one source.                                                                                                             |
| `RELEASING.md` in `bluemap-compass`, `chestcleaner`, `nicknames`, `spawn-kit`                                                  | Rule 2                                      | The pin rule is standard; each file shrinks to repository-specific version steps.                                                   |
| Per-repository `AGENTS.md` shapes (`# Repository guidance: Awepeeps <Name>`, `# Repository Guidelines`, older prose)           | C8.1 and rule 9                             | One shape; the local invariants and privacy lists stay.                                                                             |
| `archipelago/justfile` and its AGENTS.md "canonical access point" rule                                                         | C7.1 and rule 8                             | Applies to every repository, not only `archipelago`.                                                                                |
| `.github/README.md` "Workflows, branch protection, repository settings, and agent instructions require explicit configuration" | [Plan and protection](#plan-and-protection) | The mechanics are unchanged; the target state and how each repository reaches it are now written down.                              |
| Merge-commit merges used across the organization                                                                               | C2.3                                        | Squash only, including forks; branch protection is enforced by the `protect-main` ruleset or the private-repository hook and guard. |
| `archipelago/.github/skills/archipelago-session-workflow/`                                                                     | C8.2 and rule 6                             | Move to `.agents/skills/` and add the `.claude/skills` symlink.                                                                     |

Follow-ups, none done in this pull request: link this standard from the four
`RELEASING.md` files, both halves of the Minecraft split and the plugin
`AGENTS.md` files; move the `archipelago` skill; add `justfile`, `mise.toml` and
`docs/exceptions.md` to the repositories that lack them; add the `dependencies`
and `major-update` labels everywhere and `automerge` in the private
repositories.

## Conformance backlog

Measured on 2026-11-23 from the local clones and
`/tmp/repo-audit/api/awepeeps__*.json`. "PR median" is the median wall clock of
the pull request runs in that file (n is small; a new measurement follows the
first CI change in each repository).

| Repository                  | PR median | Gaps vs core and this standard                                                                                                                                                                                                                                                                     | Proposed fix                                                                                                                                                                                 |
| --------------------------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.github`                   | n/a       | This pull request adds the standard, `justfile`, `mise.toml`, `.editorconfig`, `.gitattributes`, `AGENTS.md` and the README link. Still missing: `protect-main`, secret scanning, CodeQL, `.github/dependabot.yml`, the `dependencies`/`major-update` labels, `LICENSE`; wiki and Projects are on. | Apply the public-repository settings; add Dependabot and the labels; decide `LICENSE` (C1.6) or record an exception.                                                                         |
| `minecraft-setup`           | 43 s      | No `protect-main`; wiki and Projects on; no `dependabot.yml`; no CodeQL or secret scanning (gitleaks only); no `justfile`, `mise.toml`; `sha_pinning_required` off.                                                                                                                                | Add the ruleset and settings, Dependabot, CodeQL and secret scanning; wrap `automation/run-tests.sh` in `just check`/`just secrets`; add the pins.                                           |
| `minecraft-deployment`      | no CI     | No workflow at all, so no `check`, no `secrets`, no hook, guard or automerge; no `favicon.svg`; `just`, `mise.toml`, `.editorconfig` missing; Projects on.                                                                                                                                         | Add the hook, guard, automerge workflow, a diff-only gitleaks job and the tooling files; keep the mock suites behind `just test`.                                                            |
| `archipelago`               | 35 s      | Skill under `.github/skills/`; tag-pinned actions; no `protect-main`; wiki and Projects on; no `dependabot.yml`; no CodeQL or secret scanning; no `mise.toml`; local `just` floor 1.33 vs CI 1.59.0; Python scripts need a C7.4 exception.                                                         | Move the skill and add the symlink; SHA-pin actions; add the ruleset, Dependabot, CodeQL and secret scanning; add `mise.toml` and align the local `just` floor; record the Python exception. |
| `awepeeps-bridgeipelago`    | 22 s      | Issues off; tag-pinned actions; `preserve-upstream-main` missing (only deletion of `awepeeps-patches` is blocked); no `dependabot.yml`; no `justfile`, `mise.toml`, `.editorconfig`, `favicon.svg`; older AGENTS.md; issue templates ask for a `.env` paste.                                       | Enable issues (or record the exception), add the second ruleset and settings, replace the templates with the org defaults, add the tooling files and the agent-doc shape.                    |
| `bluemap-compass`           | 45 s      | No `favicon.svg`; no `protect-main`; no `dependabot.yml`; no CodeQL or secret scanning; no `justfile`, `mise.toml`; reproducibility job runs on every PR; no `LICENSE` (intentional, not recorded as an exception).                                                                                | Add icon, ruleset, settings, Dependabot, CodeQL, secret scanning and the tooling files; move the second build to `main` and release PRs; record the license stance in `docs/exceptions.md`.  |
| `chestcleaner`              | 35 s      | Issues off; wiki and Projects on; no `protect-main`; no `dependabot.yml`; no CodeQL or secret scanning; no `justfile`, `mise.toml`; reproducibility job on every PR; `delete_branch_on_merge` off.                                                                                                 | Enable issues (or record it), add the ruleset and settings, Dependabot, CodeQL, secret scanning and tooling files; move the second build to `main` and release PRs.                          |
| `nicknames`                 | 85 s      | Exceeds C5.1: the Linux build and a reproducibility compare run on every PR, and the workflow still carries a Windows build (C5.6). No `protect-main` (private), no hook, guard or automerge; no `dependabot.yml`; no `justfile`, `mise.toml`.                                                 | Drop the Windows build and the cross-OS compare (C5.6); keep one Linux build on PRs and, if reproducibility stays, compare two Linux builds on `main` and release PRs; add the private controls and tooling files; record the resulting median once measured.         |
| `spawn-kit`                 | 54 s      | No `protect-main`; wiki and Projects on; no `dependabot.yml`; no CodeQL or secret scanning; reproducibility job on every PR; no `justfile`, `mise.toml`; `delete_branch_on_merge` off.                                                                                                             | Add the ruleset and settings, Dependabot, CodeQL, secret scanning and tooling files; move the second build to `main` and release PRs.                                                        |
| `test-discord`              | no CI     | No `check` or `secrets`, no hook, guard or automerge; standalone `CLAUDE.md` (C8.1); no `justfile`, `mise.toml`, `.editorconfig`; Projects on.                                                                                                                                                     | Add the private controls and a gitleaks diff job; fold `CLAUDE.md` into `AGENTS.md`; wrap the tools in `just` recipes.                                                                       |
| `wow-forever-guild-report`  | 32 s      | Description is empty (C1.2); no `.gitattributes`; no `protect-main`; wiki and Projects on; labels lack `major-update`; Bun 1.4.3 and `just` 1.45.0 differ from the organization pins; no CodeQL or secret scanning; three red CI runs on 2026-11-23.                                               | Set the description; add `.gitattributes`, ruleset, settings, the `major-update` label and CodeQL/secret scanning; pin Bun 1.4.5 and `just` 1.59.0; triage the failing runs.                 |
| `navigator` (archived)      | n/a       | No `favicon.svg`; issues and Projects still on; no local `SECURITY.md`.                                                                                                                                                                                                                            | The retirement record is complete, so these are low priority; if the repository stays archived, record the icon gap in `docs/exceptions.md` rather than unarchiving.                         |
| `whitelist-gate` (archived) | n/a       | No `favicon.svg`; tag-pinned actions in a workflow that can no longer run; issues and Projects still on.                                                                                                                                                                                           | Leave archived; record the icon and pinning gaps as accepted for a retired repository.                                                                                                       |
