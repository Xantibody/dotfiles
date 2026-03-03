---
name: decision-record
description: Create a decision record from an executed plan.
---

# Decision Record

Use this skill after executing a plan (`/execute-plan`) and completing final verification.
It captures the rationale, outcomes, and next steps as a structured decision record in `./decisions/`.

## Workflow

### 1. Discover and Select Plan

- Read all files in `./plans/` directory
- If multiple plan files exist, present a summary of each and ask the user which one to record
- If only one plan file exists, confirm with the user before proceeding

### 2. Collect Context

- Extract motivation and background from the plan file
- Run `git log --oneline` to collect commits created during execution
- Extract out-of-scope items and future work notes from the plan

### 3. Draft Decision Record

Create a draft using the following template:

```markdown
## なぜやるか

（プランファイルの動機・背景から抽出）

## やったこと

（プランのステップ + git log から実際の実装内容をまとめる）

## やらなかったこと / 次にやること

（スコープ外の項目 + ユーザーへの追加確認）

## レビュワーへの依頼

（ユーザーに入力を求める）

## 資料

- Plan: `plans/<元のファイル名>`
- PR: （`gh pr view` で存在すれば記載）
- （プラン内の参照URL等）
```

### 4. User Review

- Present the draft to the user
- Accept corrections and additions

### 5. Save

- Create `./decisions/` directory if it does not exist
- Determine the next sequence number by scanning existing files (`NNNN` zero-padded, 4 digits)
- Generate `<slug>` in kebab-case from the plan file name or title
- Save as `./decisions/NNNN-<slug>.md`

### 6. Commit

- Use `/commit` skill to commit with the message format: `docs(decision): <summary>`

### 7. Cleanup

- Delete the source plan file from `./plans/`
- Use `/commit` skill to commit the deletion
