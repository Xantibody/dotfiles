---
name: implement
description: Feature implementation with TDD methodology. Guides development through the Red-Green-Refactor cycle with Tidy First principles to keep structural and behavioral changes separate.
when_to_use: Whenever the user asks to implement a feature, fix a bug, add functionality, or build something new — "実装して", "バグを直して", "機能を追加して", "作って", "対応して".
---

# Feature Implementation

Shape the code by the global instructions' Code Structure and Running Behaviour. Use `check` to run the project's checks, and `commit` when ready to commit.

Before starting, run `git branch --show-current`. Whether new work belongs on the default branch or its own branch is a per-repository decision (the repo's CLAUDE.md usually says; a single-maintainer repo often commits straight to the default), so follow that rather than a fixed rule. When it gets its own branch, cut it with `ha new <type>/<slug>` rather than `git switch -c`, and run every command against the `<base>@<branch>` worktree (the `ha` skill has the layout); the base checkout stays on the default branch. What is never fine is beginning on an unrelated non-default branch without asking — the work ends up in someone else's PR.

## Goal

"Every increment green" is the author's memory of the cycles; a change is finished when the project's own checks say so now, the app still starts and does what its smoke rows say, and anything that changes what a screen draws has been looked at. The goal is that state, measured rather than remembered.

**Target.** The change on the current branch: the commits `origin/<default>..HEAD` (the default from `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`), or the commits made in this conversation when the work went straight onto the default branch. The checks can rewrite files (a formatter fixes before it fails), so items 1 and 2 run only on a clean tree (`git status --porcelain` empty); on a dirty tree they are `unknown`, and the uncommitted files are named.

**Items.**

| #   | Item          | Holds when                                                                                                                                                                                                           |
| --- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Checks        | the project's check command exits 0: `just check` when `just --summary` lists `check` (through `nix develop --command` outside the devShell), otherwise the command the `check` skill's step 1 picks                 |
| 2   | Smoke         | `just smoke` exits 0 — `n/a` when `just --summary` does not list `smoke`, with the note that the repository lacks the `baseline` skill's step 8                                                                      |
| 3   | Screen looked | `n/a` when the change draws nothing new; otherwise this conversation captured an image of it with the `browser-verify` or `terminal-verify` skill after the last commit that touched what it draws, and read it back |

Item 3 is a reading rule. The change draws something when the diff of the target (`git diff --name-only <range>`) touches what a browser or a terminal renders: a page, a component, a stylesheet, a template, a chart, a prompt, a colour scheme, a status line, a TUI. A test or a config nobody sees rendered does not count. The image must exist at the path the conversation captured it to; a path from an earlier conversation, or none in this one, leaves the item `unknown` rather than holding.

**Verdict.**

```markdown
**Verdict:** done | not done
**Range:** <the range judged>

| #   | Item | State | Evidence |
| --- | ---- | ----- | -------- |
```

State is `holds`, `fails`, `n/a` or `unknown` (with why). The verdict is **done** only when every row is `holds` or `n/a`; an `unknown` row is never counted as holding. Evidence is the command and the last lines of its output, or the image path.

**Hand-over.** This Goal is asked for by this skill's Finishing, so the review returns the table to it rather than loading anything. Finishing says what each verdict leads to. When the user asked for the state directly, stop at the table.

## Red-Green-Refactor Cycle

### Red Phase (Write Failing Test)

- Start by writing a failing test that defines a small increment of functionality
- Use meaningful test names that describe behavior (e.g., "shouldSumTwoPositiveNumbers")
- Make test failures clear and informative
- Write the simplest failing test first

### Green Phase (Make It Pass)

- Write just enough code to make the test pass - no more
- Use the simplest solution that could possibly work
- Do not add extra features or edge case handling yet
- If the passing code works around something outside the repository, mark it `HACK(<issue URL>)`; if it takes a shape a reader would question, mark it `AIDEV-NOTE`. The global instructions (AGENTS.md / CLAUDE.md) have the exact forms, and a grep for `HACK(` or `AIDEV-NOTE` is how the next session finds them.

### Refactor Phase (Improve Structure)

- Refactor only when tests are passing
- Use established refactoring patterns with their proper names
- Make one refactoring change at a time
- Run tests after each refactoring step
- Prioritize refactorings that remove duplication or improve clarity

## Tidy First Approach

Separate all changes into two distinct types:

| Type       | Description                                | Examples                                  |
| ---------- | ------------------------------------------ | ----------------------------------------- |
| STRUCTURAL | Rearranging code without changing behavior | Renaming, extracting methods, moving code |
| BEHAVIORAL | Adding or modifying actual functionality   | New features, bug fixes                   |

Rules:

- Never mix structural and behavioral changes in the same commit
- Always make structural changes first when both are needed
- Validate structural changes do not alter behavior by running tests before and after

## Code Quality Standards

- Eliminate duplication ruthlessly
- Express intent clearly through naming and structure
- Make dependencies explicit
- Keep methods small and focused on a single responsibility
- Minimize state and side effects

## Defect Fixing Workflow

When fixing a defect:

1. First write an API-level failing test
2. Then write the smallest possible test that replicates the problem, in the kind that matches the defect's shape: when it breaks on a property of the input (an invariant that fails for a class of values), a property test over generated inputs instead of one minimal example, since another input would bring it back; when it breaks on execution order or concurrency, a test that fails under a fixed seed (Go: `-shuffle=<seed>` with `-race`; other stacks' flags are in the `baseline` skill's references), since an example alone may pass by luck
3. Get both tests to pass

## Feature Implementation Workflow

Build features incrementally — one test at a time, never in batch. Follow the 0-1-N progression:

1. **0-case (empty/base)**: Write a failing test for the simplest case (empty input, zero state). Implement the minimum to pass.
2. **1-case (single/minimal)**: Write a failing test for a single valid input. Extend the implementation.
3. **N-case (multiple/general)**: Write a failing test for the general case. Implement the real algorithm.
4. **Boundary tests**: After the core logic works (Green), add edge case tests to strengthen confidence. These should pass without code changes. When the input space is too wide to list by example (a parser, an encoder, a pure transformation), write one property test instead — an invariant such as a round trip, idempotence or a preserved count, checked over generated inputs with the stack's tool from the `baseline` skill's references. For an optimization, keep the old implementation beside the new one as the reference (in the test file, or unexported) and write a property test that the two return the same output on generated inputs before deleting or replacing it.
5. **Refactor**: Consolidate test structure (e.g., table-driven tests) and improve code quality. Commit structural changes separately (use `commit` skill).
6. Repeat for the next increment of the feature.

Each cycle is: write ONE failing test → make it pass → run the checks (`check` skill) → commit (`commit` skill). If the same check still fails after three fixes, the cycle ends there: stop and hand it to the user as the `check` skill says, rather than trying a fourth. When the increment changes something a browser or a terminal renders — a page, a component, a style, a prompt, a TUI — tests prove the behaviour but not the picture: before committing, load the `browser-verify` or `terminal-verify` skill and look at the screen. Never write multiple tests before implementing. This incremental approach catches design issues early and keeps each step small and reversible. Committing does not include pushing — `git push` is the user's; report and stop.

## Finishing

When the last increment is committed, load the `reliability-checklist` skill and work through every row it prints for this change: those are the places this repository broke before, and a check that finds the problem again is a new Red like any other. Then load the `goal-review` skill against this skill's Goal. On **not done**, go back to the first row that is not `holds` or `n/a`: a failing check or smoke is a new Red, fixed in a cycle as above and under the same three-fixes rule; a screen not looked at goes to the `browser-verify` or `terminal-verify` skill; an `unknown` gets what it lacked (a commit for a dirty tree, a capture in this conversation). Then ask again. Only **done** ends the work; the report carries its table, so the user reads what was run rather than "checks passing".

The per-cycle commits are checkpoints for you, not the history a reviewer reads — they see one feature, not the cycles and detours that produced it. Once this skill's Goal is **done**, load the `goal-review` skill once against the `reconstruct` skill's Goal and follow its verdict: on **rebuild**, it hands over to the `reconstruct` skill before anything is pushed; on **pass**, report and stop. This Goal comes first because a rebuild reproduces the final diff, so it keeps whatever the checks found wrong. Once is the point — not after each cycle, when the answer is always "not yet", and not after the branch is pushed for review, when the history already belongs to the reviewer.
