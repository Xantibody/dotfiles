---
name: refactor
description: Analyze and create a refactoring plan for codebases grown through vibe coding. Produces a plan — it does not execute changes itself.
when_to_use: When the user wants to clean up, reorganize, or redesign code that has been built incrementally and become messy, or mentions technical debt, legacy code cleanup, code reorganization, or restructuring a project without breaking existing behavior.
disable-model-invocation: true
---

# Refactor

Analyze a codebase that has grown organically (often through vibe coding) and produce a step-by-step refactoring plan. The plan preserves existing behavior while improving structure — no changes are made without test coverage first.

This skill outputs numbered plan files to `.ai/plans/` — `.ai/` is the globally gitignored home for agent output in every repository, so nothing needs adding to `.gitignore` — for execution in a later session (typically driven by `/goal` after `/clear`).

## Why This Skill Exists

Vibe coding is great for getting things working fast. But the result is often a codebase where responsibilities are tangled, abstractions are missing or inconsistent, and changes in one place break things elsewhere. The goal here is not to rewrite from scratch — it's to incrementally reshape the code into something maintainable, guided by tests that guarantee nothing breaks along the way.

## Core Principle: Behavior Preservation

Every refactoring step must be protected by tests before any structural change. This is non-negotiable — the whole point is to keep working software working. If the codebase lacks tests, the first plan steps must add them.

## Workflow

### 1. Understand the Current State

Read the codebase thoroughly before forming opinions:

- Directory structure and file organization
- Entry points and key flows
- Test coverage (what exists, what's missing)
- Dependencies and their relationships

Identify the **type of mess** — not all technical debt is the same:

| Pattern             | Symptom                                               | Typical Cause                          |
| ------------------- | ----------------------------------------------------- | -------------------------------------- |
| God object/file     | One file does everything                              | Features added to the nearest file     |
| Scattered logic     | Same concept spread across many files                 | No clear ownership of responsibilities |
| Tight coupling      | Changing A breaks B, C, D                             | Direct dependencies without interfaces |
| Mixed concerns      | UI logic in data layer, business logic in controllers | No layer discipline                    |
| Copy-paste variants | Similar code repeated with small differences          | Quick fixes without abstraction        |

### 2. Measure and Prioritize

Not everything needs refactoring. Focus effort where it matters most:

- **Churn × Complexity**: Files that change frequently AND are complex are the highest-priority targets. Files that are complex but rarely change can wait.
- **Pain points**: Ask the user which parts of the code cause the most friction in daily development.
- **Blast radius**: Identify which changes are isolated vs. which affect many parts of the system.

Present findings to the user as a prioritized list with reasoning.

### 3. Choose Design Strategy (with the user)

Start from the global instructions' Code Structure and Running Behaviour. Their principles — three kinds of place (four once a domain exists), imports pointing one way, one entry per use case, no default for anything an environment decides — are the target and are not reopened. How this repository spells them (what each place is called, how far to split, the example's names or others) is a choice like the ones below: propose a layout in the language's idiom with its tradeoffs and decide it with the user.

Decide the layout from the outside in, one level per exchange with the user: first the top level by what runs (each program, and the library they share), then the places inside each, then the things inside each place. A level the user has settled is not reopened by the next one.

Then map every file in the areas chosen in step 2 before writing a plan: a table of current path → place → name, with where each name's word comes from (the docs, the UI strings, the command and tool names). Hand the table to separate agents (subagents where the harness has them) who see only the table, the code and the principles — one doubting the names (siblings at one level of abstraction, product words rather than implementation words, the same word for the same thing across the repository), one doubting the places (does processing know the application, does service code do more than talk, would any import point the wrong way) — and fold their findings in. Then present the reviewed table, flagging each name the readers disputed or where more than one product word fits, with the alternatives. Correcting names one at a time in conversation is the slow path.

Judge a layout by what the code holds — which product noun each component belongs to, how many outside services there are, what each file imports — not by how files changed together in the history: co-change counts measure the current layout and so argue for it.

Different parts of the codebase may need different approaches. Present options and tradeoffs — don't prescribe a single methodology.

**Structural patterns to consider:**

