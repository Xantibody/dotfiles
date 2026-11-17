---
name: goal-review
description: Judges where something stands against the Goal another skill declares — a repository against `baseline`'s, a branch's unpushed history against `reconstruct`'s, a finished change against `implement`'s — and returns that Goal's verdict. It reads the Goal and runs its tests, never the owning skill's procedure; the owning skill does the work.
when_to_use: Whenever the user asks whether something is already in the state a skill aims for — "環境どこまでできてる?", "baseline 見て", "履歴見て", "コミット整理した方がいい?", "commit きれい?", "このまま PR 出せる?", "実装終わった?", "完了でいい?" — whenever the implement skill finishes a feature (against its own Goal, then reconstruct's), whenever the pull-request skill confirms its range (against reconstruct's Goal), and whenever the baseline skill starts (against its own Goal).
---

# Goal review

A skill that changes things says in a `## Goal` section what state it
produces. This skill measures how far the present is from that state and says
so. It never changes anything: the change is the owning skill's job, kept
apart so that other work can ask "is it there yet?" without carrying the
procedure, and so that the answer comes from tests rather than from the
author's memory of what they did.

## Which Goal

The caller names the skill (`goal-review` against `reconstruct`). When the
user asks without naming one, take it from what they ask about: a
repository's setup, tooling or CI is `baseline`; a branch's commits are
`reconstruct`; whether a change is finished — its checks, its smoke run, its
screen — is `implement`. If none fits, ask.

Read `<name>/SKILL.md` in the directory this skill sits in (`~/.claude/skills`
for Claude Code, `~/.agents/skills` for codex): its `## Goal` section, and the
files that section names, and nothing below it. The procedure is for the
owning skill; reading it here invites doing it. A skill without a `## Goal`
section has nothing to be reviewed against — say so and stop.

## What a Goal declares

- **Target** — what is judged and how to find it: a repository, the range
  `origin/<default>..HEAD`, and any precondition (a clean tree, no open PR).
- **Items** — each part of the state, with the test that decides it. A test
  is a command, a file check or a reading rule written in the Goal or in a
  file it names.
- **Verdict** — the shape of the report, including the states an item can be
  in.
- **Hand-over** — when this review loads the owning skill, and with what.

## Running the tests

- Run every test the Goal names. An item is never judged from a file's
  presence or a commit subject alone; that shortcut is what this review
  exists to replace.
- A test that could not run — no network, a tool missing, a precondition not
  met — leaves its item `unknown`, with the reason. `unknown` is never
  reported as passing.
- Change nothing: no edit, no commit, no install. A test the Goal says
  rewrites files runs only under the precondition the Goal gives, and what it
  leaves is evidence, not something to clean up. This is a rule here rather
  than `disallowed-tools`, because that removal lasts until the user's next
  message and would leave the owning skill unable to edit after the hand-over.
- Run nix one command at a time.

## Report

Use the Goal's verdict shape and nothing beyond it. Its bold labels
(`**Verdict:**`, `**Proposed commits:**`) are copied as written, not
translated, because the owning skill and the user's tools look for them; the
prose around them follows the user's language. Where the Goal says to stop —
a precondition that settles the verdict on its own — stop there: no further
tests, no list of what would have failed otherwise. When the Goal has no
verdict shape, use:

```markdown
**Goal:** <skill> — **Target:** <what was judged>

| Item | State | Evidence |
| ---- | ----- | -------- |

**Next:** <the first item that does not hold, and what it lacks>
```

Then follow the Goal's hand-over rule: load the owning skill when the rule
says to, passing it the verdict, and otherwise stop at the report — the next
step belongs to whoever asked.
