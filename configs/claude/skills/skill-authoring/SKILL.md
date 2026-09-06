---
name: skill-authoring
description: House rules and pre-flight for creating or changing a Claude Code skill (a SKILL.md under ~/.claude/skills) — check what the spec and Anthropic's repos say today, cut the skill by job so other workflows can load it, validate the frontmatter with the bundled checker, then hand drafting and testing to skill-creator. It does not write the skill itself.
when_to_use: Whenever the user asks to create, add, change, split, rename, or review a skill — "skill 作って", "skill 直して", "skill 追加して", "この作業を skill にして", "SKILL.md を書いて" — and before loading skill-creator for any reason. Also when a skill-creator script rejects a frontmatter field, or when a skill needs a frontmatter option and it is unclear whether one exists.
---

# Skill authoring

The skill spec changes monthly and the tooling lags it. On the day this
skill was written, skill-creator's bundled validator rejected
`disallowed-tools` and `when_to_use` — both documented fields — because
its allowed list was frozen at the six Agent Skills fields. So the order
of work is fixed: read what is true today, shape the skill, validate it
against the live spec, and only then draft and test with skill-creator.

## 1. Read what is true today

Fetch the spec, not memory. Three sources, in this order:

- **The frontmatter reference:** `https://code.claude.com/docs/en/skills.md`
  (the `.md` URL returns markdown). Read the `Frontmatter reference`
  table. A field may already do what the skill was about to do in prose —
  `paths` for file-scoped activation, `context: fork` for isolation,
  `user-invocable: false` for background knowledge, `hooks` for something
  that must run every time.
- **The changelog:** `https://code.claude.com/docs/en/changelog.md`. Read
  the entries since the skill directory's last commit
  (`git log -1 --format=%ad -- configs/claude/skills`) for "skill",
  "command", "frontmatter", "hook", "plugin". Note anything that changes
  how skills load or trigger.
- **Anthropic's repos:** an official skill that covers the job is a
  reason to install it, not to write one.

  ```bash
  gh api repos/anthropics/skills/contents/skills --jq '.[].name'
  gh api repos/anthropics/claude-plugins-official/contents/plugins --jq '.[].name'
  gh api 'repos/anthropics/claude-code/releases?per_page=5' --jq '.[].tag_name'
  ```

Write down, in the report to the user, what changed since the last skill
was written and whether it affects the one being built. A check nobody
can see the result of was not done.

## 2. Cut by job

One skill, one job, composed by name: a skill says "load the `explain`
skill" and the model does. The Skill tool is the only composition
mechanism the docs describe, and it works only if each piece is small
enough to be worth loading on its own.

- **Judgement and action are two skills.** `history-review` decides
  whether a branch needs rebuilding; `reconstruct` rebuilds it. The
  judgement can then run from `implement` and `pull-request` without
  either of them being able to start a rewrite.
- **A rule two skills share is a third skill.** `explain` holds the
  bullet-structure rule that `pull-request` and `issue` both load. Copying
  it into both is how the copies drift.
- **The frontmatter says who may start it.** Rewrites history, deletes,
  tags, pushes: `disable-model-invocation: true`. That hides the skill
  from the model completely — description and all — so the skill that
  decides has to hand the user `/name` to type. Background knowledge
  nobody would type as a command: `user-invocable: false`. A skill that
  only reads and reports: `disallowed-tools: Edit, Write, NotebookEdit`.
  Trigger phrases: `when_to_use`, which the listing appends to
  `description` under one shared 1,536-character cap.

House conventions, since the repo's skills are read together: the body is
English, trigger phrases in `when_to_use` are Japanese because that is
what the user types, no README or CHANGELOG inside the skill directory,
evals in `evals/evals.json`, and the eval workspace is the sibling
`<name>-workspace/`, which `.gitignore` already covers with
`*-workspace/`.

## 3. Validate

```bash
go run ~/.claude/skills/skill-authoring/scripts/validate/main.go <skill-dir>...
```

The checker reads the frontmatter and fails on: a field the live docs
table does not list, a missing `name` or `description`, a `name` that
differs from the directory (the house rule that makes `/name` match the
path), `description` plus `when_to_use` over the documented cap, both
invocation switches turned off at once, and a body that asks to load a
sibling skill that does not exist. It fetches the field
list from the docs page each run and falls back to the list baked into
the source when offline; when the two differ it says so, and that
warning is the signal that the spec moved and the fallback needs
updating. Run it on every skill you touched, and on all of them when the
docs changed — a field being removed affects skills nobody opened.

## 4. Draft and test with skill-creator

Load the `skill-creator:skill-creator` skill for the draft and the eval
loop. It is the only harness that runs unassisted today: `claude plugin
eval` is early access, gated per organisation, and uses a different
format (markdown cases with typed graders) that skill-creator does not
read.

Write two or three evals from real history in the repo — a range of
commits, a file that exists — with assertions a grader can check against
the transcript, and run one baseline without the skill so the report can
say what the skill added. Two leaks make that comparison worthless, and
both happened the first time this was tried:

- **The executor must see only the prompt.** `prepare_eval.py` writes
  the assertions into `eval_metadata.json` next to the prompt, and
  `copy_skill.py` copies `evals/evals.json` along with the skill. An
  executor that reads either answers to the rubric — the baseline for
  `history-review` reproduced the skill's exact vocabulary that way.
  Paste the prompt into the executor's instructions and delete the
  metadata and `evals/` from the run directory before it starts.
- **The baseline must not see the skill.** An untracked skill in the
  working tree, or an edited neighbour that names it, is readable from
  the same checkout. Run the baseline in a worktree at the commit before
  the skill existed (`git worktree add <dir> <commit>`).

Say in the report which of these held for each run; a contaminated
baseline presented as clean is worse than none.

When the loop is done, the numbers go into the commit body and the
workspace is deleted. A `<name>-workspace/` left behind is gitignored
but not invisible: the next session's executors and graders can read
last time's transcripts and verdicts from it, and a comparison made
with that in reach is no longer blind. The commit body is the record;
the workspace is scaffolding.
