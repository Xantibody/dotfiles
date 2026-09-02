---
name: c4-analyze
description: Analyze c4 (Claude Code Command Collector) logs with DuckDB, audit whether existing CLAUDE.md rules still earn their place, and distill a net-neutral rule diff. Use this skill when the user asks to analyze command logs, find slow or failing commands, review command usage patterns, detect replaceable pipelines, or update CLAUDE.md rules based on collected data. Triggers include "c4", "command log", "analyze", "retrospective", "slow command", "コマンドログ", "分析", "振り返り", "遅いコマンド".
---

# c4 Log Analysis (c4-analyze)

Analyze the Bash command logs collected by c4 with DuckDB, then produce a
**diff** to CLAUDE.md — not an append. Every round both adds rules the data
justifies and retires rules the data no longer supports. A ruleset that only
grows loses adherence per rule; keep it roughly line-neutral.

## Data location

- Primary: `~/.claude/c4.csv` (current schema, 14 columns)
- `~/.claude/c4-raw.jsonl` — the raw hook payload for every row, kept by
  `C4_DUMP`: the full command in `tool_input.command`, stdout/stderr in
  `tool_response`, plus `effort`, `agent_type`, `permission_mode`,
  `tool_input.timeout`, `tool_response.timedOutAfterMs`. This is where
  argument shape lives (query 7). It also holds secrets and file contents —
  aggregate it, never quote a raw command or output into a rule or report
- `~/.claude/c4.csv.v*.bak` are rotations of the old schema. **Do not read them**

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
3. When looking at a single command's duration, restrict to single-segment
   invocations — **but never stop there.** Only ~11% of invocations are single
   segment, so that view is blind to anything that only ever appears mid-chain
   (`sleep`, `nc`, loop bodies). Always also run query 5.
4. The first segment's `connector` is **NULL**, not `''`
5. **The CSV has no arguments.** Frequency alone cannot tell a violation
   from a legitimate use — `| head` (truncating command output) and
   `head file` (reading a file) are the same `base_command` but only the
   latter breaks a rule. Same for `cat`: heredoc writes and `cat f | rg` are
   fine. Split by position/connector in the CSV first, then confirm the
   shape against the raw dump with query 7 — in the current data the
   `| head/tail` form outnumbers file reads more than ten to one, so a
   CSV-only count of `head` is mostly noise

## Standard queries

```sql
-- 0. Scope: how much data, over what window
SELECT count(*) AS rows, count(DISTINCT tool_use_id) AS invocations,
       count(DISTINCT session_id) AS sessions,
       min(timestamp) AS from_ts, max(timestamp) AS to_ts
FROM read_csv('~/.claude/c4.csv');

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
         string_agg(CASE WHEN connector IS NULL OR connector = '' THEN normalized_command
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

-- 5. Wall-time attribution — THE money query.
--    Attributes each invocation's full duration to every command inside it,
--    so mid-chain time sinks surface. Overlapping by design: read it as
--    "invocations containing X cost N seconds", then confirm by eyeballing
--    the individual chains (query 5b).
WITH inv AS (
  SELECT tool_use_id, any_value(duration_ms) AS ms
  FROM read_csv('~/.claude/c4.csv') GROUP BY 1
),
j AS (
  SELECT DISTINCT c.tool_use_id, c.normalized_command, i.ms
  FROM read_csv('~/.claude/c4.csv') c JOIN inv i USING (tool_use_id)
)
SELECT normalized_command, count(*) AS n, sum(ms) / 1000 AS total_s,
       median(ms)::int AS med_ms
FROM j WHERE ms IS NOT NULL GROUP BY 1 ORDER BY total_s DESC LIMIT 20;

-- 5b. Denominator + the actual chains behind a suspect command.
--     Always report a time finding as a % of this total.
WITH inv AS (
  SELECT tool_use_id, any_value(duration_ms) AS ms, any_value(project) AS proj,
         string_agg(normalized_command, ' ' ORDER BY segment_index) AS p
  FROM read_csv('~/.claude/c4.csv') GROUP BY 1
)
SELECT proj, ms, p FROM inv
WHERE ms IS NOT NULL AND p LIKE '%<suspect>%' ORDER BY ms DESC;

-- 6. Rule effectiveness — did the last round's rules change behavior?
--    Get the cutoff from: git log --format='%h %ad %s' --date=short -- configs/claude/CLAUDE.md
WITH d AS (
  SELECT *, CASE WHEN timestamp < '<rule_added_date>' THEN 'before' ELSE 'after' END AS era
  FROM read_csv('~/.claude/c4.csv')
)
SELECT era, count(DISTINCT tool_use_id) AS inv,
       count(*) FILTER (base_command = '<targeted>') AS targeted,
       count(*) FILTER (base_command = '<replacement>') AS replacement,
       round(avg(CASE WHEN status = 'failure' THEN 1 ELSE 0 END) * 100)
         FILTER (base_command = '<targeted>') AS targeted_fail_pct
FROM d GROUP BY 1;

-- 7. Argument shape from the raw dump. The regexes are starting points —
--    adjust them to the command under suspicion, and report only the counts.
WITH raw AS (
  SELECT tool_input.command AS cmd
  FROM read_json_auto('~/.claude/c4-raw.jsonl', union_by_name=true, ignore_errors=true)
)
SELECT CASE
  WHEN regexp_matches(cmd, '(^|[|&;]\s*)cat\s*(>[^<]*)?<<') THEN 'heredoc write'
  WHEN regexp_matches(cmd, '\|\s*(head|tail)\b') THEN 'pipe | head/tail'
  WHEN regexp_matches(cmd, '(^|[|&;]\s*)(cat|head|tail)\s+[^-<|]') THEN 'read file'
  ELSE 'other' END AS shape, count(*) AS n
FROM raw GROUP BY 1 ORDER BY n DESC;
```

