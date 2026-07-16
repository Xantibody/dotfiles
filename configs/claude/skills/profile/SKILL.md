---
name: profile
description: Measure and quantify performance with profilers and flame graphs. Use this skill whenever the user wants to profile code, find hot spots or bottlenecks, generate a flame graph, benchmark code, or measure whether an optimization actually helped — including when the user just says something is "slow" and wants to know why. Covers FlameGraph (perf, sample), language-native profilers (go pprof, cargo flamegraph, py-spy), hyperfine, and differential flame graphs for before/after comparison.
---

# Profile

Measure performance with reproducible numbers and flame graphs. This skill covers **measurement only** — use the resulting data to decide what to optimize, then measure again to prove the improvement.

Core rule: never claim a performance improvement without before/after numbers taken under identical conditions. A flame graph shows _where_ time goes; a benchmark shows _how much_ — you usually want both.

## Workflow

### 1. Define the Workload

Fix a reproducible scenario before measuring anything:

- A concrete command, benchmark, or request pattern with fixed input data
- Release/optimized build (never profile debug builds; for Rust add `[profile.release] debug = true` to keep symbols)
- Quiet machine conditions — note anything that could skew results

Save all artifacts to `./profiles/` (add it to `.gitignore`) with names like `<label>-before.folded`, `<label>-before.svg` so before/after pairs stay comparable.

### 2. Choose the Profiler

| Target  | Wall-clock comparison                      | CPU profile → flame graph                                                             |
| ------- | ------------------------------------------ | ------------------------------------------------------------------------------------- |
| Go      | `go test -bench=. -count=10` + `benchstat` | `go test -cpuprofile cpu.prof` → `go tool pprof` (`-http` has a built-in flame graph) |
| Rust    | `cargo bench` (criterion) or hyperfine     | `cargo flamegraph --bin <name>` (or `--bench`)                                        |
| Python  | hyperfine                                  | `py-spy record -o flame.svg -- python app.py` (attach with `--pid`)                   |
| Node.js | hyperfine                                  | `node --cpu-prof` → open in speedscope, or `0x`                                       |
| Any CLI | `hyperfine --warmup 3 'cmd'`               | perf / sample + FlameGraph (below)                                                    |

Prefer the language-native profiler — it handles symbol resolution and build flags for you. Fall back to system profilers for compiled binaries or mixed workloads.

Tool acquisition: everything here is in nixpkgs — `nix shell nixpkgs#flamegraph nixpkgs#hyperfine` (also `cargo-flamegraph`, `py-spy`, `inferno` as a Rust port of the FlameGraph scripts).

### 3. Measure the Baseline

Always capture two kinds of data **before touching the code**:

1. **Wall-clock**: `hyperfine --warmup 3 --export-json profiles/<label>-before.json '<cmd>'` — gives mean ± σ over ≥10 runs. For Go, `go test -bench=. -count=10 | tee profiles/<label>-before.txt` for benchstat.
2. **CPU profile**: generate a flame graph and keep the intermediate folded stacks (needed later for the diff):

**Linux (perf):**

```bash
perf record -F 99 -g -- <cmd>
perf script | stackcollapse-perf.pl > profiles/<label>-before.folded
flamegraph.pl profiles/<label>-before.folded > profiles/<label>-before.svg
```

**macOS (sample):**

```bash
sample <pid-or-process-name> 30 -file /tmp/sample.txt
stackcollapse-sample.awk /tmp/sample.txt > profiles/<label>-before.folded
flamegraph.pl profiles/<label>-before.folded > profiles/<label>-before.svg
```

(`cargo flamegraph` and `py-spy` do the collapse+render in one step; use `py-spy record --format raw` / `cargo flamegraph --post-process` when you need the folded file for diffing. For deep macOS dives, Instruments via `xctrace record --template 'Time Profiler'`.)

Sampling at 99 Hz avoids lockstep with periodic work; raise it only for very short runs.

### 4. Read the Flame Graph

Open the SVG in a browser (it is interactive — click to zoom, Ctrl+F to search):

- **Width = total time in that function** (including children); the x-axis is alphabetical, not chronological
- Look for wide plateaus at the top — that is where CPU time is actually spent
- Search for known-expensive patterns: allocation (`malloc`, `runtime.mallocgc`), serialization, regex, syscalls

Report the top hot spots with their percentage width. This is the evidence for deciding what to change.

### 5. Measure After the Change

Repeat step 3 with the exact same workload, flags, and machine conditions, writing `<label>-after.*` files.

### 6. Compare and Report

- **Wall-clock**: `hyperfine` both commands in one invocation for a statistical comparison, or for Go: `benchstat profiles/<label>-before.txt profiles/<label>-after.txt` (shows delta with p-value)
- **Differential flame graph**: `difffolded.pl profiles/<label>-before.folded profiles/<label>-after.folded | flamegraph.pl > profiles/<label>-diff.svg` — red = grew, blue = shrank

Report using this structure:

```markdown
## Performance Measurement: <label>

**Workload**: <command / benchmark, input size, build flags>
**Environment**: <machine, OS, notable conditions>

| Metric                             | Before | After | Delta |
| ---------------------------------- | ------ | ----- | ----- |
| wall-clock (mean ± σ)              | ...    | ...   | -XX%  |
| <hot function> (flame graph width) | XX%    | XX%   | ...   |

Flame graphs: profiles/<label>-{before,after,diff}.svg
```

If the delta is within the noise (overlapping ±σ, or benchstat says ~), say so plainly — "no measurable improvement" is a valid, useful result.

## Pitfalls

- Comparing a debug build against a release build, or runs on different machine states — the numbers are meaningless
- Single-run timings — always use warmup + repetition; report variance, not just the mean
- Missing symbols (all frames show hex addresses): install debug info / keep symbols in release builds, then re-profile
- On macOS, `perf` does not exist and dtrace needs SIP changes — prefer `sample`, `py-spy`, `cargo flamegraph`, or Instruments
