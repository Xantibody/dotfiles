---
name: reconstruct
description: Reconstruct git commit history on a development branch. Resets messy unpushed commits back to a clean diff against the base branch, then rebuilds logically coherent, minimal commits one by one. A more controllable alternative to interactive rebase. Runs without asking — nothing reaches the remote until the user pushes.
when_to_use: Whenever the goal-review skill, run against this skill's Goal, returns rebuild — load this right after it, without handing the user a command. Also when the user wants to clean up commits, reorganize history, split commits, squash and recommit, or tidy up before a PR — "コミット整理して", "履歴作り直して", "squash して", "コミット分けて".
---

# Git History Reconstruction

Reset messy development branch history and rebuild it as logically coherent, minimal commits from the final diff against the base branch.

Since `git rebase -i` requires interactive input and cannot be used in Claude Code, this skill achieves equivalent or better results using `git reset --soft` combined with incremental `git add`.

Whether a history needs this at all is judged by the `goal-review` skill against the Goal below; it is what the `implement` and `pull-request` skills run, and on **rebuild** this skill follows it directly. The reset runs without asking because it is local and recoverable: the original HEAD is recorded before it and stays reachable through `git reflog`, and the remote changes only on a push, which stays with the user (`git push` is deny-listed). What it never does is rewrite history someone else has read — see Step 1.

## Goal

The commits made while working are checkpoints for the author — one per TDD cycle, one per detour, one per "oh, that broke". A reviewer reads history by logical change, and `git bisect` lands on whichever commit is there. The goal is a history that reads that way.

**Target.** The unpushed commits of the current branch:

```bash
BASE=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
git fetch origin "$BASE"
git log --stat --format='%h %s' "origin/$BASE..HEAD"
```

Compare against `origin/$BASE`, not the local branch — a local default that is ahead of the remote would hide the user's unpushed commits, and those are exactly the ones still cheap to rebuild. A range handed in by the caller or named by the user is used as given; the verdict prints it and says which of these steps were therefore skipped. Then `gh pr view --json number,state --jq '.number' 2>/dev/null`: if a PR exists, the verdict is **pass** with that reason and the review stops there — no reading of the diffs, no list of commits that would otherwise fail, one or two sentences in all. History a reviewer has read is not rewritten, and responding to review by appending commits is what they expect. The one exception is a reviewer asking for a squash, and that request comes from them.

**Reading rule.** Subjects say what the author meant; only the diff says what the commit did. Read each commit with `git show --stat -p <hash>` and look for the shapes a subject never admits to:

- **A reversal** — a line an earlier commit in the range added is deleted by a later one.
- **A dead edit** — a file edited by one commit and deleted by a later one in the range (`git diff --name-status origin/$BASE..HEAD` lists the deletions).
- **A whitespace-only commit** — `git show -w --stat <hash>` prints no files.

**Items.** The history needs rebuilding when any of these holds:

- **A commit ships nothing of its own.** A typo fix for the previous commit, a test the previous commit broke, a formatter run, a reversal, a dead edit, "wip", "fix review", "fix fmt". The tell is a subject that cannot take a Conventional Commits type, because there is no change to type.
- **One purpose is spread over several commits.** The same file touched three or more times for one feature, or a test and the code that makes it pass in separate commits. TDD produces exactly this shape on purpose, and the reviewer wants the feature, not the cycles.
- **One commit carries two purposes.** A structural and a behavioural change together, or a subject that needs an "and". Tidy First puts the structural commit first, on its own.
- **An intermediate commit does not build or pass on its own.** When the checks cannot run at each commit, a later "fix build" or "fix test" commit is the evidence.

What passes: each commit is one logical change, in dependency order, structure before behaviour. A single commit passes. Two unrelated but individually clean commits pass too; whether they should be two PRs is the `pull-request` skill's question. Don't fail a clean log to make history look busier.

**Verdict.**

```markdown
**Verdict:** pass | rebuild
**Range:** <the range reviewed> (<N> commits)
**Skipped:** <only when the range was handed in — the fetch or PR check not run>

<pass — one or two sentences on why the commits read cleanly, or that a PR already exists>

<rebuild — one bullet per offending commit: hash, subject, which item it breaks>

**Proposed commits:**

1. <type(scope): subject> — <files>
```

The proposed list appears only on **rebuild**. It folds every commit that ships nothing of its own into the one it corrects and gathers each purpose spread over several commits into one, so it is shorter than the range; split a commit only for a second purpose, never for size. It is ordered as Step 3 orders groups: dependencies first, structure before behaviour, every intermediate state buildable. An unrelated change that rode along stays its own commit. The list never drops a change: the rebuild reproduces the branch's final diff exactly, so a whitespace-only commit whose unformatted text predates the range becomes its own `style` commit, not a deletion.

**Hand-over.** On **rebuild**, load this skill and run the procedure below with the proposed list — no approval first, for the reasons above. On **pass**, say so and return to whatever asked. The review runs **once, before the first push**: detours cost nothing extra, because the rebuild starts from the final diff, so ten wrong turns rebuild the same as none.

## Procedure

### Step 1: Identify the base branch

Do not assume the base branch is `main`. When a `goal-review` verdict handed over a range, use its base. Otherwise:

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

If a `goal-review` verdict with a **Proposed commits** list is already in the conversation, use that list rather than re-deriving it — the user has seen it, and re-grouping from scratch gives them two proposals to reconcile. Otherwise, classify the changed files into logical commit groups. Criteria:

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

   If only part of a file belongs to this group, `git add -p` is interactive and unavailable. Write the group's hunks of `git diff <file>` to a patch in the scratchpad and stage them with `git apply --cached <patch>`; the rest of the file stays unstaged for a later group.

2. **Check the staged set** against the group with `git diff --cached --stat`.

3. **Create the commit** using the `commit` skill to follow Conventional Commits format. The messages are new, but the references the original commits carried are not yours to drop: list them with

   ```bash
   git log --format='%h %s%n%b' <base>..<original-HEAD> | grep -E '^[0-9a-f]{7,} |^Prevents: [0-9a-f]|^(Closes|Fixes|Refs):? #'
   ```

   and carry each `Prevents:` line into the rebuilt commit that holds the check it names (the `guardrail` skill's Goal counts a closure only through that trailer), and each `Closes` / `Fixes` / `Refs` line into the rebuilt commit that holds its change — a `Closes` on the last one for that issue. Never copy `Verified-by:`: the commit-msg hook writes it for the tree being committed, and only the last rebuilt commit can match a tree that was verified.

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
