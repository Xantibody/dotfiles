---
name: issue
description: Creates GitHub issues with a concise Japanese body, modeled on traP NeoShowcase's issue templates (bug report / feature request). Use this skill whenever the user wants to file, open, or create an issue — including phrasings like "issueを立てて", "issue作って", "バグ報告して", "機能要望を出して", "この問題をissueにして", or "gh issue create". Also use it when the user describes a bug or wants to track future work as an issue.
---

# Issues

The reader of an issue is either you months from now or someone with no
context. The job is to leave just enough for them to reproduce and decide,
briefly — long issues don't get read.

## Check the repo's own templates first

If the target repo has `.github/ISSUE_TEMPLATE/`, that takes precedence —
follow it instead of this skill's templates. Otherwise use the ones below.

## Pick a type

**Bug report** — something doesn't behave as expected. **Feature request** — a
new behavior is wanted. Tasks that are neither (refactoring, investigation,
TODO) borrow the feature-request shape and drop the sections that don't fit.

The issue body is written in Japanese.

### Bug report

Title: `[Bug]: <one-line summary>`

```markdown
## バグの概要

<何が起きるか一行で>

## 再現手順

1. <第三者がこの手順だけで再現できる粒度で>

## 期待する動作

<何が起こるはずだったか>

## 実際の動作

<実際に何が起きたか。エラーメッセージは原文のまま貼る>

## 再現環境

<OS / バージョン / 発生条件。わかる範囲で>

## 関連情報

<ログ、スクリーンショット、関連 issue やリンク>
```

The reproduction steps carry most of the value. Omitting assumptions that only
hold on your machine (local paths, pre-existing state) leaves the reader
unable to reproduce, and the issue goes stale.

### Feature request

Title: `[Feature]: <one-line summary>`

```markdown
## 問題の説明

<今の何が困るのか。これが無い機能要望は判断できない>

## 新機能の説明

<どうなってほしいか>

## その他の案

<検討して見送った代替案。あれば>

## 参考資料

<関連リンク、議論、先行事例>
```

問題の説明 is the core. State the problem before the solution — if the problem
is shared, a different solution may do; if it isn't, no implementation
proposal can be judged.

## Common rules

- **Drop sections you can't fill.** Deleting a section beats leaving it blank
  or writing "特になし". The template is not a completeness checklist.
- A diagram is warranted only when proposing or explaining architecture. Don't
  force one otherwise.
- If reproduction logs or error output already exist in the conversation,
  paste them verbatim into 実際の動作 or 関連情報 instead of summarizing.
  Primary evidence beats a summary.

## Create

Write the body outside the worktree and pass it via `--body-file` (`--body`
mangles newlines):

```bash
BODY=$(mktemp -d)/issue-body.md
gh issue create --title "<title>" --body-file "$BODY"
```

Only add labels after confirming they exist with `gh label list` (use
`kind/bug` / `kind/feature` equivalents if present). Passing a nonexistent
label to `--label` fails the whole creation.

Report the issue URL once created. If creation is denied by permissions, hand
over the command with the real path substituted, in the form
`! gh issue create --title "..." --body-file <path>`, so the user can run it
in their own session.
