---
name: profile
description: Measure and quantify performance with profilers and flame graphs. Covers FlameGraph (perf, sample), language-native profilers (go pprof, cargo flamegraph, py-spy), hyperfine, and differential flame graphs for before/after comparison.
when_to_use: Whenever the user wants to profile code, find hot spots or bottlenecks, generate a flame graph, benchmark code, or measure whether an optimization actually helped — including when they just say something is "slow" / "遅い" and want to know why, or say "プロファイル取って", "ボトルネック探して", "ベンチ取って", "フレームグラフ出して".
---

# Profile

Measure performance with reproducible numbers and flame graphs. This skill covers **measurement only** — use the resulting data to decide what to optimize, then measure again to prove the improvement.

Two rules, no exceptions:

1. **Visualize before you evaluate.** Do not name a cause, rank a hot spot, or propose a change until a flame graph of the baseline exists in `.ai/profiles/` and you have read its hot spots (step 4). Reading the source and guessing where time goes is not profiling. If the target genuinely cannot be sampled — a CI pipeline, a remote service, a wait on the network — say so in the report before anything else, and substitute the nearest breakdown of where the time went (per-step timings, a trace). Never skip the visualization silently.
2. **Never claim an improvement without before/after numbers taken under identical conditions.** A flame graph shows _where_ time goes; a benchmark shows _how much_ — you need both.

## Tools

home-manager installs the toolchain on every host (`modules/home-manager/home/packages/profile.nix` in dotfiles): `flamegraph.pl`, `stackcollapse-*.pl`, `difffolded.pl`, the `inferno-*` ports (`inferno-collapse-xctrace` for macOS Instruments), `hyperfine`, `py-spy`, `cargo flamegraph`, and `perf` on Linux. `go tool pprof` comes with Go; macOS has `sample` built in.

Check before starting, and fall back to `nix shell nixpkgs#flamegraph nixpkgs#hyperfine` on a machine that is not from dotfiles:

```bash
command -v flamegraph.pl stackcollapse-perf.pl difffolded.pl hyperfine
```

`benchstat` is not in nixpkgs — run it as `go run golang.org/x/perf/cmd/benchstat@latest`.

## Workflow

### 1. Define the Workload

Fix a reproducible scenario before measuring anything:

- A concrete command, benchmark, or request pattern with fixed input data
- Release/optimized build (never profile debug builds; for Rust add `[profile.release] debug = true` to keep symbols)
- Quiet machine conditions — note anything that could skew results

Save all artifacts to `.ai/profiles/` (`.ai/` is globally gitignored, so nothing needs adding to `.gitignore`) with names like `<label>-before.folded`, `<label>-before.svg` so before/after pairs stay comparable.

### 2. Choose the Profiler

Every path ends in a **folded stacks file** (`frame;frame;frame count` per line). That one format feeds `flamegraph.pl`, `difffolded.pl`, and the hotspots script, so always keep it.

| Target  | Wall-clock comparison                      | Folded stacks                                                                         |
| ------- | ------------------------------------------ | ------------------------------------------------------------------------------------- |
| Go      | `go test -bench=. -count=10` + `benchstat` | `go test -cpuprofile cpu.prof` → `go tool pprof -raw cpu.prof \| stackcollapse-go.pl` |
| Rust    | `cargo bench` (criterion) or hyperfine     | `cargo flamegraph --bin <name> --post-process 'tee <label>.folded'`                   |
| Python  | hyperfine                                  | `py-spy record --format raw -o <label>.folded -- python app.py` (or `--pid`)          |
| Node.js | hyperfine                                  | `node --cpu-prof` → open in speedscope (no folded output; report from its UI)         |
| Any CLI | `hyperfine --warmup 3 'cmd'`               | perf / sample + FlameGraph (below)                                                    |

Prefer the language-native profiler — it handles symbol resolution and build flags for you. Fall back to system profilers for compiled binaries or mixed workloads.

### 3. Measure the Baseline

Always capture two kinds of data **before touching the code**:

