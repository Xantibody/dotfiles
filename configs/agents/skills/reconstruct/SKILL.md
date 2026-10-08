---
name: reconstruct
description: Reconstruct git commit history on a development branch. Resets messy unpushed commits back to a clean diff against the base branch, then rebuilds logically coherent, minimal commits one by one. A more controllable alternative to interactive rebase. Runs without asking — nothing reaches the remote until the user pushes.
when_to_use: Whenever the history-review skill returns rebuild — load this right after it, without handing the user a command. Also when the user wants to clean up commits, reorganize history, split commits, squash and recommit, or tidy up before a PR — "コミット整理して", "履歴作り直して", "squash して", "コミット分けて".
---

# Git History Reconstruction

Reset messy development branch history and rebuild it as logically coherent, minimal commits from the final diff against the base branch.

Since `git rebase -i` requires interactive input and cannot be used in Claude Code, this skill achieves equivalent or better results using `git reset --soft` combined with incremental `git add`.

Whether a history needs this at all is the `history-review` skill's call; it is what the `implement` and `pull-request` skills run, and on **rebuild** this skill follows it directly. The reset runs without asking because it is local and recoverable: the original HEAD is recorded before it and stays reachable through `git reflog`, and the remote changes only on a push, which stays with the user (`git push` is deny-listed). What it never does is rewrite history someone else has read — see Step 1.

## Procedure

### Step 1: Identify the base branch

Do not assume the base branch is `main`. When `history-review` handed over a range, use its base. Otherwise:

1. Check if there is an open PR for the current branch:
   ```bash
   gh pr view --json number,baseRefName 2>/dev/null
   ```
   If one exists, stop and ask the user: a reviewer has read that history, and rewriting it takes away their way of seeing what changed since their last look. Go on only if the user says so (typically because the reviewer asked for a squash), against the PR's `baseRefName`.
2. If no PR exists, ask the repo for its default branch and find the merge base:
   ```bash
   BASE=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
   git fetch origin "$BASE"
   git merge-base "origin/$BASE" HEAD
   ```
   Use `origin/$BASE`, not the local branch — a local default that is ahead of the remote would fold the user's unpushed commits into the reconstruction.

Report the base you chose in one line and continue.

### Step 2: Survey changes

```bash
git log --oneline <base>..HEAD
git diff --stat <base>..HEAD
```

If there are uncommitted changes, ask whether they belong in the reconstruction (commit them via the `commit` skill first) or not (stash them). This is the one question the skill always asks: leaving them in the working tree means `git reset --soft` mixes them into the unstaged pool and they get silently absorbed into whichever group is staged next, and which way they go is the user's call.

### Step 3: Analyze and group

If a `history-review` verdict with a **Proposed commits** list is already in the conversation, use that list rather than re-deriving it — the user has seen it, and re-grouping from scratch gives them two proposals to reconcile. Otherwise, classify the changed files into logical commit groups. Criteria:

| Perspective  | Examples                                             |
| ------------ | ---------------------------------------------------- |
| Layer        | Domain / Application / Infrastructure / Presentation |
| Change type  | refactor / feat / fix / test / docs / chore          |
| Feature unit | auth module / API endpoint / UI component            |

Order the groups by these principles, then proceed:

- **Dependency order**: commits that others depend on come first
- **Structure before behavior**: following Tidy First, put refactoring commits before feature commits
- **Each commit should be buildable/testable**: no broken intermediate states

### Step 4: Reset

Record the current HEAD — it is the recovery point and goes into the final report:

```bash
git rev-parse HEAD
```

Then reset and unstage everything to allow selective re-staging:

```bash
git reset --soft <base>
git restore --staged .
```

Verify with `git status`.

### Step 5: Rebuild commits

For each group, repeat:

1. **Stage files** for this group:

   ```bash
   git add <file1> <file2> ...
   ```

   If only part of a file belongs to this group, `git add -p` is interactive and unavailable. Write the group's hunks of `git diff <file>` to a patch in the scratchpad and stage them with `git apply --cached <patch>`; the rest of the file stays unstaged for a later group. Write the patch from Bash (a heredoc), not with Write: when `history-review` ran earlier in the same turn, its `disallowed-tools` still holds Edit and Write until the user's next message.

2. **Check the staged set** against the group with `git diff --cached --stat`.

3. **Create the commit** using the `commit` skill to follow Conventional Commits format.

4. **Check remaining changes** with `git status`, and repeat until all changes are committed.

### Step 6: Verify completeness

Ensure no changes were lost:

```bash
git log --oneline <base>..HEAD
git diff <original-HEAD> HEAD
```

The `git diff` output must be empty — the final tree is identical to the one before the reconstruction. If it is not, restore with `git reset --hard <original-HEAD>` and report what went wrong instead of patching the difference in.

Report the new log, and the original HEAD with the one-line way back (`git reset --hard <original-HEAD>`), so the user can compare before pushing.

If the branch was already on the remote, the rewritten history needs a force push. Hand the user the exact command in the form `! git push --force-with-lease origin <branch>` (`--force-with-lease` refuses to overwrite commits that arrived on the remote since the last fetch, which `--force` would silently destroy).

## Important

- Never push. The remote is the line this skill does not cross; the user does.
- To abort mid-reconstruction, `git reset --hard <original-HEAD>`; `git reflog` has it if the recorded hash is lost.
