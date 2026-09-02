---
name: commit
description: Enforces Conventional Commits 1.0.0 for all git commit messages, with a body that records why the change was made. Use this skill whenever the user asks to commit changes, create a commit, or save progress to git — including phrasings like "コミットして", "コミット切って", "commit して", "ここまで保存して", or when another skill (implement, reconstruct, pull-request) reaches its commit step. Ensures commit messages follow the conventional format with proper type, scope, and description.
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

## The body carries the why

The commit log is the only artifact that answers _why_ (code answers how, tests answer what). It is also what the `pull-request` skill lifts the PR's なぜやるか from, so a commit without a body pushes that work onto whoever writes the PR later, with less context than you have now.

Write a body whenever the subject alone would leave a future reader asking "but why?" — a one-line typo fix doesn't need one; a changed default, a removed feature, a workaround, or a rejected alternative does. Say what was wrong before, what is true now, and what you chose not to do. Don't narrate the diff; it's right there.

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

1. Run `git status --short`. If nothing is staged, ask what to include — or, when the working tree is a single logical change, propose staging it all. Never stage silently; unrelated files end up in the wrong commit
2. Run `git diff --cached --name-only` to see staged files
3. Infer the scope using the rules above
4. Determine the commit type from the nature of the changes
5. Compose the commit message following the format
6. If the user provides a message, reformat it to follow these rules

Committing ends here. `git push` is deny-listed on purpose — don't chain it after the commit; report the commit and let the user push.