1. **Wall-clock**: `hyperfine --warmup 3 --export-json .ai/profiles/<label>-before.json '<cmd>'` — gives mean ± σ over ≥10 runs. For Go, `go test -bench=. -count=10 | tee .ai/profiles/<label>-before.txt` for benchstat.
2. **CPU profile**: folded stacks, then the flame graph:

**Linux (perf):**

```bash
perf record -F 99 -g -- <cmd>
perf script | stackcollapse-perf.pl > .ai/profiles/<label>-before.folded
flamegraph.pl .ai/profiles/<label>-before.folded > .ai/profiles/<label>-before.svg
```

**macOS (sample):**

```bash
sample <pid-or-process-name> 30 -file /tmp/sample.txt
stackcollapse-sample.awk /tmp/sample.txt > .ai/profiles/<label>-before.folded
flamegraph.pl .ai/profiles/<label>-before.folded > .ai/profiles/<label>-before.svg
```

For deep macOS dives use Instruments (`xctrace` ships with full Xcode, not the Command Line Tools):

```bash
xctrace record --template 'Time Profiler' --launch <cmd> --output /tmp/run.trace   # or --attach <pid>
xctrace export --input /tmp/run.trace --xpath '/trace-toc/*/data/table[@schema="time-profile"]' \
  | inferno-collapse-xctrace > .ai/profiles/<label>-before.folded
```

Sampling at 99 Hz avoids lockstep with periodic work; raise it only for very short runs.

### 4. Read the Flame Graph

The SVG is the user's artifact — interactive in a browser (click to zoom, Ctrl+F to search). You cannot see it, so read the same data as text:

```bash
go run ~/.claude/skills/profile/scripts/hotspots/main.go .ai/profiles/<label>-before.folded
```

It prints the widest frames twice: **self** (the frame is the leaf — where the CPU actually is) and **total** (frame plus children — what the flame graph draws as width). Thread and loader frames (`Thread_…`, `dyld`) at the top of the total table are scaffolding; the first frame from your own code below them is the story.

- Wide plateaus in _self_ are the hot spots; a frame wide in _total_ but thin in _self_ is a caller, not a cause
- Search for known-expensive patterns: allocation (`malloc`, `runtime.mallocgc`), serialization, regex, syscalls

Report the top hot spots with their percentage width, and the SVG path. This is the evidence for deciding what to change — only now does evaluation start.

### 5. Measure After the Change

Repeat step 3 with the exact same workload, flags, and machine conditions, writing `<label>-after.*` files.

### 6. Compare and Report

- **Wall-clock**: `hyperfine` both commands in one invocation for a statistical comparison, or for Go: `benchstat .ai/profiles/<label>-before.txt .ai/profiles/<label>-after.txt` (shows delta with p-value)
- **Differential flame graph**: `difffolded.pl .ai/profiles/<label>-before.folded .ai/profiles/<label>-after.folded | flamegraph.pl > .ai/profiles/<label>-diff.svg` — red = grew, blue = shrank. Run the hotspots script on both folded files to put the same delta in the table.

Report using this structure:

```markdown
## Performance Measurement: <label>

**Workload**: <command / benchmark, input size, build flags>
**Environment**: <machine, OS, notable conditions>

| Metric                             | Before | After | Delta |
| ---------------------------------- | ------ | ----- | ----- |
| wall-clock (mean ± σ)              | ...    | ...   | -XX%  |
| <hot function> (flame graph width) | XX%    | XX%   | ...   |

Flame graphs: .ai/profiles/<label>-{before,after,diff}.svg
```

If the delta is within the noise (overlapping ±σ, or benchstat says ~), say so plainly — "no measurable improvement" is a valid, useful result.

## Pitfalls

- Comparing a debug build against a release build, or runs on different machine states — the numbers are meaningless
- Single-run timings — always use warmup + repetition; report variance, not just the mean
- Missing symbols (all frames show hex addresses): install debug info / keep symbols in release builds, then re-profile
- On macOS, `perf` does not exist and dtrace needs SIP changes — prefer `sample`, `py-spy`, `cargo flamegraph`, or Instruments
- A flame graph of a process that mostly sleeps (server idle, waiting on I/O) is all `epoll`/`kevent` — profile under load, or profile off-CPU time instead