## Procedure

### Step 1 — Audit the existing rules first

Read `configs/claude/CLAUDE.md`, then run query 6 once per existing
Command-Usage rule, using the date that rule landed as the cutoff. Classify
each rule:

| Signal                                               | Action                                                                                           |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Targeted command **never appears** (n = 0)           | **Delete** — a warning against a temptation that isn't real                                      |
| Replacement now dominates ~10:1 and failures are low | **Delete or compress** — behavior is internalized; keep only the sub-clause still being violated |
| The cited statistic no longer holds                  | **Rewrite** with the current number, or drop it — stale evidence undermines every other rule     |
| Still violated, and query 5 shows real cost          | **Strengthen** — name the exact anti-pattern form that leaked through                            |
| Two rules share one underlying norm                  | **Merge** into one bullet                                                                        |

### Step 2 — Find new candidates

Run queries 0–5. For each candidate, before proposing anything:

1. **Split by position/connector** (caveat 5) to separate violations from
   legitimate uses. Do not quote a raw frequency as evidence of waste
2. **Verify the claim outside the log.** If the finding is "used Python in a
   non-Python repo", check with `fd -e py <repo>`. If it is "should use `rg`",
   confirm the binary exists (`which rg fd`). Never write a rule for a tool
   that is not installed
3. Cross-check the replacement table:
   - `grep` (frequent / with -r) → `rg` / `find` → `fd` / `cat X | grep Y` → `rg Y X`
   - `npm` → `pnpm`, `pip` → `uv` — only when consistent with the project's lock file

### Step 3 — Apply the evidence bar

A finding becomes a rule only if it clears **both**:

- **Measured loss** — a share of total wall time (query 5b denominator), or a
  failure rate well above the baseline (query 3 — cite the number you
  measured, not the one in the previous round's rule), or a repeated wasted
  round trip
- **A concrete replacement** the next session can act on

Explicitly reject the rest and say so. Cheap-but-noisy patterns (decorative
`echo`, `sed` failing at roughly the baseline rate) are _not_ rules. Note that the biggest
lever is usually a handful of very slow invocations, not the most frequent
command — check share of total time before assuming frequency means cost.

### Step 4 — Present a diff, then apply

Lead with **intent**: the wasteful pattern the data shows, why it happens, and
how behavior would change. Present additions and retirements together as a
`diff` block with a bullet-count delta, and state which candidates were
rejected and why. Ask for approval before editing.

Once approved:

- **The user's CLAUDE.md is managed by home-manager** — `~/.claude/CLAUDE.md`
  is a symlink into the Nix store, so edit the source in the dotfiles repo
  (`configs/claude/CLAUDE.md`, next to this skill under
  `configs/claude/skills/`; find the checkout with `ghq list -p dotfiles`).
  A rebuild is required to apply it
- Put project-specific rules in each repository's own `CLAUDE.md`
- Keep every rule one bullet with its evidence inline (`c4 data: …`) so the
  next round can audit it. A rule with no cited evidence cannot be retired
  on evidence
