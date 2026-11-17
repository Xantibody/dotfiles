---
name: guardrail
description: Turns an agent's repeated mistakes into checks that stop them — collects candidates from revert and fix commits, review comments, lint suppressions, markers that silence tests and auto-memory, closes the ones the user picks at the strongest level that holds (design, type, lint / hook / deny, test, prose) with the check warning before it fails, and prunes checks and rules that no longer earn their place. Its Goal is what the goal-review skill measures.
when_to_use: When the user wants a mistake to stop recurring, a correction turned into a check, or the rules pruned — "同じミスを繰り返さないようにして", "この失敗を check にして", "ガードレール足して", "訂正を仕組みにして", "AGENTS.md 刈り込んで", "memory 整理して" — and when goal-review is asked against this skill's Goal ("ガードレール見て", "plan の移し忘れない?").
---

# Guardrail

A correction typed into a session stops one session. A sentence added to
AGENTS.md stops the sessions that read it and remember it. A check stops
every session, whichever agent runs it, because it runs whether or not
anyone remembers. This skill turns a mistake that keeps happening into a
check, and removes checks and rules that have stopped paying for
themselves. It does not decide which mistakes matter: it finds the
candidates, the user picks, and it closes what was picked.

Two limits keep it from overreacting. A mistake is a candidate only once it
has happened at least twice; one correction is noted and watched, not
closed. And a mistake becomes a lint, a hook or a deny only when the diff or
the command shows it — a trigger a script can read. A judgement error with
no such trigger goes to prose or to a skill's Goal, never to a check that
would fire on guesses.

## Goal

**Target.** The repository at the working directory together with what the
agents read for it: `AGENTS.md` (and `CLAUDE.md` where it is a copy), the
Claude Code settings and hooks, codex's hooks and rules, `REVIEW.md`, the
auto-memory directory for this repository
(`~/.claude/projects/<path with / as ->/memory/`), and `.ai/plans/`. `.ai/`
is gitignored and the memory lives outside the repository, so CI sees
neither; this Goal is judged on the machine where the work happens.

**Items.**

| #   | Item             | Holds when                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| --- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Repeats closed   | every kind of mistake with two or more pieces of evidence, collected as `references/candidates.md` says, has a check that names one of its incidents in a `Prevents:` trailer (item 4) or is a Goal item of a skill. A kind the user declined in this conversation is listed as declined and does not count                                                                                                                                                                                    |
| 2   | Checks fire      | for each commit with a `Prevents:` trailer, the check it added reports the incident when run against the incident commit's tree and reports nothing on `HEAD`: a test that runs both (extracting the incident tree with `git archive`, as the skill validator's `TestSkillReferenceIncidents` does) and passes now, or the commands and output for both runs in the commit body. `n/a` for a closure that is itself a Goal item, which item 5 and its peers judge                              |
| 3   | Nothing to prune | none of: a check whose trigger matches nothing in the tree any more (a `REVIEW.md` path that no file matches, a deny for a command no host installs, a test of code that is gone); an `AGENTS.md` line whose rule both agents already enforce (a `permissions.deny` or hook in Claude's settings and a rule or hook in codex's), unless the line says what to do instead and neither enforcement's message does; an auto-memory entry whose rule is already in `AGENTS.md`, a skill or a check |
| 4   | Trailer          | every commit that closes a candidate carries `Prevents: <incident hash>`, one line per incident, in its trailer block: `git log --format='%h %(trailers:key=Prevents,valueonly,separator=%x20)'` lists it with at least one hash, and each hash is a commit (`git cat-file -e <hash>^{commit}`)                                                                                                                                                                                                |
| 5   | Plans moved      | no file directly under `.ai/plans/` belongs in `.ai/plans/done/`: for each one, every issue it names (`#N` or an issues URL) is still open (`gh issue view N --json state`), and no commit names the file (`git log --all --oneline --grep=<file name>`). `n/a` when `.ai/plans/` does not exist                                                                                                                                                                                               |

Item 5 is here because the move was forgotten twice (the plans behind
67bbf7b and 3542501) and `.ai/` is out of CI's reach, so a Goal item judged
where the plans live is the strongest check that can hold it.

**Verdict.**

```markdown
**Verdict:** closed | open

| #   | Item | State | Evidence |
| --- | ---- | ----- | -------- |

**Candidates:** <kind — evidence hashes — proposed level>, one per line
**Watching:** <kinds with one piece of evidence>
```

State is `holds`, `fails`, `n/a` or `unknown` (with why). The verdict is
**closed** only when every row is `holds` or `n/a`. Evidence is the command
and the lines of output that decided the row.

**Hand-over.** When the user asked to close mistakes or prune rules and the
verdict is **open**, load this skill with the table. When they or another
skill only asked for the state, stop at the table.

## Procedure

1. Load the `goal-review` skill against this skill's Goal, unless its table
   is already in the conversation, and show the table before changing
   anything.
2. Collect the candidates as `references/candidates.md` says and show them
   as a table — the kind of mistake, its evidence (hashes, PR comments,
   memory files), and the level you would close it at. Kinds with one
   piece of evidence go under Watching, not in the table.
3. Ask which to close and which to prune. Close only what the user picked;
   a kind they decline is named in the report as declined, with their
   reason when they gave one.
4. Close each picked kind at the strongest level that can hold it, trying
   them in this order and stopping at the first that works:
   1. **Design** — make the mistake impossible to write: remove the API, the
      shadowing `with`, the second way to do it.
   2. **Type** — make it fail to compile.
   3. **Lint, hook or deny** — a lint rule or recipe that reads the diff (the
      `baseline` skill's references hold the per-stack shapes), a PreToolUse
      hook, or a `permissions.deny`. For an agent rule, enforce it in both
      agents — Claude's settings and codex's hooks or rules — or the
      `AGENTS.md` line stays; 251f561 is the precedent.
   4. **Test** — a test that fails on the incident's tree and passes on
      `HEAD`.
   5. **Checklist row** — a `REVIEW.md` row when the check needs a person
      but the trigger is a path or a diff regex; load the
      `reliability-checklist` skill and write it as its Write a row says.
   6. **Goal item** — for state CI cannot see, such as `.ai/`.
   7. **Prose** — `AGENTS.md` or a skill line, only for what needs judgement.

   A new check goes in as a warning: a hook's `additionalContext`, an
   `ask` instead of a `deny`, a lint that prints and exits 0. Make it fail
   in a later commit, once it has run on real changes without a false
   alarm, and say in that commit how many runs it saw. Before committing,
   run the check against the incident commit (it must report) and against
   `HEAD` (it must not), and pin both as a test where the check is code.
   Commit each closure through the `commit` skill, with one `Prevents:
   <incident hash>` line per incident in the trailer block.

5. Prune what the user picked, one commit per item, with the body saying
   which kind it was (never fires, enforced by both agents, promoted). A
   memory entry lives outside the repository: delete its file and its
   `MEMORY.md` line only on the user's yes, and say so in the report.
6. Load the `goal-review` skill against this skill's Goal again and end with
   its table.

## Evals

`evals/evals.json` gives each eval a `split`. Work on the skill against the
`tune` evals only. When the work stops, run the `holdout` evals once and
report their numbers in the commit body; a holdout failure is not fixed by
editing the skill against it — that eval moves to `tune` and a new holdout
case is written from history the skill has not seen.
