# Collecting candidates

A candidate is a kind of mistake, not a commit: "a skill reference broke
after a rename" is one kind whether it was a hidden skill or a moved one.
Group the evidence by kind, then count. Read the commit bodies, not only the
subjects; a `fix:` subject often hides which mistake it fixed.

## Sources

Run each from the repository root. A range is the whole history unless the
user names one; on a long history, start from the last commit that carries
a `Prevents:` trailer.

- **Revert and fix commits.** What was undone or repaired, and why.

  ```bash
  git log --format='%h %s' | grep -E '^[0-9a-f]+ (Revert|revert|fix)(\(|:| )'
  git log --format='%h %(trailers:key=Prevents,valueonly,separator=%x20)' | awk 'NF > 1'
  ```

  The second command lists what is already closed; a kind whose incidents
  are all there is not a candidate.

- **Review comments.** What a reviewer had to say more than once.

  ```bash
  gh api 'repos/{owner}/{repo}/pulls/comments?per_page=100' --paginate --jq '.[] | .created_at[:10] + " " + .path + ": " + (.body | split("\n")[0])'
  ```

- **Lint suppressions and markers that silence tests**, added rather than
  present: each one is a place the agent chose to get past a check.

  ```bash
  git log -p --format='commit %h' -G'nolint|revive:disable|eslint-disable|oxlint-disable|@ts-expect-error|@ts-ignore|#\[allow|deadnix: skip|t\.Skip|\.skip\(|xit\(|#\[ignore|time\.Sleep|retry'
  ```

- **Auto-memory.** Each entry is a correction the user made in a session.
  `~/.claude/projects/<the repository path with / as ->/memory/*.md`, and
  `MEMORY.md` beside them as the index.

- **Rules written as prose.** `AGENTS.md`, `CLAUDE.md` and skill lines that
  say "never" or "always": each is a candidate for pruning when a check
  already enforces it, and its history (`git log -L` on the line) can be
  evidence that it was written after a repeat.

## Counting

- Two or more pieces of evidence for one kind make a candidate. One makes it
  Watching; say what the second piece would look like.
- Evidence must be dated and checkable: a hash, a PR comment, a memory file.
  A recollection is not evidence.
- For each candidate, say whether a script can see the trigger: a path, a
  line in the diff, a command line. Only those go to lint, hook or deny.
- Propose the level from the order in the skill's step 4 and name the file
  the check would live in.
