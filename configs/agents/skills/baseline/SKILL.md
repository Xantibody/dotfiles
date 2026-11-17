---
name: baseline
description: Converges a repository onto the baseline from whatever state it is in — a flake devShell with direnv, `nix fmt` through treefmt-nix, one `just check` with strict lint and type-check defaults and restricted escape hatches, CI running that same recipe, workflow-security and spelling checks, an architecture map, a decision-record template and Renovate for dependency updates — one commit per missing step, absorbing the tools already there. Its Goal is what the goal-review skill measures.
when_to_use: Whenever the user asks to set up a repository's development environment or bring one up to the house setup — "環境構築して", "baseline に寄せて", "flake 入れて", "just check 作って", "CI 組んで", "lint 厳しくして", "ADR の置き場作って", "renovate 入れて" — new or existing, empty or half done.
---

# Baseline

An agent copies the code next to it and takes the shortest path that
compiles. A repository where agents work well is one where that path is the
right one: the tools are pinned, one command says whether a change is right,
CI runs that same command, and the repository explains its structure and its
decisions. This skill builds that state, from zero or from wherever the
repository already is.

## What the setup stands on

- **A constraint goes at the strongest level that can hold it.** Structure
  (the API, the directory boundaries) over types, types over lint, lint over
  tests, tests over prose. Prose is for what needs judgement.
- **One command, everywhere.** A developer, an agent and CI run the same
  `just check` inside the same devShell. A check CI runs and `just check` does
  not is a check nobody runs before pushing.
- **An error message is an instruction.** A rule this skill adds says what to
  use instead, in the message the agent reads at the line it broke.
- **Escape hatches need a reason.** Inline disables, `any`, casts,
  `@ts-ignore`, `#[allow]`, `//nolint` are forbidden or allowed only with a
  `HACK(<issue URL>)` that names what they wait for.
- **Existing debt is ratcheted, not mass-fixed.** A rule raised on a mature
  repository fails only on new violations, so adopting it does not block work.
  Formatting is the exception: it is mechanical, so it is one commit.

## Goal

**Target.** The repository at the working directory. The format check and
`just check` can rewrite files (`treefmt --ci` formats before it fails), so
they run only on a clean tree (`git status --porcelain` empty); on a dirty
tree their items are `unknown`.

**Items.** Seven steps. Each holds or not on its own; the numbering is the order
that works best when building from nothing, not an order a repository must
have followed. The tests for each, and the shapes that mean "started but not
holding", are in `references/survey.md`.

| #   | Step               | Holds when                                                                                                  |
| --- | ------------------ | ----------------------------------------------------------------------------------------------------------- |
| 1   | devShell + direnv  | a tracked `flake.nix` / `flake.lock` with a devShell, `.envrc` loads it, `.direnv/` ignored                 |
| 2   | `nix fmt`          | treefmt-nix formats every language the repo has, and the tree is formatted                                  |
| 3   | `just check`       | one recipe runs the format check, lint (with zizmor and typos), type check and tests at the strict defaults |
| 4   | CI                 | a workflow runs `nix develop --command just check` on pull requests and default-branch pushes               |
| 5   | Architecture map   | one map with a codemap and the rules step 3 enforces                                                        |
| 6   | Decision records   | a decision-record directory with a template                                                                 |
| 7   | Dependency updates | a Renovate config that updates the language dependencies, the actions and `flake.lock`                      |

A passing `just check` is not yet step 3: compare the lint and type-check
configuration with the stack's reference in `references/` (`typescript.md`,
`go.md`, `rust.md`) and with `references/nix.md` and `references/repo-wide.md`,
which apply to every repository: each one has a flake and a `.github/`. A rule the reference turns on that the repo
turns off or leaves out, or an escape hatch the reference restricts that the
repo allows freely, makes the step partial. A stack with no reference is
judged on whether its strictest documented mode is on.

**Verdict.** One row per step: `done`, `partial`, `missing`, or `unknown`
(a test that could not run, with why), and the evidence — the file, command
and output that decided it. Above the table, the stacks found; below it, the
steps that are not `done`.

**Hand-over.** When the user asked to set the repository up or to converge
it, and a row is not `done`, load this skill with the table. When they or
another skill only asked for the state, stop at the table.

## Procedure

1. Load the `goal-review` skill against this skill's Goal, unless its table
   is already in the conversation, and show the table to the user before
   changing anything. Seven `done` rows: say so and stop.
