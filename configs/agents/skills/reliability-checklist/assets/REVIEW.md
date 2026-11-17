# REVIEW.md

Checks a change calls up by what it touches. The reliability-checklist
skill reads this table from the base branch and prints the rows a diff
hits; each row comes from an incident, named by the commit whose body
tells what broke.

- **Trigger:** one or more backticked patterns, any of which fires the
  row. A path glob matches the whole repo-relative path (`*` and `?`
  within one directory, `**` across them); `/regex/` matches an added or
  removed diff line (RE2, `|` written as `\|`).
- **Check:** what to look at in the change, specific enough to answer
  yes or no.
- **Incident:** the commit whose body explains the failure; a row
  nobody can trace back is a row nobody can prune.

| Trigger        | Check                                                    | Incident  |
| -------------- | -------------------------------------------------------- | --------- |
| `path/to/file` | What to confirm about the change before calling it done. | `abc1234` |
