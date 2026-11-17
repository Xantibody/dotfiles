# Docs and ADRs (steps 5-6)

Step 5 gives the repo a map (`docs/architecture.md`). Step 6 gives it a place
for decisions (`docs/adr/` and its template). Both describe what steps 1-4 put
in place, so run them after those steps and fill them from what the repo has,
not from this file's examples. No record is written in advance: an ADR exists
because a decision was made, not because the directory was created.

## Survey

Look for each of these before writing anything. A hit means absorb, not replace.

| Looking for      | Paths to check                                                                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Architecture map | `docs/architecture.md`, `ARCHITECTURE.md`, `docs/introduction.md`, `doc/`, an "Architecture" README heading                                             |
| ADR directory    | `.adr-dir` (its content is the path), `docs/adr/`, `doc/adr/`, `docs/decisions/`, `doc/architecture/decisions/`, `adr/`                                 |
| ADR template     | `<adr dir>/template.md`, `<adr dir>/templates/template.md`, `<adr dir>/adr-template.md`                                                                 |
| ADR format       | `## Considered Options` / `## Decision Outcome` headings (front matter `status:` is optional) mean MADR; a `## Status` heading means Nygard / adr-tools |

Step 5 is done when a map exists that has a codemap and a rules section listing
the checks from step 3. Step 6 is done when an ADR directory exists with a
template. Skip a step that is done.

Absorbing:

- An existing map keeps its path. Add only the missing sections (Rules, the link
  to the ADR directory) from `assets/architecture.md`. Do not create a second map.
- An existing ADR directory keeps its path, its format and its numbers. Put the
  template next to the records it already has; when it uses MADR, keep MADR and
  copy only the `Enforced by` section from `assets/adr-template.md` into its
  template. Never renumber or reformat existing records.
- Records that already cover a decision below are not written again; continue
  numbering from the highest number present.

## Language

Prose follows the repository's language: the README and the last twenty commit
subjects decide (`git log -20 --format=%s`). ADR headings stay as the template
writes them, because grep and adr-tools key on `## Status`; everything under
them is in the repo's language. File names stay lowercase ASCII.

## The map: `docs/architecture.md`

Copy `assets/architecture.md` and fill it from the code:

