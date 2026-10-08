---
name: skill-authoring
description: House rules and pre-flight for creating or changing a skill (a SKILL.md that Claude Code and codex both load) — check what each agent's spec and vendor repos say today, cut the skill by job so other workflows can load it, validate the frontmatter with the bundled checker, hand drafting and testing to skill-creator, and redraw the skill map in configs/agents/README.md.
when_to_use: Whenever the user asks to create, add, change, split, rename, or review a skill — "skill 作って", "skill 直して", "skill 追加して", "この作業を skill にして", "SKILL.md を書いて", "skill の図を更新して" — and before editing any file under configs/agents/skills or loading skill-creator for any reason. Also when a skill-creator script rejects a frontmatter field, or when a skill needs a frontmatter option and it is unclear whether one exists.
---

# Skill authoring

The skill spec changes monthly and the tooling lags it. On the day this
skill was written, skill-creator's bundled validator rejected
`disallowed-tools` and `when_to_use` — both documented fields — because
its allowed list was frozen at the six Agent Skills fields. So the order
of work is fixed: read what is true today, shape the skill, validate it
against the live spec, and only then draft and test with skill-creator.

## 1. Read what is true today

Fetch the spec, not memory, for every agent that loads the skill: today
Claude Code (`~/.claude/skills`) and codex (`~/.agents/skills`), from the
one source tree. Three sources, in this order:

- **The frontmatter references:** Claude Code's
  `https://code.claude.com/docs/en/skills.md` (the `.md` URL returns
  markdown; read the `Frontmatter reference` table) and codex's
  `https://learn.chatgpt.com/docs/build-skills.md`. A field may already
  do what the skill was about to do in prose — `paths` for file-scoped
  activation, `context: fork` for isolation, `user-invocable: false` for
  background knowledge, `hooks` for something that must run every time.
  codex reads only `name` and `description`; what it must enforce goes in
  the `agents/openai.yaml` sidecar (`policy.allow_implicit_invocation`)
  or in the body.
- **The changelogs:** `https://code.claude.com/docs/en/changelog.md` and
  `gh api 'repos/openai/codex/releases?per_page=20' --jq '.[] | select(.prerelease | not) | .tag_name + " " + .body'`.
  Read the entries since the skill directory's last commit
  (`git log -1 --format=%ad -- configs/agents/skills`) for "skill",
  "command", "frontmatter", "hook", "plugin". Note anything that changes
  how skills load or trigger.
- **The vendors' repos:** an official skill that covers the job is a
  reason to install it, not to write one.

  ```bash
  gh api repos/anthropics/skills/contents/skills --jq '.[].name'
  gh api repos/anthropics/claude-plugins-official/contents/plugins --jq '.[].name'
  gh api repos/openai/skills/contents/skills/.curated --jq '.[].name'
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
  either of them carrying the rewrite procedure, and the judgement hands
  over to the action by name.
- **A rule two skills share is a third skill.** `explain` holds the
  bullet-structure rule that `pull-request` and `issue` both load. Copying
  it into both is how the copies drift.
- **The frontmatter says who may start it.** Something that cannot be
  taken back from this machine — a tag, a ruleset, anything published:
  `disable-model-invocation: true`. A local rewrite that `git reflog`
  undoes is not that; `reconstruct` runs on its own because nothing
  leaves the machine until the user pushes. That hides the skill
  from the model completely — description and all — so the skill that
  decides has to hand the user `/name` to type. Background knowledge
  nobody would type as a command: `user-invocable: false`. A skill that
  only reads and reports: `disallowed-tools: Edit, Write, NotebookEdit`.
  Trigger phrases: `when_to_use`, which the listing appends to
  `description` under one shared 1,536-character cap. codex ignores
  `when_to_use` and lists every skill's `description` under one budget of
  2% of the context window (8,000 characters when unknown), so a longer
  description costs every other skill room there.

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

## 5. Redraw the skill map

`configs/agents/README.md` maps every skill in three mermaid flowcharts —
実装から PR まで, 打って使う skill, skill を作る時 — plus a list of the
skills nothing loads. It is the only place the whole graph is visible,
so it is redrawn in the same commit as any skill change that adds,
removes or moves a node or an edge; a map that lags one commit is a map
nobody trusts.

Derive it from the files, not from memory of the last version:

- **Diagram from the frontmatter.** A skill with
  `disable-model-invocation: true` goes in 打って使う skill with an edge
  from `user`. Every other skill goes in the diagram of the work that
  loads it; one that nothing loads and that loads nothing goes in the
  list under the diagrams. A node from another diagram is repeated by
  its bare name, without the phrase.
  ```bash
  grep -l '^disable-model-invocation: true' configs/agents/skills/*/SKILL.md
  ```
- **Edges from the bodies.** Every reference that makes a skill load
  another — "load the `<name>` skill", "via the `<name>` skill", "hand
  over to", "hand the user `/name`" — is an edge: solid (`-->`) when it
  loads it at that step every time, dotted (`-.->`) when only under a
  condition. A reference that only points ("that is the `pull-request`
  skill's question") is not an edge. The label says when, in Japanese,
  the way the existing labels do; a hand-off to a hidden skill is
  labelled "/name を案内", since the user has to type it.
  ```bash
  grep -n -E '`[a-z-]+` skill|`/[a-z-]+`' configs/agents/skills/*/SKILL.md
  ```
- **Tools** a skill calls (`agent-browser`, `lint-body`) are
  parallelogram nodes, `id[/"name<br/>phrase"/]`. Tools no skill calls
  (`rtk`, `ck`, `codegraph`) stay in the prose, not in a diagram.
- **Node text.** `id["name<br/>one short Japanese phrase"]`, the phrase
  saying what the skill returns or does, not how.

Then reread the prose above the diagrams: when a skill moved between
the two kinds, a sentence that names it may no longer be true. Render
every block before committing and look at the images — a syntax error
leaves GitHub showing raw text, and a diagram whose edges cross into a
knot is a reason to split it, not to ship it. mermaid-cli finds no
Chrome of its own under nix, so point it at the one agent-browser
downloaded:

````bash
awk '/```mermaid/{f=1;n++;next}/```/{f=0;next}f{print > ("<scratch>/m" n ".mmd")}' configs/agents/README.md
export PUPPETEER_EXECUTABLE_PATH="$(find ~/.agent-browser/browsers -type f -perm +111 -name 'Google Chrome for Testing' | head -1)"
for m in <scratch>/m*.mmd; do nix run nixpkgs#mermaid-cli -- -i "$m" -o "${m%.mmd}.png" -w 1400; done
````
