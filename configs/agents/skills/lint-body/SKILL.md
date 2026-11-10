---
name: lint-body
description: The gate a PR or issue body passes before `gh` sees it — the `lint-body` command, the hook that refuses `gh pr create` / `gh issue create` while findings remain, and the house textlint rules to know before drafting. How to write the body is the osekkai skill's; this is only the check.
when_to_use: PR 本文や issue 本文を gh に渡す前、lint-body の指摘を直すとき、pull-request か issue の skill が読み込むとき — 「lint-body 通して」「textlint の指摘直して」「本文の lint」。
---

# Linting a body

How a body is written — who reads it, what they know, how the bullets
and sections are shaped — is the `osekkai` skill's. This skill is the
check that runs on the result before it reaches GitHub.

## The gate

A body is linted before `gh` sees it, and the lint is the gate, not the
prose rules: the `pull-request` and `issue` skills register a PreToolUse
hook (`lint-body-hook`, from their frontmatter) that runs the same check
on the `--body-file` of `gh pr create` / `gh pr edit` / `gh issue create`
/ `gh issue comment`, prints the findings, and refuses the command while
any remain. It stays registered for the rest of the session once either
skill has been invoked. codex ignores frontmatter hooks, so there the
`lint-body` step written in those skills' bodies is the only gate — do
not skip it.

```bash
lint-body <path>         # 指摘を見る
lint-body --fix <path>   # 機械的に直せるものは直す
```

Fix every finding and rerun until it is clean. Because each Bash call is
a fresh shell, the hook can only follow a literal path — write the real
path into `--body-file`, not `$BODY`, and never pass `--body` inline.

## The house rules

`lint-body` runs textlint and then `osekkai lint` on the same file, and
fails if either reports anything; `--fix` only fixes textlint's findings.
The textlint rules are the Japanese technical-writing preset plus a few
that are house rules rather than textlint's, so know them before drafting
instead of learning them from the findings (the structure rules are
osekkai's, and its skill has them):

- **A bullet is one line; a paragraph is one sentence per line.** In PR
  and issue bodies GitHub renders a newline inside a paragraph as a
  visible line break, so the break goes after every 「。」 and nowhere
  else: an 80-column wrap cuts a sentence mid-thought, and two sentences
  on one line hide where one ends. `--fix` repairs both.
- **No separator after a bullet's head.** 「`foo` — 説明」 and
  「**重要**: 本文」 are a heading and a body pushed into one line; make
  it one sentence or nest the body beneath.
- **No empty section.** A heading with nothing under it, or with only
  「特になし」, is deleted, not left as a placeholder.
- **Space between Japanese and Latin, including around inline code.**
  「`rm` が終わる前に」, not 「`rm`が終わる前に」.
- **Open the kanji the rule opens.** 事 → こと, 時 → とき, 為 → ため,
  下さい → ください; the finding names the reading.
