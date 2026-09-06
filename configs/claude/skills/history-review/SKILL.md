---
name: history-review
description: Reads a branch's unpushed commits the way a reviewer will and says whether the history needs rebuilding before it is pushed — which commits ship nothing of their own, which purpose is smeared across several, which commit carries two. It only judges and reports; the rewrite itself is the user's /reconstruct.
when_to_use: Whenever the user asks whether the commits are clean or ready — "コミット整理した方がいい?", "履歴見て", "commit きれい?", "このまま PR 出せる?", "squash した方がいい?" — and whenever the implement skill finishes a feature or the pull-request skill confirms its range. Also before any first push of a branch with more than one commit.
disallowed-tools: Edit, Write, NotebookEdit
---

# History review

The commits made while working are checkpoints for the author — one per
TDD cycle, one per detour, one per "oh, that broke". A reviewer reads
history by logical change, and `git bisect` lands on whichever commit is
there. This skill reads the log as that reviewer would and returns a
verdict. It never rewrites: rewriting is `/reconstruct`, which the user
runs, because history rewriting must never start on its own.

## Range

```bash
BASE=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
git fetch origin "$BASE"
git log --stat --format='%h %s' "origin/$BASE..HEAD"
```

Compare against `origin/$BASE`, not the local branch — a local default
that is ahead of the remote would hide the user's unpushed commits from
the review, and those are exactly the ones still cheap to rebuild. When
the range was handed to you — by the skill that loaded this one, or by
the user naming two commits — use it as given and say which of these
steps you therefore skipped.

Then check whether a reviewer has already seen this history:

```bash
gh pr view --json number,state --jq '.number' 2>/dev/null
```

If a PR exists, stop with **pass** and say why: history a reviewer has
read is not rewritten. Rewriting it takes away their way of seeing what
changed since their last look, and responding to review by appending
commits is what they expect. The one exception is a reviewer asking for
a squash, and that request comes from them, not from this skill.

## Read the diffs, not the subjects

Subjects say what the author meant; only the diff says what the commit
did to the branch. Read each commit with `git show --stat -p <hash>` and
look for the three shapes a subject never admits to:

- **A reversal** — a line that an earlier commit in the range added is
  deleted by a later one. The two commits cancel; the reviewer would read
  both and learn nothing.
- **A dead edit** — a file edited by one commit and deleted by a later
  commit in the same range. `git diff --name-status origin/$BASE..HEAD`
  lists the deletions; any earlier touch of those files is dead.
- **A whitespace-only commit** — `git show -w --stat <hash>` prints no
  files. A formatter ran; the content belongs to whichever commit
  produced the unformatted text.

## What fails

The history needs rebuilding when any of these holds:

- **A commit ships nothing of its own.** A typo fix for the previous
  commit, a test the previous commit broke, a formatter run, a reversal,
  a dead edit, "wip", "fix review", "fix fmt". Its content belongs inside
  the commit it corrects, or nowhere; the tell is a subject that cannot
  take a Conventional Commits type, because there is no change to type.
- **One purpose is spread over several commits.** The same file touched
  three or more times for one feature, or a test and the code that makes
  it pass in separate commits. TDD produces exactly this shape on purpose —
  which is why the check exists — and the reviewer wants the feature, not
  the cycles.
- **One commit carries two purposes.** A structural change and a
  behavioural change together, or a subject that cannot take a single
  Conventional Commits type without an "and". Tidy First puts the
  structural commit first, on its own.
- **An intermediate commit does not build or pass on its own.** Judge from
  the log when you cannot run the checks at each commit: a later "fix
  build" or "fix test" commit is the evidence.

What passes: each commit is one logical change, in dependency order, and
structure comes before behaviour — a refactor, then the feature it made
possible, then its docs. A single commit passes. A branch carrying two
unrelated but individually clean commits passes too; whether it should
be two PRs is the `pull-request` skill's question, not this one's. Don't
fail a clean log to make history look busier; three well-cut commits are
better than one squash.

## Verdict

Report in this shape, then stop:

```markdown
**Verdict:** pass | rebuild
**Range:** origin/<base>..HEAD (<N> commits)

<pass — one or two sentences on why the commits read cleanly, and stop here>

<rebuild — one bullet per offending commit: hash, subject, which rule it breaks>

**Proposed commits:**

1. <type(scope): subject> — <files>
2. ...
```

The proposed list appears only on **rebuild**. It is the grouping
`/reconstruct` will ask for in its Step 3; writing it here saves the user
a round trip. Order it the way that skill does: dependencies first,
structure before behaviour, every intermediate state buildable. An
unrelated change that rode along stays its own commit — it is not what
is being rebuilt.

On **rebuild**, hand the user `/reconstruct` — say plainly that the skill
is user-invocable only, so it has to be typed. On **pass**, say so and
move on to whatever asked for the review. Either way this runs **once,
before the first push**: detours during implementation cost nothing
extra, because the rebuild starts from the final diff and never looks
at the intermediate commits, so ten wrong turns rebuild the same as none.
