---
name: c4-analyze
description: Analyze c4 (Claude Code Command Collector) logs with DuckDB and distill improvement rules into CLAUDE.md. Use this skill when the user asks to analyze command logs, find slow or failing commands, review command usage patterns, detect replaceable pipelines, or update CLAUDE.md rules based on collected data. Triggers include "c4", "コマンドログ", "分析", "振り返り", "遅いコマンド".
---

# c4 Log Analysis (c4-analyze)

c4が収集したBashコマンドログをDuckDBで分析し、Claude自身の行動改善規則
（代替CLI・プロジェクト固有の作法）をCLAUDE.mdに蒸留する。

## データの場所

- 本体: `~/.claude/c4.csv`（現行スキーマ・14列）
- `~/.claude/c4.csv.v*.bak` は旧スキーマのローテーション。**読まない**
- 将来R2に移行したら `read_json_auto('s3://<bucket>/logs/dt=*/*.jsonl')` に差し替える

## 実行方法

`duckdb` が無ければ `nix run nixpkgs#duckdb --` で代用する:

```sh
duckdb -c "<SQL>"                       # インストール済みの場合
nix run nixpkgs#duckdb -- -c "<SQL>"    # フォールバック
```

## スキーマと分析上の注意

| 列 | 意味 |
| --- | --- |
| timestamp | 実行日時 (RFC3339 UTC) |
| session_id / tool_use_id | セッション / 1回のBash呼び出しのグループキー |
| project | cwdのbasename |
| hostname | 実行マシン（スペック・回線差はこのキーで层別する） |
| segment_index / connector | 複合コマンド内の位置と直前の演算子 (`|` `&&` `||` `;`) |
| base_command / sub_command / flags / normalized_command | 正規化済みコマンド（引数・値は含まない） |
| duration_ms | **呼び出し全体**の実行時間。複合コマンドでは全レコードに同値 |
| status | success / failure（PostToolUseFailure発火＝failure） |
| effort | reasoning effortレベル（modelの代理変数） |

**必ず守る注意点:**

1. duration集計は `tool_use_id` で重複排除する（複合コマンドで同値が複数行に入るため）
2. 平均ではなく**中央値・p90**を使う（キャッシュのcold/warmでばらつくため）
3. コマンド単体のdurationを見るときは単一セグメントの呼び出しに絞る

## 定番クエリ

```sql
-- 1. コマンド頻度と失敗率
SELECT normalized_command, count(*) AS n,
       round(avg(CASE WHEN status = 'failure' THEN 1 ELSE 0 END) * 100) AS fail_pct
FROM read_csv('~/.claude/c4.csv') GROUP BY 1 ORDER BY n DESC LIMIT 20;

-- 2. 時間を食っているコマンド（単一セグメントのみ・呼び出し単位で重複排除）
WITH single AS (
  SELECT tool_use_id, any_value(normalized_command) AS cmd,
         any_value(duration_ms) AS ms
  FROM read_csv('~/.claude/c4.csv')
  GROUP BY tool_use_id HAVING count(*) = 1 AND any_value(duration_ms) IS NOT NULL
)
SELECT cmd, count(*) AS n, sum(ms) AS total_ms,
       median(ms)::int AS med_ms, quantile_cont(ms, 0.9)::int AS p90_ms
FROM single GROUP BY 1 ORDER BY total_ms DESC LIMIT 20;

-- 3. 頻出パイプライン（置換候補の主戦場）
WITH chains AS (
  SELECT tool_use_id,
         string_agg(CASE WHEN connector = '' THEN normalized_command
                         ELSE connector || ' ' || normalized_command END,
                    ' ' ORDER BY segment_index) AS pipeline,
         count(*) AS segments
  FROM read_csv('~/.claude/c4.csv') GROUP BY tool_use_id
)
SELECT pipeline, count(*) AS n FROM chains
WHERE segments > 1 GROUP BY 1 ORDER BY n DESC LIMIT 20;

-- 4. プロジェクト別の顔ぶれ（プロジェクト固有規則の種）
SELECT project, normalized_command, count(*) AS n
FROM read_csv('~/.claude/c4.csv') GROUP BY 1, 2
QUALIFY row_number() OVER (PARTITION BY project ORDER BY n DESC) <= 5
ORDER BY project, n DESC;
```

## 蒸留の手順

1. 上の4クエリを実行し、目立つパターンを拾う
2. 置換候補の対応表と突き合わせる:
   - `grep`(頻用/-r付き) → `rg` / `find` → `fd` / `cat X | grep Y` → `rg Y X`
   - `sort | uniq -c | sort` → `sort | uniq -c` はそのまま可だが頻出なら集計スクリプト化を検討
   - `npm` → `pnpm`・`pip` → `uv` はプロジェクトのlockファイルと整合する場合のみ
3. 代替CLIが**実際にインストールされているか確認**（`which rg fd` 等）。
   無いものを規則化しない
4. 失敗率の高いコマンドは「このrepoでは`X`ではなく`Y`を使う」の形の
   プロジェクト固有規則候補として整理する
5. 提案をユーザーに提示し、承認後にCLAUDE.mdへ追記する。
   **ユーザーのCLAUDE.mdはhome-manager管理**のため、編集先は
   `~/Repository/dotfiles/configs/claude/CLAUDE.md`（反映にはリビルドが必要）。
   プロジェクト固有規則は各リポジトリの `CLAUDE.md` に置く
