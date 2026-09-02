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

# Git Workflow

- `git push` is deny-listed on purpose — don't chain it after `git commit`,
  and treat a push denial as the handoff, not an error: commit, report, and
  let the user push. They ask for a PR after pushing.

# Repository Conventions

- Nearly every repository has a `/sample` directory: implementation plans
  and saved HTML of reference sites live there. Read it before starting
  work; save new reference material there. It is always
  gitignored — add it to `.gitignore` if missing.
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
