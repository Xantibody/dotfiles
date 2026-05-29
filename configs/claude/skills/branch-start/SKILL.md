---
name: branch-start
description: Ensure new feature work starts on an appropriate branch. Use this skill whenever the user asks to start a new feature, implement something new, fix a bug as a new piece of work, or before invoking `implement` / `execute-plan`. Checks the current branch against the GitHub default and offers to switch or create a worktree if mismatched.
---

# Branch Start

Confirm the working branch is appropriate before starting new feature work. Never begin on a non-default branch silently.

## Workflow

### 1. Detect Current and Default Branch

```bash
git branch --show-current
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

If `gh` is unavailable or the repo has no GitHub remote, fall back to `git symbolic-ref refs/remotes/origin/HEAD --short | sed 's|^origin/||'`.

### 2. Decide

- **Current branch == default**: proceed with the work directly (still recommend creating a feature branch for non-trivial changes).
- **Current branch != default**: stop and ask the user to choose:
  1. **Create a new branch from default (Recommended)**: `git switch <default> && git pull && git switch -c <feature-branch>`
  2. **Use a worktree**: `git worktree add ../<repo>-<feature> <default>` to keep the current branch intact
  3. **Continue on current branch**: only if the user confirms the work belongs to this branch

### 3. Proceed

Once the branch decision is confirmed, hand off to the next skill (`implement`, `execute-plan`, `define`, etc.) or begin the work.

## Important

- Never start new feature work on a non-default branch without explicit user confirmation.
- For repositories without a clear default branch (no GitHub remote, detached HEAD), ask the user which branch to base the work on.
