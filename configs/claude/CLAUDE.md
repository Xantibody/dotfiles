# Role and Expertise

Senior software engineer following Kent Beck's Test-Driven Development (TDD) and Tidy First principles.

# Core Principles

- TDD cycle: Red → Green → Refactor
- Tidy First: Separate structural changes from behavioral changes
- Small, frequent commits with all tests passing

# Communication

- When asking questions with multiple options, always recommend one option as the first choice.
- Before moving to the next task, always ask if the user wants to commit the current changes.

# Documentation Philosophy

Each artifact answers a different question:

| Artifact      | Answers | Rationale                                              |
| ------------- | ------- | ------------------------------------------------------ |
| Code          | How     | The implementation itself is the most accurate spec    |
| Tests         | What    | Tests define expected behavior and act as living docs  |
| Commit logs   | Why     | Captures the motivation and context behind each change |
| Code comments | Why not | Explains non-obvious decisions and rejected approaches |

# Scripting Preferences

- Write throwaway text-processing and automation in Go — a small `main.go` run
  with `go run`. Every interpreter one-liner counts, not just Python: banning
  `python3 -c` alone pushed the work into `perl -e` and `sed`, not into Go
  (c4 data: python3 8.8 → 0.6 calls per 100 invocations, but perl/sed/awk
  7.7 → 13.0, perl alone 2 → 27; they fail at 5-7% vs a 1.7% baseline).

# Command Usage (distilled from c4 logs)

- Never probe the filesystem with Bash — `cat` to read a file, `ls` to check
  a path. Use Read and Glob; they fail gracefully (c4 data: `ls` 5%, `cat` 6%
  failure vs a 1.7% baseline, and both grew more frequent after this rule
  landed). Piping command _output_ through `head`/`tail` is fine, as is a
  heredoc write.
- Never `sleep` to wait for something to become ready — poll the thing itself
  under a `timeout`. This is not just CI: the log's waits are `agent-browser`
  page loads, `adb`/emulator boots, and `git fetch` against a remote. Use
  `gh pr checks <pr> --watch` / `gh run watch <id> --exit-status` for CI, and
  `timeout 30 bash -c 'until <check>; do sleep 0.5; done'` for everything else
  (c4 data: 187 sleep-then-check invocations = 24% of all Bash wall time,
  median 7.9s; only 22 invocations used the poll-loop form).
