---
name: implement
description: Feature implementation with TDD methodology. Use this skill when the user asks to implement a feature, fix a bug, add functionality, or build something new. Guides development through the Red-Green-Refactor cycle with Tidy First principles to keep structural and behavioral changes separate.
---

# Feature Implementation

Use this skill when implementing features or fixing bugs.

Use `design` skill for architecture and design principles.
Use `commit` skill when ready to commit.

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
2. Then write the smallest possible test that replicates the problem
3. Get both tests to pass

## Feature Implementation Workflow

Build features incrementally — one test at a time, never in batch. Follow the 0-1-N progression:

1. **0-case (empty/base)**: Write a failing test for the simplest case (empty input, zero state). Implement the minimum to pass.
2. **1-case (single/minimal)**: Write a failing test for a single valid input. Extend the implementation.
3. **N-case (multiple/general)**: Write a failing test for the general case. Implement the real algorithm.
4. **Boundary tests**: After the core logic works (Green), add edge case tests to strengthen confidence. These should pass without code changes.
5. **Refactor**: Consolidate test structure (e.g., table-driven tests) and improve code quality. Commit structural changes separately (use `commit` skill).
6. Repeat for the next increment of the feature.

Each cycle is: write ONE failing test → make it pass → run ALL tests → commit. Never write multiple tests before implementing. This incremental approach catches design issues early and keeps each step small and reversible.
