---
name: reconstruct
description: Reconstruct git commit history on a development branch. Resets messy commits back to a clean diff against the base branch, then guides the user to rebuild logically coherent, minimal commits one by one. Use this skill when the user wants to clean up commits, reorganize history, split commits, squash and recommit, or tidy up before a PR. Provides a more controllable alternative to interactive rebase.
---

# Git History Reconstruction

Reset messy development branch history and rebuild it as logically coherent, minimal commits from the final diff against the base branch.

Since `git rebase -i` requires interactive input and cannot be used in Claude Code, this skill achieves equivalent or better results using `git reset --soft` combined with incremental `git add`.

## Procedure

### Step 1: Identify the base branch

Do not assume the base branch is `main`. Determine it by:

1. Check if there is an open PR for the current branch:
   ```bash
   gh pr view --json baseRefName --jq '.baseRefName' 2>/dev/null
   ```
2. If no PR exists, infer from merge-base:
   ```bash
   git merge-base --fork-point main HEAD 2>/dev/null || git merge-base main HEAD
   ```
3. **Always confirm with the user** which branch to reconstruct against before proceeding.

### Step 2: Survey changes

```bash
git log --oneline <base>..HEAD
git diff --stat <base>..HEAD
```

Show the user the commit list and changed files. If there are uncommitted changes, ask whether to stash them first.

### Step 3: Analyze and propose logical groups

Classify the changed files into logical commit groups. Criteria:

| Perspective  | Examples                                             |
| ------------ | ---------------------------------------------------- |
| Layer        | Domain / Application / Infrastructure / Presentation |
| Change type  | refactor / feat / fix / test / docs / chore          |
| Feature unit | auth module / API endpoint / UI component            |

Present the proposed grouping to the user with a recommended commit order. Principles:

- **Dependency order**: commits that others depend on come first
- **Structure before behavior**: following Tidy First, put refactoring commits before feature commits
- **Each commit should be buildable/testable**: no broken intermediate states

### Step 4: Reset

This is a destructive operation. Before executing:

1. Record the current HEAD for recovery:
   ```bash
   git rev-parse HEAD
   ```
2. Show the commits that will be collapsed:
   ```bash
   git log --oneline <base>..HEAD
   ```
3. Inform the user that recovery is possible via `git reflog` if anything goes wrong.
4. **Get explicit approval from the user** before proceeding.

Then execute:

```bash
git reset --soft <base>
```

After reset, all changes are staged. Unstage everything to allow selective re-staging:

```bash
git restore --staged .
```

Verify with `git status`.

### Step 5: Rebuild commits

For each proposed logical group, repeat:

1. **Stage files** for this group:

   ```bash
   git add <file1> <file2> ...
   ```

   If only part of a file belongs to this group, inform the user and suggest they run `git add -p <file>` manually (interactive command, cannot be run by Claude Code).

2. **Review staged changes** with the user:

   ```bash
   git diff --cached --stat
   ```

3. **Create the commit** using the `commit` skill to follow Conventional Commits format.

4. **Check remaining changes**:

   ```bash
   git status
   ```

5. Repeat until all changes are committed.

### Step 6: Verify completeness

Ensure no changes were lost:

```bash
git log --oneline <base>..HEAD
git diff <base>..HEAD
```

The `git diff` output should be empty — the final state must be identical to what it was before the reconstruction. If there is any diff, investigate and resolve with the user.

Remind the user that a force push (`git push --force-with-lease`) will be needed if the branch was already pushed to the remote.

## Important

- Never execute `git reset --soft` without explicit user approval
- Never force push without explicit user approval — use `--force-with-lease` over `--force`
- If the user wants to abort mid-reconstruction, recover with `git reflog` and `git reset --hard <original-HEAD>`
