---
name: reconstruct
description: Reconstruct git commit history on a development branch. Resets messy commits back to a clean diff against the base branch, then guides the user to rebuild logically coherent, minimal commits one by one. Use this skill when the user wants to clean up commits, reorganize history, split commits, squash and recommit, or tidy up before a PR. Provides a more controllable alternative to interactive rebase.
disable-model-invocation: true
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
2. If no PR exists, ask the repo for its default branch and find the merge base:
   ```bash
   BASE=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
   git fetch origin "$BASE"
   git merge-base "origin/$BASE" HEAD
   ```
   Use `origin/$BASE`, not the local branch — a local default that is ahead of the remote would fold the user's unpushed commits into the reconstruction.
3. **Always confirm with the user** which branch to reconstruct against before proceeding.

### Step 2: Survey changes

```bash
git log --oneline <base>..HEAD
git diff --stat <base>..HEAD
```

Show the user the commit list and changed files. If there are uncommitted changes, ask whether they belong in the reconstruction (commit them via the `commit` skill first) or not (stash them). Leaving them in the working tree means `git reset --soft` mixes them into the unstaged pool and they get silently absorbed into whichever group is staged next.

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

If the branch was already on the remote, the rewritten history needs a force push. `git push` is deny-listed on purpose — hand the user the exact command in the form `! git push --force-with-lease origin <branch>` (`--force-with-lease` refuses to overwrite commits that arrived on the remote since the last fetch, which `--force` would silently destroy).

## Important

- Never execute `git reset --soft` without explicit user approval
- If the user wants to abort mid-reconstruction, recover with `git reflog` and `git reset --hard <original-HEAD>`
