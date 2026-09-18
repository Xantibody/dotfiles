---
name: explain
description: Structure rules for explanatory text a human will read — a PR body, an issue body, or the report given to the user after a task. Covers one bullet, one claim (nesting vs. headings). Not for ordinary conversation.
when_to_use: Load it when drafting a PR body, an issue body, or an end-of-task report, and whenever the pull-request or issue skill says to.
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

## The closing line

A report on work that touched a remote ends with the URL of what it
touched, so the reader opens it from the terminal without looking for it.
The rule itself is in CLAUDE.md (Communication); this is its shape:

- the URL is bare and alone on its line — the terminal makes `https://`
  clickable, and `[text](url)` and a URL inside a sentence are not
- it is the last line before any question the report goes on to ask
- one line per artifact — a PR and the issue filed from it are two lines
- an artifact that is not live yet is marked as such — a tag the user has
  not pushed gets its future URL and the words 「push 後に有効」

## PR and issue bodies

The full catalogue of GitHub constructs — when a table beats bullets, what
goes in `<details>`, how many siblings a list can hold — is
`pull-request/references/markdown.md`. Read it before writing a body longer
than a few lines. The diagram gate lives in the `pull-request` skill.