- **Three-layer (Presentation / Domain / Data)**: When responsibilities are mixed across layers. Keep the domain's rules free of I/O; its operations take services as parameters.
- **DDD (Entities, Value Objects, Bounded Contexts)**: When complex business logic is scattered and needs a clear model. Worth the cost only for genuinely complex domains.
- **Transaction Script**: When a flow is simple and sequential. Resist the urge to over-engineer — a plain function is fine.
- **Functional Core, Imperative Shell**: When testability is the main goal. Push logic into pure functions, keep I/O at the edges.

**Safe migration patterns:**

- **Strangler Fig**: Build new design alongside the old, migrate callers gradually, then remove the old code. Best for large-scale restructuring.
- **Seam extraction** (from Working Effectively with Legacy Code): Find natural boundaries in the code where you can insert tests and then restructure.
- **Mikado Method**: When changes have deep dependency chains. Map the dependency graph, work from leaves to root.

**Evaluation criteria:**

- **SOLID / CUPID**: Use as a lens to evaluate proposed designs, not as rigid rules to follow.
- **Connascence**: Identify the type and strength of coupling between components to guide decoupling decisions.

For each area of the codebase, recommend an approach and explain the tradeoff:

- What improves (testability, readability, changeability)
- What it costs (complexity, learning curve, migration effort)

Wait for the user's input before proceeding.

### 4. Design the Test Strategy

Before writing any plan step that changes structure, define what tests protect the current behavior:

- **Characterization tests**: Capture what the code actually does today (not what it should do). These are the safety net.
- **Unit tests**: For isolated logic that can be tested in pure functions.
- **Integration tests**: For boundaries between components, especially I/O and external services.
- **Differential tests**: For every stage where the old and the new implementation run side by side (Strangler Fig, a seam with both paths behind it). Feed the same inputs to both — generated ones from the stack's property-test tool (the `baseline` skill's references name it) or recorded real inputs — and compare the outputs. A normalization function strips differences that do not matter (timestamps, generated IDs, ordering of unordered collections) before the comparison, and the differences that are intended live in an approved-differences file checked in beside the test, one entry per difference with why it is accepted. Characterization tests pin the examples someone thought of; this catches the inputs nobody listed, and it is what says the old path can be deleted.

Identify **seams** — places in the code where you can intercept behavior to insert tests without modifying the code under test.

### 5. Generate the Plan

Write plan files to `.ai/plans/` with numbered prefixes:

```
.ai/plans/
├── 01-add-characterization-tests.md
├── 02-extract-domain-logic.md
├── 03-pass-services-to-operations.md
└── 04-restructure-directory-layout.md
```

Each plan file should contain:

```markdown
# Step title

## Goal

What this step achieves, why it comes at this point in the sequence, and what it makes easier to test.

## Prerequisites

Which previous steps must be complete. What tests must be passing.

## Tasks

Concrete implementation tasks with enough detail to execute, each one commit, marked structural, behavioral or test-only; a step holds no behavioral task beside a structural one.

## Verification

How to confirm this step succeeded without breaking anything.

- Which tests to run
- What behavior to manually verify
- Which tests can now be written that could not before, or got simpler
- For a step that deletes an old implementation: the differential test reports zero differences beyond the approved-differences file
```

A decision the user let stand on your recommendation without confirming it is listed at the top of the plan that depends on it, so the executor asks before acting on it.

**Plan design principles:**

- **Tests come first**: The earliest plan files should establish test coverage. No structural changes without a safety net.
- **Small steps**: Each file should be a single logical change that can be verified independently. If a step feels too large, split it.
- **Tidy First**: Separate structural changes (moving code, renaming, extracting) from behavioral changes (fixing bugs, adding features). Never mix them in the same step.
- **Reversible**: Each step should be easy to revert if something goes wrong. Avoid steps that burn bridges.

### 6. Review with the User

Present the full plan for review:

- List all plan files with a one-line summary of each
- Highlight any steps where you made judgment calls and explain why
- Flag risks or areas of uncertainty
- Ask if the ordering, granularity, and approach look right

Revise based on feedback until the user is satisfied.

## What This Skill Does NOT Do

- **Execute changes**: This skill produces plans. Execute them in a later session with `/goal`, committing each step with the `commit` skill after `check` passes, then moving that step's plan file to `.ai/plans/done/` so `.ai/plans/` stays the open backlog.
- **Make autonomous design decisions**: Beyond the principles in the global instructions, design choices — the layout and its names included — are always presented to the user with tradeoffs.
- **Force a single methodology**: DDD, Transaction Script, FCIS — the right answer depends on the context.
