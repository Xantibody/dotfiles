---
name: test-design
description: Design test cases following Kent Beck and t-wada principles. Use this skill when the user asks what to test, wants to design test cases, needs a test strategy, or wants to identify edge cases and boundary conditions for a feature. Focuses on behavior-driven testing with the 0-1-N rule.
---

# Test Design

Design tests that improve design resilience, not just find bugs.

Inspired by Kent Beck (TDD creator) and t-wada (Takuto Wada).

## Workflow

### 1. Investigate Existing Conventions

Before designing test cases, understand the context:

- Read the target code or specification to understand expected behavior
- Check the codebase for existing naming conventions, patterns, and common values (e.g., directory structures that map to identifiers, commit history patterns)
- Use actual values from the codebase in test cases rather than generic placeholders — this catches real-world edge cases and ensures tests match actual usage

### 2. Design Test Cases

Apply the core principles below to generate test cases in the output format.

## Core Principles

| Principle              | Description                                                        |
| ---------------------- | ------------------------------------------------------------------ |
| Fear into Tests        | Prioritize boundaries and edge cases where "this might break"      |
| Test Behavior          | Focus on external behavior, not internal implementation details    |
| Refactoring Resistance | Extract essential specs that survive code restructuring            |
| 0-1-N Rule             | Always include empty(0), single(1), multiple(N), and boundary vals |

## Output Format

When analyzing code or specifications, provide:

### 1. Core Behavior Tests

- Happy path scenarios that deliver direct user value

### 2. Boundary and Error Tests (0-1-N)

- 0: Empty, null, unset
- 1: Single item, minimum value
- N: Multiple items, maximum, max+1, timeout

### 3. Design Concerns

- Complex dependencies
- Side effects (DB, API, external services)

### 4. Design Insights

- How these tests help "tidy" the code
- Suggestions for loose coupling
