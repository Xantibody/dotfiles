---
name: commit
description: Enforces Conventional Commits 1.0.0 for all git commit messages. Use this skill whenever the user asks to commit changes, create a commit, or save progress to git. Ensures commit messages follow the conventional format with proper type, scope, and description.
---

# Conventional Commits (commit)

All commit messages follow the [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- **type**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **description**: imperative present tense ("add" not "added"), no capitalized first letter, no trailing dot
- **body**: explains the motivation for the change and contrasts with previous behavior
- **breaking changes**: append `!` after type/scope, or add a `BREAKING CHANGE:` footer

## Atomic Commits

Each commit represents a single logical change. Never combine unrelated features, fixes, or refactoring in one commit — recommend splitting instead. Atomic commits enable `git bisect`, clean reverts, and reviewable history.

## Scope Inference

Determine the scope from the staged changes:

1. Run `git log --oneline -20` to learn the repository's existing scope conventions.
2. Run `git diff --cached --name-only` and map staged files to a scope following those conventions (typically the top-level directory, module, or component name).
3. If the project's CLAUDE.md defines explicit scope rules, those take precedence over inference.

### Multi-Scope Resolution

- All files map to a **single scope**: use that scope
- One scope covers the **majority** (>70%) of changed files: use that scope
- Files map to **multiple unrelated scopes**: omit the scope and recommend splitting into atomic commits
- The user explicitly provides a scope: use it regardless of inference

## How to Use

When asked to commit changes:

1. Run `git diff --cached --name-only` to see staged files
2. Infer the scope using the rules above
3. Determine the commit type from the nature of the changes
4. Compose the commit message following the format
5. If the user provides a message, reformat it to follow these rules