2. Pick one step that is not `done`. The user's request decides which ("CI
   組んで" is step 4); with no such request, take them in table order, the
   order for building from nothing. The only fixed order is what a step
   needs: 2 and 3 run their tools in the devShell, so they need 1; 4 runs
   `just check` in the devShell, so it needs 1 and 3; 7's update PRs are only
   worth merging when CI checks them, so it needs 4; 5 and 6 need nothing.
   A requested step whose prerequisite is not `done` starts with the
   prerequisite, and the report says why. Do the step as described below and
   in `references/absorb.md` for what the repository already has.
3. Verify the step with its tests in `references/survey.md`, then commit it
   through the `commit` skill: one commit per step, the reason for any
   non-default choice in the body.
4. Review again and go back to 2, until the steps asked for — all of them,
   when the user asked to converge — are `done`. A step's work can change
   another's state — step 1 can make step 2's formatter appear — so never
   work from the first table alone.

Detect the stacks before any step: `package.json` / `tsconfig.json` →
`references/typescript.md`, `go.mod` → `references/go.md`, `Cargo.toml` →
`references/rust.md`. Read only the stack references the repository needs;
`references/nix.md` and `references/repo-wide.md` apply to every repository,
because step 1 gives each one a flake and step 4 a `.github/`. The survey and
the steps use this same rule, so a converged repository stays converged. A repository with several stacks gets one
recipe per stack (`lint-ts`, `lint-go`) under the shared `check`. A stack with
no reference gets its tools' strictest documented mode, and the report says no
reference covered it.

Run nix one command at a time, never several in parallel. Never run
`direnv allow` for the user, never push, and never change branch protection:
requiring the CI check is the `/branch-protection` skill, which the user
types.

### The steps

**1. devShell and direnv.** A repository with no flake gets
`assets/flake.nix` (flake-parts, treefmt-nix) with the stack reference's
packages, and `assets/envrc` as `.envrc`; add `.direnv/` to `.gitignore`. An
existing flake keeps its style. `git add` the flake before evaluating it — a
flake in a git repository sees only tracked files.

**2. `nix fmt`.** Enable the treefmt-nix programs for every language present,
taking the formatter the repository already uses over the stack reference's
choice. The first full format of a mature repository is its own commit, and
its hash goes into `.git-blame-ignore-revs`.

**3. `just check`.** Start from `assets/justfile`: `check` depends on
`fmt-check`, `lint`, `typecheck` and `test`, and nothing in them swallows a
failure. Fill each from the stack reference — its strict lint and type-check
configuration, its escape-hatch rules, and, for a repository that already has
violations, its ratchet. `lint` also runs zizmor on the workflows and typos
over the tree; `references/repo-wide.md` says what each is for and shows one
repository's settings as an example. A placeholder recipe from the asset left in place is
a step not done.

**4. CI.** `assets/check.yml`, with the default branch written into
`on.push.branches`. An existing workflow that already runs the lint and tests
its own way is rewritten to call `just check`, keeping the job name if it is a
required status check. When CI goes red on the first run, the fix belongs in
the devShell or the recipe, never in a CI-only step.

**5. Architecture map.** `assets/architecture.md` as `docs/architecture.md`,
filled from the code: the codemap from the real top-level components and their
dependencies, and one Rules row per boundary step 3 enforces. An existing map
keeps its path and gains only the missing sections.

**6. Decision records.** `assets/adr-template.md` as `docs/adr/template.md`.
Write no records in advance: an ADR exists because a decision was made. The
conventions, and when a later change must write one, are in
`references/docs.md`. The only records this skill writes are for choices it
actually made in this repository between real alternatives — kept ESLint
instead of moving to oxlint, chose a ratchet over a mass fix — each in the
commit of the step that made the choice.

**7. Dependency updates.** `assets/renovate.json5` at the repository root:
Renovate updates the language dependencies, the actions and, with its nix
manager, `flake.lock`, in small grouped PRs that CI checks. Group the stack's
own dependencies the way `references/repo-wide.md` describes. Installing the
Renovate app on the repository is outside it and is the user's to do.

## Report

End with the table from before and after, one line per commit made, and what
is left: a stack no reference covered, ratchet baselines that still hold
violations, a required check the user has to switch on with
`/branch-protection`, and the Renovate app to install. Host-side setup — installing direnv or nix-direnv on the
machine — is the user's and is named, not done.
