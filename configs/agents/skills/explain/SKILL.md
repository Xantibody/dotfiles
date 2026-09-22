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

A report on work that touched a remote — a PR, an issue, a CI run, a
release, a ruleset, a deployed page — ends with the URL of what it
touched, so the reader opens it from the terminal without looking for it:

- the URL is bare and alone on its line — the terminal makes `https://`
  clickable, and `[text](url)` and a URL inside a sentence are not
- it is the last line before any question the report goes on to ask
- one line per artifact — a PR and the issue filed from it are two lines
- an artifact that is not live yet is marked as such — a tag the user has
  not pushed gets its future URL and the words 「push 後に有効」

## What was left out

When a report ends with things deliberately left out (やらなかったこと,
deferred items, "not in this change"), ask whether to file them as issues
and recommend which ones — the `issue` skill has a deferred-work template.
The reason something was skipped is freshest right then and is lost by the
next session.

## PR and issue bodies

The full catalogue of GitHub constructs — when a table beats bullets, what
goes in `<details>`, how many siblings a list can hold — is
`pull-request/references/markdown.md`. Read it before writing a body longer
than a few lines. The diagram gate lives in the `pull-request` skill.

### Lint the body

A body is linted before `gh` sees it, and the lint is the gate, not the
prose above: the `pull-request` and `issue` skills register a PreToolUse
hook (`lint-body-hook`, from their frontmatter) that runs the same check
on the `--body-file` of `gh pr create` / `gh pr edit` / `gh issue create`
/ `gh issue comment` and refuses the command while findings remain. It
stays registered for the rest of the session once either skill has been
invoked. codex ignores frontmatter hooks, so there the `lint-body` step
written in those skills' bodies is the only gate — do not skip it.

```bash
lint-body <path>         # 指摘を見る
lint-body --fix <path>   # 機械的に直せるものは直す
```

Fix every finding and rerun until it is clean. Because each Bash call is
a fresh shell, the hook can only follow a literal path — write the real
path into `--body-file`, not `$BODY`, and never pass `--body` inline.

The rules are the Japanese technical-writing preset plus a few that are
house rules rather than textlint's, so know them before drafting instead
of learning them from the findings:

- **A paragraph or bullet is one line.** In PR and issue bodies GitHub
  renders a newline inside a paragraph as a visible line break, so an
  80-column wrap or a newline after each sentence breaks the text
  mid-thought. `--fix` joins the lines.
- **No separator after a bullet's head.** 「`foo` — 説明」 and
  「**重要**: 本文」 are a heading and a body pushed into one line; make
  it one sentence or nest the body beneath.
- **No empty section.** A heading with nothing under it, or with only
  「特になし」, is deleted, not left as a placeholder.
- **Space between Japanese and Latin, including around inline code.**
  「`rm` が終わる前に」, not 「`rm`が終わる前に」.
- **Open the kanji the rule opens.** 事 → こと, 時 → とき, 為 → ため,
  下さい → ください; the finding names the reading.
