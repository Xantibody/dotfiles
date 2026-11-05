---
name: delegate
description: Turns one request into a .ai/plans/ checklist and hands it to an unattended `autopilot` run in a detached felis session, then returns at once — the run implements, checks and commits on its own and notifies when it ends. Also reports on a run already started. Nothing is pushed.
when_to_use: When the user wants work done without staying at the keyboard — "autopilot で実装して", "放置で実装して", "寝てる間にやっといて", "任せた", "無人で回して", "自走させて", "裏で実装しといて" — and when they ask how a run is going — "autopilot どうなった?", "終わった?", "進捗見せて".
---

# Delegate

The user gives one instruction and walks away. This skill's job is to make
that instruction into something an agent with nobody to ask can finish,
start it, and get out of the way. The run itself is the `autopilot`
launcher (`autopilot -d`), which spawns a felis session, resumes Claude
Code until the plan's checklist is done or the deadline passes, and
raises a desktop notification at the end. This session does not wait for
it.

## 1. Check the ground

Run these and stop only on a real blocker; anything else is decided here
and written into the plan.

```bash
git rev-parse --show-toplevel        # must be a git repository
git status --porcelain               # must be empty
command -v autopilot felis           # both must exist
```

- Uncommitted changes: the run commits as it goes, and someone else's
  edits would land in its commits. Say which files are dirty and stop;
  this is the one case where the user has to act first.
- No `autopilot` or `felis`: say which is missing and stop.

## 2. Write the plan

Read what the request touches first: the repository's CLAUDE.md, the
anchors of the files involved (`anchors` skill), and the code itself
(codegraph). A plan written from the request alone is a guess the run
will have to undo.

Write `.ai/plans/<kebab-case-slug>.md`:

```markdown
# <what is being built, one line>

## Context

<why the user wants it, in their words where possible; what exists today>

## Assumed

- <every reading you chose where the request was open, with the reason>

## Checklist

- [ ] <one behaviour, observable by a test or a command>
- [ ] ...
```

- **One behaviour per item**, in the order they can be built. An item the
  run cannot verify ("make it nicer") is not an item; turn it into the
  behaviour the user would check.
- **Checkboxes only in the checklist.** The Stop hook counts every
  `- [ ]` in the file as open work.
- **No questions.** The user chose not to be asked. Where the request is
  open, pick the reading that is literal and smallest, and put it under
  Assumed so the user can see it before the run gets far.
- **Scope stays the request's.** A refactor the code invites, a follow-up
  the user did not mention: leave them out, or name them under Assumed as
  not included.

## 3. Start it

```bash
autopilot -d [-w <type>/<slug>] -H <hours> .ai/plans/<slug>.md
```

`<hours>` is the user's if they gave one ("朝までに" from now, "2 時間で");
otherwise 4. The command prints the felis session id and returns at once.

Add `-w <type>/<slug>` (Conventional Commits type, the plan's slug) when
the repository's CLAUDE.md wants a branch for a change of this size, and
always when another run is already working in this checkout
(`felis sessions list --tag autopilot` shows one with no
`autopilot:done` / `autopilot:stopped` tag and the same `spawn_cwd`).
The run then lives in `<repo>@<type>/<slug>`: its plan, journal and
commits are there, not here, so the status commands below run in that
directory. Without `-w` the run commits on the current branch.

## 4. Report and end the turn

Tell the user, briefly: the plan path and its checklist, everything under
Assumed, the session id with `felis attach <id>`, and that a notification
arrives when the run ends. Then end the turn; do not poll the run.

## When asked how it is going

```bash
felis sessions list --tag autopilot --format json \
  | jq -r '.sessions[] | "\(.short_id) \(.tags | join(",")) \(.spawn_cwd)"'
grep -c '^\s*- \[x\]' .ai/plans/<slug>.md; grep -E '^\s*- \[ \]' .ai/plans/<slug>.md
tail -40 .ai/autopilot/journal.md
git log --oneline -20
```

`autopilot:done` or `autopilot:stopped` on the session is the outcome; no
such tag means it is still running. Report the items ticked and open,
anything the journal marks `not done` or `assumed`, and the commits. When
it is done, the next step is the user's: review the commits and push, or
load the `pull-request` skill if they ask for a PR.
