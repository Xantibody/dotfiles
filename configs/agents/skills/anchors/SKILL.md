---
name: anchors
description: The rules for writing anchor comments — HACK(<issue URL>) workarounds and AIDEV-NOTE decisions — and the audit that lists them and reports which HACKs reference an issue that has since closed. Read-only; it never edits the anchors.
when_to_use: At the start of a session in a repository, before touching code that might carry a workaround, and whenever the user asks what hacks or notes are lying around — "HACK 一覧", "回避策どれが消せる?", "アンカー見せて", "AIDEV-NOTE 一覧", "issue 閉じたやつある?".
disallowed-tools: Edit, Write, NotebookEdit
---

# Anchors

Two grep-able comment shapes carry the "why not" of a decision, so a
later session finds it with `rg` instead of re-deriving it:

- `HACK(<issue URL>): <what is broken upstream; what to remove once it is fixed>`
  — a workaround that should disappear. The reference is a full issue
  URL: it opens from a grep hit and can point at another repository. No
  upstream issue yet means file one first; a HACK with nothing to wait
  for is an AIDEV-NOTE.
- `AIDEV-NOTE: <the decision and the rejected alternative>` — a
  non-obvious choice that stays. One line, under 120 characters.

Rules (the AIDEV-NOTE convention's, adopted as is):

- Update an anchor when the code under it changes. Never delete one
  without an explicit instruction, except a HACK whose issue has closed
  and whose workaround leaves in the same change.
- A bare `TODO` with no reference is not a third kind of anchor — file it
  with the `issue` skill instead.

The rest of this skill is the audit: it finds every anchor and asks
GitHub whether the HACKs are still needed.

## Run

```bash
go run ~/.claude/skills/anchors/scripts/audit/main.go [-offline] [<dir>]
```

The script walks the files git tracks or would track (so `.gitignore`
applies), prints one line per anchor, and for every HACK whose reference
is a GitHub issue or pull-request URL, `owner/repo#N`, or `#N` in the
current repository, asks `gh` for its state. It exits 1 when any
referenced issue is closed. `-offline` skips the `gh` calls.

Output columns: `path:line`, kind, state, reference, text. States:

| State       | Meaning                                                       |
| ----------- | ------------------------------------------------------------- |
| `open`      | still waiting — leave the workaround in place                 |
| `closed`    | the upstream fix landed — the workaround is a candidate       |
| `unchecked` | the reference is not a GitHub issue, or `gh` could not answer |

## Report

- Lead with the closed ones, each as "remove <workaround> at <path:line>
  once <what the anchor says to do>". A closed issue is a candidate, not a
  verdict: the fix has to be in the version the repository actually uses,
  so say what to verify before deleting.
- Treat `unchecked` as unknown, never as open — a `gh` auth or network
  failure must not read as "still needed".
- A HACK with no reference or a reference the script cannot parse is a
  rule violation; list it separately so it can be fixed into the
  documented shape.
- If nothing is closed, say so in one line and list the anchors; the
  list is the point when this runs at the start of a session.

Removing a workaround is an edit, which this skill cannot make. Hand the
candidates to the `implement` skill, one commit per removed HACK, so the
history says which upstream fix unblocked each one.
