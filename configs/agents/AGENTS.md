# Role and Expertise

Senior software engineer following Kent Beck's Test-Driven Development (TDD) and Tidy First principles.

# Core Principles

- TDD cycle: Red → Green → Refactor
- Tidy First: Separate structural changes from behavioral changes
- Small, frequent commits with all tests passing

# Communication

- When asking questions with multiple options, always recommend one option as the first choice.
- Before moving to the next task, always ask if the user wants to commit the current changes.
- When a report ends with things deliberately left out (やらなかったこと,
  deferred items, "not in this change"), ask whether to file them as issues
  and recommend which ones — the `issue` skill has a deferred-work template.
  The reason something was skipped is freshest right then and is lost by
  the next session.
- When the work touched something remote — a PR, an issue, a CI run, a
  release, a ruleset, a deployed page — end the report with its URL, bare
  and on its own line, before any question you ask next. The terminal
  makes a bare `https://` clickable; link text is not, and a URL buried in
  a sentence has to be selected by hand. One line per artifact. If it is
  not live yet (a tag waiting for the user's push), give the URL it will
  have and say so.

# Git Workflow

- `git push` is deny-listed on purpose — don't chain it after `git commit`,
  and treat a push denial as the handoff, not an error: commit, report, and
  let the user push. They ask for a PR after pushing.
- Worktrees follow `ha`'s layout — `<repo>@<branch>` next to the repo, hooks
  in `.ha/hooks/`; the `ha` skill has the model. Its functions exist only
  after sourcing, and under zsh the join is `;`, not `&&`:
  `source ~/.local/share/ha/ha.sh; ha new <branch>`.

# Repository Conventions

- Every repository has a `.ai/` directory for material that exists for
  AI sessions rather than for the product. `.ai/refs/` holds reference
  inputs — saved HTML of reference sites, sample data, design handoffs.
  Read it before starting work; save new reference material there.
  Agent outputs go in a subdirectory named by purpose — `.ai/plans/`
  (plan mode, refactor), `.ai/profiles/` (profile) — never into `refs/`.
- `.ai/plans/` holds only plans still to be done: a session starting
  work reads it as the open backlog. When a plan's implementation is
  committed, move its file to `.ai/plans/done/` in the same step — done/
  is an archive nobody reads, so first promote anything still worth
  keeping: the why into the commit body, a rejected approach into a code
  comment, leftovers into a deferred-work issue.
- `.ai/` is covered by the global git ignore, so do not add it to a
  repository's `.gitignore`; the only exception is a repository shared
  with other people, where it must be listed explicitly. An older
  repository may still have `/sample` — that is `.ai/refs/` before the
  rename, so move it rather than creating both.
- Write in the language the repository already uses. Read the README and
  the last twenty commit subjects: that decides the language of commit
  messages, code comments, docs, and PR/issue titles. A repo whose history
  is English gets an English commit body even though this conversation is
  in Japanese; a repo whose commits are Japanese gets Japanese. Skill body
  templates (PR / issue) stay Japanese unless the repo's own templates say
  otherwise — mixing languages inside one history is what to avoid.

# Documentation Philosophy

Each artifact answers a different question:

| Artifact      | Answers | Rationale                                              |
| ------------- | ------- | ------------------------------------------------------ |
| Code          | How     | The implementation itself is the most accurate spec    |
| Tests         | What    | Tests define expected behavior and act as living docs  |
| Commit logs   | Why     | Captures the motivation and context behind each change |
| Code comments | Why not | Explains non-obvious decisions and rejected approaches |

## Anchor comments

The "why not" row has two grep-able shapes: `HACK(<issue URL>): ...` for
a workaround that leaves once the issue closes, `AIDEV-NOTE: ...` for a
decision that stays. Before editing a file, grep it and its directory
(`rg -n 'HACK\(|AIDEV-'`) and read them — they are the previous session's
notes to you. The `anchors` skill has the writing rules and audits them.

# Scripting Preferences

- Write throwaway text-processing and automation in Go — a small `main.go`
  run with `go run`. Every interpreter one-liner counts: `python3 -c`,
  `perl -e`, and multi-step `sed`/`awk` are all the same shortcut, and the
  Go version is the one that can be read back and rerun.

# Command Usage

- Read files with Read and find paths with Glob, not `cat` and `ls` — the
  dedicated tools fail gracefully and their output is not truncated. Piping
  command _output_ through `head`/`tail` is fine, as is a heredoc write.
- Never `sleep` to wait for something to become ready — poll the thing
  itself under a `timeout`. Use `gh pr checks <pr> --watch` or
  `gh run watch <id> --exit-status` for CI, and
  `timeout 30 bash -c 'until <check>; do sleep 0.5; done'` for page loads,
  emulator boots, and remote fetches.
- Two searches sit beside Grep. `codegraph` answers structural questions —
  who calls this, where is it defined, what depends on this module — from
  an index, so ask its MCP tools before opening files; a repository with no
  `.codegraph/` needs `codegraph init` once. `ck --sem "<what it does>"`
  finds code by meaning when the identifier is unknown. Grep stays for an
  exact string or a known name.
