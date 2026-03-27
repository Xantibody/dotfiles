---
name: refactor
description: Analyze and create a refactoring plan for codebases grown through vibe coding. Use this skill when the user wants to clean up, reorganize, or redesign code that has been built incrementally and become messy. Also use when the user mentions technical debt, legacy code cleanup, code reorganization, or wants to restructure a project without breaking existing behavior. This skill produces a plan — it does not execute changes itself.
---

# Refactor

Analyze a codebase that has grown organically (often through vibe coding) and produce a step-by-step refactoring plan. The plan preserves existing behavior while improving structure — no changes are made without test coverage first.

This skill outputs numbered plan files to `./plans/` for execution via `/execute-plan`.

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

| Pattern | Symptom | Typical Cause |
|---|---|---|
| God object/file | One file does everything | Features added to the nearest file |
| Scattered logic | Same concept spread across many files | No clear ownership of responsibilities |
| Tight coupling | Changing A breaks B, C, D | Direct dependencies without interfaces |
| Mixed concerns | UI logic in data layer, business logic in controllers | No layer discipline |
| Copy-paste variants | Similar code repeated with small differences | Quick fixes without abstraction |

### 2. Measure and Prioritize

Not everything needs refactoring. Focus effort where it matters most:

- **Churn × Complexity**: Files that change frequently AND are complex are the highest-priority targets. Files that are complex but rarely change can wait.
- **Pain points**: Ask the user which parts of the code cause the most friction in daily development.
- **Blast radius**: Identify which changes are isolated vs. which affect many parts of the system.

Present findings to the user as a prioritized list with reasoning.

### 3. Choose Design Strategy (with the user)

Different parts of the codebase may need different approaches. Present options and tradeoffs — don't prescribe a single methodology.

**Structural patterns to consider:**

- **Three-layer (Presentation / Domain / Data)**: When responsibilities are mixed across layers. Apply Dependency Inversion to keep the domain independent.
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

Identify **seams** — places in the code where you can intercept behavior to insert tests without modifying the code under test.

### 5. Generate the Plan

Write plan files to `./plans/` with numbered prefixes:

```
plans/
├── 01-add-characterization-tests.md
├── 02-extract-domain-logic.md
├── 03-introduce-repository-pattern.md
└── 04-restructure-directory-layout.md
```

Each plan file should contain:

```markdown
# Step title

## Goal
What this step achieves and why it comes at this point in the sequence.

## Prerequisites
Which previous steps must be complete. What tests must be passing.

## Tasks
Concrete implementation tasks with enough detail to execute.

## Verification
How to confirm this step succeeded without breaking anything.
- Which tests to run
- What behavior to manually verify
```

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

- **Execute changes**: This skill produces plans. Use `/execute-plan` to run them.
- **Make autonomous design decisions**: Design choices are always presented to the user with tradeoffs.
- **Force a single methodology**: DDD, Transaction Script, FCIS — the right answer depends on the context.
