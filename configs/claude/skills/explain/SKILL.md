---
name: explain
description: Structure rules for explanatory text a human will read — a PR body, an issue body, or the report given to the user after a task. Load it when drafting one of those, and whenever the pull-request or issue skill says to. Not for ordinary conversation. Covers one bullet, one claim (nesting vs. headings).
---

# Explaining to a human reader

The reader has less context than you and less patience. Structure tells them
what to skim and what to read; structure used wrongly lies to them.

## One bullet, one claim

A bullet that needs a colon to carry its content is a subsection wearing a
bullet's clothes. `- 問い方が増えた: <続けて数行ぶんの中身>` reads as a single
list item but holds a section's worth of text, and the colon papers over the
fact that the structure is wrong. Match the structure to the content instead:

- one claim → one bullet, no colon
- a claim plus supporting detail → nest the detail as indented sub-bullets
- more than a couple of lines → promote it to a `###` heading

A colon is fine when what follows fits on the same line — `**役割**: 説明` is
a label, not a smuggled section.

The rule is about the shape, not the character. `**見出し** — <数行ぶんの中身>`
is the same violation with the colon swapped for a dash, and so is a bullet
that avoids the `。` by chaining clauses with `、`. If the content would not
fit on the label's line with a colon, no other separator makes it fit; nest
it or promote it.

## PR and issue bodies

The full catalogue of GitHub constructs — when a table beats bullets, what
goes in `<details>`, how many siblings a list can hold — is
`pull-request/references/markdown.md`. Read it before writing a body longer
than a few lines. The diagram gate lives in the `pull-request` skill.