- **Overview**: from the README and the entry points.
- **Codemap**: the top-level source directories and deployables. Use codegraph
  (or the language's module graph) to find which depend on which; draw only the
  arrows that are a boundary someone might cross by mistake.
- **Rules**: one row per dependency or structure rule that step 3's lint config
  enforces (import restrictions, forbidden packages, the suppression policy),
  with the tool and rule name and the instruction its error message gives. A
  rule the team follows but nothing checks is a row marked `prose only`.
- **Decisions**: link `adr/`. Do not restate an ADR's reasoning here.

Delete a section that would be empty rather than leaving a placeholder.

## ADR conventions

- **Location**: `docs/adr/` unless the survey found another. Name the template
  `docs/adr/template.md`. For adr-tools users: a `.adr-dir` containing `docs/adr`
  points `adr new` at the directory (its default is `doc/adr`), and since it
  looks for a template only at `<adr dir>/templates/template.md`, export
  `ADR_TEMPLATE=docs/adr/template.md` (in `.envrc`). It substitutes `NUMBER`,
  `TITLE`, `DATE`, and `STATUS`, the last always with `Accepted`, so edit a
  Proposed record after `adr new`. Its sed replaces the first match on every
  line, so keep those uppercase words out of the template's comments. Do not add
  adr-tools to the devShell unless the repo already uses it.
- **File name**: `NNNN-kebab-title.md`. `NNNN` is four digits, zero-padded, one
  more than the highest number in the directory (count rejected and superseded
  records too). Numbers are never reused. The title is an imperative verb phrase
  in lowercase ASCII: `0004-use-postgresql-for-job-state.md`.
- **Heading**: `# <N>. <Title>`, with the unpadded number, the way adr-tools writes it.
- **Date**: ISO `YYYY-MM-DD`, the day the record was written. Superseding does
  not change it (adr-tools sets it once, from `date +%Y-%m-%d` or `ADR_DATE`).
- **Status**: `Proposed` (open for review), `Accepted`, `Rejected` (kept so the
  option is not proposed again unknowingly), `Deprecated` (no longer applies,
  nothing replaces it), `Superseded by [<N>. <Title>](<file>)`.
- **One decision per record.** If the Decision section needs "and", split it.
- **Immutable once accepted.** The only edits to an accepted record are its
  Status line, a link to a later record, and typo fixes. A changed mind is a new
  record.
- **No index file.** The directory listing is the index; an index page goes stale.
- **Referencing**: from code or a commit body, cite the path
  (`docs/adr/0004-use-postgresql-for-job-state.md`) so a grep hit opens it.

Number collisions between branches: when two branches both add `0007`, the one
merged second renames its file and heading to the next free number before merge.
Put that check where it cannot be skipped: add an ADR check to `just check` (see
below) rather than relying on this paragraph.

Set `dir` to the surveyed ADR directory, and add any non-record files it
already holds (MADR's `adr-template.md`, a `README.md`) to the allowed names.
UNVERIFIED: the recipe has not been run.

```just
# ADR files are named NNNN-kebab-title.md and each number is used once
check-adr:
    #!/usr/bin/env bash
    set -euo pipefail
    dir=docs/adr
    test -d "$dir" || { echo "$dir: missing; create it with template.md" >&2; exit 1; }
    bad=$(ls "$dir" | grep -Ev '^([0-9]{4}-[a-z0-9-]+\.md|template\.md|templates)$' || true)
    if [ -n "$bad" ]; then
        echo "$dir: rename $bad to NNNN-kebab-title.md (lowercase ASCII, next free number)" >&2
        exit 1
    fi
    dup=$(ls "$dir" | grep -Eo '^[0-9]{4}' | sort | uniq -d || true)
    if [ -n "$dup" ]; then
        echo "$dir: number $dup is used twice; give the newer record the next free number" >&2
        exit 1
    fi
```

## Records baseline itself writes

None by default. Creating the directory and the template decides nothing, and a
record of a default that nobody weighed against anything has no Context worth
reading. baseline writes a record only for a choice it actually made in this
repo between real alternatives — kept ESLint instead of moving to oxlint, chose
a ratchet over a mass fix, kept a second formatter because its plugins live in
`node_modules` — and only under the rules below. Such a record goes in the
commit of the step that made the choice, not in step 6.

## When to write a new record

An agent writes an ADR, in the same commit as the change, when the change:

- moves a boundary: adds, removes or merges a top-level module, a port or an
  adapter, or changes which way a dependency points;
- changes the toolchain: adds, replaces or removes a formatter, linter, type
  checker, test runner, build tool or CI provider, or relaxes a strict setting;
- adds a dependency that is costly to remove: a framework, a datastore, an
  external service, a code generator;
- adds a new class of allowed suppression or exempts a path from a rule.

It does not write one for a choice local to one file, a reversible default, a
single suppression (that is a `HACK(<issue URL>)` anchor), or a temporary
workaround. If unsure, ask: would a later agent, not knowing the reason, undo
it? Then record it. When the rule is checkable, add the check in the same
commit and fill `Enforced by`; when the change alters a row in the map's Rules
table or Codemap, update `docs/architecture.md` in the same commit.

A decision the user has not made yet is written as `Proposed` and the question
is put to the user; it becomes `Accepted` or `Rejected` when they answer.

## Superseding

1. Write the new record with the next number. Under `## Status` put `Accepted`
   and a line `Supersedes [<N>. <Title>](<old file>)`. Its Context says what
   changed since the old decision.
2. In the old record, replace the status with `Superseded by [<N>. <Title>](<new file>)`.
   Change nothing else in it.
3. Update the rows in `docs/architecture.md` that cite the old record.
4. Commit all three together.

A decision that simply stops applying gets `Deprecated` and a one-line reason in
its Status section, with no new record. adr-tools' `adr new -s <N> <title>` does
steps 1-2 (it also deletes the old record's `Accepted` line) but writes
"Superceded by"; correct the spelling.

## Commits

Two commits, matching the steps:

- step 5: `docs: add architecture map` (`docs/architecture.md`)
- step 6: `docs(adr): add the decision record template` (the template and the
  `check-adr` recipe if `just check` gained it)

Use the repo's language and its own scope conventions for the subject.

## Sources

- Michael Nygard, Documenting Architecture Decisions (2011):
  https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions
- adr-tools template, numbering (`printf "%04d"`), `ADR_TEMPLATE`, `.adr-dir`
  and supersede links (last push 2024-04-25, latest tag 3.0.0; nixpkgs
  `pkgs/by-name/ad/adr-tools`):
  https://github.com/npryce/adr-tools/blob/master/src/adr-new,
  https://github.com/npryce/adr-tools/blob/master/src/_adr_dir,
  https://github.com/npryce/adr-tools/blob/master/src/_adr_add_link
- MADR 4.0.0 (released 2024-09-17, still the latest), `NNNN-title-with-dashes.md`,
  default directory `docs/decisions`, optional front matter `status`:
  https://adr.github.io/madr/ and https://github.com/adr/madr/tree/4.0.0/template
- Joel Parker Henderson, ADR guidance (one decision per record, do not alter,
  when not to write one): https://github.com/joelparkerhenderson/architecture-decision-record
- matklad, ARCHITECTURE.md (codemap, invariants as absences, name but do not link):
  https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html
