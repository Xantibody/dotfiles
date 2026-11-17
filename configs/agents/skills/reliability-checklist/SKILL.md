---
name: reliability-checklist
description: Applies a repository's REVIEW.md — rows of a trigger (a path glob or a diff regex), a check, and the commit of the incident behind it — to the current change, reading the table from the base branch, and prints only the rows the diff hits so each can be checked before the work is called done.
when_to_use: When the implement skill reaches Finishing or the pull-request skill runs its Pre-flight. Also when the user asks whether a change touches a place that broke before, or wants an incident kept as a check — "REVIEW.md 当てて", "前に壊れたところ触ってない?", "チェックリスト見て", "この事故を REVIEW.md に足して".
---

# Reliability checklist

What broke before, and how to look for it again, usually lives in a
comment beside the code that broke — read only by someone who already
opened that file. `REVIEW.md` at the repository root turns each lesson
into a row the diff calls up: a trigger, what to check, and the commit
whose body tells the incident. Which rows fire is decided by paths and
regexes, so a command decides it, not you; what to do about a row that
fires is your judgement.

## Apply it

From anywhere inside the repository:

```bash
rat checklist
```

It reads `REVIEW.md` from the base (`origin/HEAD`; pass `--base <ref>`
when that is unset or another branch is the base), never from the
working tree, so a branch that drops or loosens a row is still checked
against the row it dropped. The change is the merge-base diff
(`<base>...HEAD`) plus staged, unstaged and untracked files, so it
covers a feature branch and unpushed commits made straight onto the
default branch alike. stdout is a table of the rows hit, with the files
that fired each; empty stdout means no row fired. stderr says how many
rows were read, and notes when the repository has no `REVIEW.md` on the
base (nothing to do) or when the branch's copy differs from the base's
(its new rows apply only once they reach the base). Run `git fetch
origin` first when the base may be stale.

A non-zero exit is a broken table or a base that is not there; fix
what the message names rather than skipping the checklist.

## Act on each row

For every row printed, do what its Check column says against this
change, and read the incident commit (`git show <hash>`) when the check
alone does not say what to look for. Then, per row, one of:

- **holds** — what was checked and how, in a line;
- **fixed** — the check found the problem again: fix it as a new Red in
  the implement cycle, then check again;
- **cannot check here** — the check needs CI, another platform or the
  user (a macOS build from Linux, a deploy); say what would check it.

The rows and their outcomes go in the report to the user, and in a PR
body's やったこと when the PR changed what a row guards. A row that fired
but has nothing to do with the change is still listed, with why it does
not apply; a trigger that keeps firing without cause is a reason to
narrow it in its own commit.

## Write a row

The table format, with comments on each column, is
`assets/REVIEW.md`; copy it to a repository that has none. A row
earns its place from an incident that happened — a commit whose body
says what broke — and its trigger is the narrowest set of paths, or the
diff regex, that would have fired on the change that caused it:

- a path glob is matched against the whole repo-relative path: `*` and
  `?` stay within one directory, `**` crosses them (`modules/**/*.nix`);
- `/regex/` matches an added or removed line of the diff, in Go's RE2
  syntax, with a `|` inside the cell written as `\|`.

Several backticked patterns in one cell fire the row on any of them.
A new row reaches the checklist only when it reaches the base; that is
the point, since the branch under review cannot vouch for itself.
