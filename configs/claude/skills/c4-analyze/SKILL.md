---
name: c4-analyze
description: Analyze c4 (Claude Code Command Collector) logs with DuckDB and distill improvement rules into CLAUDE.md. Use this skill when the user asks to analyze command logs, find slow or failing commands, review command usage patterns, detect replaceable pipelines, or update CLAUDE.md rules based on collected data. Triggers include "c4", "command log", "analyze", "retrospective", "slow command", "コマンドログ", "分析", "振り返り", "遅いコマンド".
---

# c4 Log Analysis (c4-analyze)

Analyze the Bash command logs collected by c4 with DuckDB, and distill
rules for improving Claude's own behavior (alternative CLIs,
project-specific conventions) into CLAUDE.md.

## Data location

- Primary: `~/.claude/c4.csv` (current schema, 14 columns)
- `~/.claude/c4.csv.v*.bak` are rotations of the old schema. **Do not read them**
- Once migrated to R2, switch to `read_json_auto('s3://<bucket>/logs/dt=*/*.jsonl')`

## How to run

If `duckdb` is not installed, fall back to `nix run nixpkgs#duckdb --`:

```sh
duckdb -c "<SQL>"                       # when installed
nix run nixpkgs#duckdb -- -c "<SQL>"    # fallback
```

## Schema and analysis caveats

| Column                                                  | Meaning                                                                              |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| timestamp                                               | Execution time (RFC3339 UTC)                                                         |
| session_id / tool_use_id                                | Group key for a session / a single Bash invocation                                   |
| project                                                 | basename of cwd                                                                      |
| hostname                                                | Machine that ran it (stratify spec/network differences by this key)                  |
| segment_index / connector                               | Position within a compound command and the preceding operator (`\|` `&&` `\|\|` `;`) |
| base_command / sub_command / flags / normalized_command | Normalized command (arguments and values excluded)                                   |
| duration_ms                                             | Runtime of the **whole invocation**. Same value on every row of a compound command   |
| status                                                  | success / failure (PostToolUseFailure fired = failure)                               |
| effort                                                  | reasoning effort level (proxy variable for the model)                                |

**Must-follow caveats:**

1. Deduplicate duration aggregates by `tool_use_id` (a compound command repeats the same value across rows)
2. Use the **median and p90**, not the average (cache cold/warm makes it vary)
3. When looking at a single command's duration, restrict to single-segment invocations

## Standard queries

```sql
-- 1. Command frequency and failure rate
SELECT normalized_command, count(*) AS n,
       round(avg(CASE WHEN status = 'failure' THEN 1 ELSE 0 END) * 100) AS fail_pct
FROM read_csv('~/.claude/c4.csv') GROUP BY 1 ORDER BY n DESC LIMIT 20;

-- 2. Time-consuming commands (single segment only, deduped per invocation)
WITH single AS (
  SELECT tool_use_id, any_value(normalized_command) AS cmd,
         any_value(duration_ms) AS ms
  FROM read_csv('~/.claude/c4.csv')
  GROUP BY tool_use_id HAVING count(*) = 1 AND any_value(duration_ms) IS NOT NULL
)
SELECT cmd, count(*) AS n, sum(ms) AS total_ms,
       median(ms)::int AS med_ms, quantile_cont(ms, 0.9)::int AS p90_ms
FROM single GROUP BY 1 ORDER BY total_ms DESC LIMIT 20;

-- 3. Frequent pipelines (the main hunting ground for replacements)
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

-- 4. Per-project lineup (seeds for project-specific rules)
SELECT project, normalized_command, count(*) AS n
FROM read_csv('~/.claude/c4.csv') GROUP BY 1, 2
QUALIFY row_number() OVER (PARTITION BY project ORDER BY n DESC) <= 5
ORDER BY project, n DESC;
```

## Distillation procedure

1. Run the four queries above and pick out the standout patterns
2. Cross-check against the replacement lookup table:
   - `grep` (frequent / with -r) → `rg` / `find` → `fd` / `cat X | grep Y` → `rg Y X`
   - `sort | uniq -c | sort` → `sort | uniq -c` is fine as-is, but if frequent consider a dedicated aggregation script
   - `npm` → `pnpm`, `pip` → `uv` only when consistent with the project's lock file
3. **Confirm the alternative CLI is actually installed** (`which rg fd`, etc.).
   Do not make a rule for something that is missing
4. Organize high-failure-rate commands into candidate project-specific
   rules of the form "in this repo, use `Y` instead of `X`"
5. Present the proposals to the user and, once approved, append to CLAUDE.md.
   **The user's CLAUDE.md is managed by home-manager**, so edit
   `~/Repository/dotfiles/configs/claude/CLAUDE.md` (a rebuild is required to apply it).
   Put project-specific rules in each repository's own `CLAUDE.md`
