# Checks every repository gets

Whatever the stack, three checks run in `just check` next to the stack's own
lint. Each section says what the check is for first; the configuration under
it is an example of one repository's answer, not a value to copy. Keep the
purpose, then fit the settings to the repository in front of you.

## Workflow security: zizmor

**Purpose.** CI is code that runs with the repository's secrets and write
token, and it is the code nobody reviews as code. Two mistakes in it are both
easy to make and costly: a `${{ }}` expression spliced into a `run:` script,
which lets a branch name or PR title run commands (template injection), and a
`uses:` that follows a moving ref, which hands the job to whoever controls
that ref. actionlint (already in treefmt) checks that a workflow is valid;
zizmor checks that it is safe. An agent that adds a workflow step copies the
nearest example, so one unsafe step spreads unless a check stops it.

**How.** Put `zizmor` in the devShell and run it from the `lint` recipe, so it
runs locally and in CI through the same `just check`:

```just
lint-actions:
    zizmor --offline .
```

`--offline` keeps the check deterministic and free of a GitHub token; the
audits that need the network (looking up whether a pinned ref is a known
version) are worth adding as a separate CI-only job only when the repository
pins by SHA.

**Exceptions.** A finding is fixed, not silenced. When a rule does not fit the
repository, change it in `.github/zizmor.yml` with the reason beside the
entry; a policy that differs from zizmor's default (pinning by version tag
instead of SHA, because Renovate already bumps the tags weekly) is a decision
and gets an ADR. Example from one repository:

```yaml
rules:
  unpinned-uses:
    config:
      policies:
        # Version tags, not SHAs: Renovate's github-actions group bumps them
        # weekly, and a SHA per line is unreviewable without a version comment.
        "*": ref-pin
```

## Spelling: typos

**Purpose.** Identifiers, comments, messages and docs are read by people and
searched by agents. A misspelled name splits one concept in two — `recieve`
and `receive` are different strings to grep, to codegraph and to the next
agent that copies one of them — and a misspelled message ships to users.
typos has a low false-positive rate, so it can fail the build rather than
merely warn.

**How.** Put `typos` in the devShell and run it over the whole tree from the
`lint` recipe:

```just
lint-spelling:
    typos
```

**Exceptions.** A real word typos does not know (a product name, a domain
term) goes into `typos.toml` with a comment saying what it is; generated and
lock files are excluded by path. Example from one repository:

```toml
[files]
extend-exclude = ["*.lock", "pnpm-lock.yaml", "*.svg"]

[default.extend-words]
# Slite is a product name
Slite = "Slite"
```

## Comments on added lines: lint-comments

**Purpose.** A comment is the cheapest way to get past a problem: instead of
removing a trap, an agent writes a note that explains it, and the note reads
like care. The house rule (the global instructions' anchors) keeps an
`AIDEV-NOTE` for a constraint from outside the code or a rejected
alternative, keeps `HACK(` for debt an issue tracks, and has no place for a
bare `TODO`. Old comments are not the problem; the line a change adds is,
because that is where the question "would a type, a lint rule or another API
remove this?" can still be answered by changing the change.

**How.** One recipe, called once per stack with that stack's line-comment
marker and file globs, from the stack's lint recipe (each stack reference
shows the call; `noglob` keeps the shell from expanding the globs before git
sees them). It reads only the lines the change adds since `LINT_BASE`, the
same base the ratchets use, so it needs no ratchet of its own:

```just
# Warn about anchors and TODOs the change adds. Warn-only: see below
lint-comments marker +globs:
    #!/usr/bin/env bash
    set -euo pipefail -o noglob
    base="${LINT_BASE:-$(git merge-base HEAD origin/{{ default_branch }})}"
    git diff -U0 "$base" -- {{ globs }} | awk -v m='{{ marker }}' '
        /^\+\+\+ / { file = substr($0, 7); next }
        !/^\+/ { next }
        { line = substr($0, 2); i = index(line, m); why = "" }
        i == 0 { next }
        { c = substr(line, i + length(m)) }
        c ~ /AIDEV-NOTE/ { why = "new AIDEV-NOTE: would a type, a lint rule or another API remove what it explains? Keep it only for a constraint from outside the code or a rejected alternative" }
        c ~ /HACK\(/ && c !~ /HACK\(https?:\/\// { why = "HACK( without an issue URL: HACK(<issue URL>): <what to remove once it is fixed>" }
        c ~ /(^|[^A-Za-z])(TODO|FIXME)([^A-Za-z]|$)/ { why = "a TODO/FIXME is not an anchor: file an issue, or write HACK(<issue URL>)" }
        why != "" { printf "warn: %s: %s\n  %s\n", file, line, why > "/dev/stderr" }'
```

`default_branch` is the Go reference's variable, set once at the top of the
justfile. The marker is matched as plain text, so a `//` inside a string
literal can start a false "comment"; that is one reason the recipe only
warns.

**Exceptions.** None yet, because it does not fail: a new check goes in as a
warning and is made to fail only once it has run on real changes without a
false alarm. When that holds, end the recipe so it exits non-zero when it
printed anything, and from then on judge step 3 on it like any other rule.
Until then a repository without it is not `partial` on step 3 for that alone.

## Dependency updates: Renovate

**Purpose.** Pinned tools only stay safe while someone moves the pins. Without
updates, `flake.lock`, the language lock files and the action versions age
until one upgrade is too large to review; with updates that arrive as small,
grouped PRs, each one is verified by the same `just check` in CI and merged
while it is small. This is why it needs step 4: an update PR nobody's CI checks
is a guess.

**How.** `assets/renovate.json5` at the repository root. The parts that hold
for every repository are in the asset: `mode: "full"` (the Mend app installed
on all repositories otherwise starts silent), the nix manager switched on so
`flake.lock` is tracked, one PR for the flake inputs and one for the actions.
Then group the stack's own dependencies so a week brings a few PRs rather
than one per package — one repository's rules, as an example:

```json5
{
  description: "Each crate separately is too many; config:recommended still splits out majors.",
  matchManagers: ["cargo"],
  matchUpdateTypes: ["minor", "patch"],
  groupName: "cargo dependencies",
},
{
  description: "Give a new npm release a day before it lands.",
  matchManagers: ["npm"],
  groupName: "npm dependencies",
  minimumReleaseAge: "1 day",
  internalChecksFilter: "strict",
},
```

A dependency that must move in step with something Nix pins (a browser
revision, a hash in a Nix derivation) is held back with `enabled: false` and a
`description` saying what to move together, rather than left to break CI
every week. Installing the Mend Renovate app on the repository is outside the
repository and is the user's to do; the report names it.
