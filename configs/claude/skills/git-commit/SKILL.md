---
name: git-commit
description: Commit discipline for TDD workflow. Use when ready to commit code changes with proper structural/behavioral separation.
---

# Commit Discipline

## Pre-Commit Checklist

Only commit when:
1. ALL tests are passing
2. ALL compiler/linter warnings have been resolved
3. The change represents a single logical unit of work

## Change Type Separation

Commits must clearly indicate their type:

| Type | Prefix | Description |
|------|--------|-------------|
| Structural | `refactor:` | Code rearrangement without behavior change |
| Behavioral | `feat:`, `fix:` | New functionality or bug fixes |

**Never mix structural and behavioral changes in the same commit.**

## Commit Message Format

```
<type>: <concise description>

[optional body with details]
```

Examples:
- `refactor: extract validation logic to separate function`
- `feat: add user authentication endpoint`
- `fix: correct off-by-one error in pagination`

## Workflow

1. Run all tests before committing
2. Stage only related changes (avoid mixing concerns)
3. Write clear commit message with type prefix
4. Verify tests still pass after commit

Use small, frequent commits rather than large, infrequent ones.
