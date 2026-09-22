---
name: profile
description: Measure and quantify performance. Decides what is being measured first — CPU, waiting, memory, or a pipeline — and picks the instrument from that. Covers on-CPU and off-CPU flame graphs (perf, sample, py-spy, cargo flamegraph, go pprof), allocation profiles, hyperfine, and differential flame graphs for before/after comparison.
when_to_use: Whenever the user wants to profile code, find hot spots or bottlenecks, generate a flame graph, benchmark code, or measure whether an optimization actually helped — including when they just say something is "slow" / "遅い" and want to know why, or say "プロファイル取って", "ボトルネック探して", "ベンチ取って", "フレームグラフ出して".
---

# Profile

Measure performance with reproducible numbers and a picture of where the time goes. This skill covers **measurement only** — use the resulting data to decide what to optimize, then measure again to prove the improvement.

Two rules, no exceptions:

1. **Visualize before you evaluate.** Do not name a cause, rank a hot spot, or propose a change until a baseline picture of where the time goes exists in `.ai/profiles/` and you have read it (step 5). Reading the source and guessing is not profiling. Which picture depends on what is being measured (step 2): a flame graph answers "where is the CPU", and is the wrong instrument for a process that is waiting. If the target genuinely cannot be measured, say so in the report before anything else. Never skip the visualization silently.
2. **Never claim an improvement without before/after numbers taken under identical conditions.** The picture shows _where_ time goes; a benchmark shows _how much_ — you need both.

## Tools

home-manager installs the toolchain on every host (`modules/home-manager/home/packages/profile.nix` in dotfiles): `flamegraph.pl`, `stackcollapse-*.pl`, `difffolded.pl`, the `inferno-*` ports (`inferno-collapse-xctrace` for macOS Instruments), `hyperfine`, `py-spy`, `cargo flamegraph`, and `perf` on Linux. `go tool pprof` and `go tool trace` come with Go; macOS has `sample` built in.

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

### 2. Measure Wall-Clock and Decide What You Are Measuring

The first measurement is the wall-clock baseline, and it also tells you which instrument to use next:

```bash
hyperfine --warmup 3 --export-json .ai/profiles/<label>-before.json '<cmd>'
```

hyperfine prints `Time (mean ± σ)` together with `User:` and `System:`. Compare user + system against the mean:

| user + system vs wall                                   | What is being measured                                     | Picture to make                                        |
| ------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------ |
| ≈ wall (or above, multi-threaded)                       | **CPU** — the process is computing                         | on-CPU flame graph                                     |
| ≪ wall                                                  | **Waiting** — I/O, locks, network, sleeps, child processes | off-CPU / wall-clock flame graph, or a syscall summary |
| CPU-bound but RSS or GC dominates                       | **Memory** — allocation churn, GC pauses                   | allocation profile                                     |
| Not one process (CI, HTTP across services, build graph) | **A pipeline** — the time is between steps                 | timeline: per-step durations, a trace                  |

For Go benchmarks, `go test -bench=. -count=10 | tee .ai/profiles/<label>-before.txt` is the wall-clock baseline; `-benchmem` adds the allocation column that decides between CPU and memory.

Write the verdict into the report's **Workload** line ("CPU-bound: user+sys 1.9 s of 2.0 s wall"). A wrong classification here wastes every step after it.

### 3. Choose the Instrument

Pick the row from step 2, then the language-native tool where one exists — it handles symbol resolution and build flags. Every stack-sampling path ends in a **folded stacks file** (`frame;frame;frame count` per line), which is what `flamegraph.pl`, `difffolded.pl`, and the hotspots script all read, so always keep it.

**CPU (on-CPU flame graph)**

| Target  | Folded stacks                                                                         |
| ------- | ------------------------------------------------------------------------------------- |
| Go      | `go test -cpuprofile cpu.prof` → `go tool pprof -raw cpu.prof \| stackcollapse-go.pl` |
| Rust    | `cargo flamegraph --bin <name> --post-process 'tee <label>.folded'`                   |
| Python  | `py-spy record --format raw -o <label>.folded -- python app.py` (or `--pid`)          |
| Node.js | `node --cpu-prof` → open in speedscope (no folded output; report from its UI)         |
| Any     | Linux: `perf record -F 99 -g`; macOS: `sample` — recipes in step 4                    |

**Waiting (off-CPU)**

| Target | Instrument                                                                                                                                                                                                    |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Go     | `go test -blockprofile block.prof -mutexprofile mutex.prof` → `go tool pprof -top`, or `go tool trace` for the goroutine timeline                                                                             |
| Python | `py-spy record --idle --format raw -o <label>.folded` — samples waiting threads too, so width = wall time                                                                                                     |
| Any    | macOS `sample` already captures blocked threads, so its flame graph is a wall-clock view. Linux: `perf trace -s -- <cmd>` for time per syscall, `nix shell nixpkgs#bcc` for `offcputime` when you need stacks |

**Memory**

| Target | Instrument                                                                                                                                                                                                                                         |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Go     | `go test -memprofile mem.prof` → `go tool pprof -sample_index=alloc_space -top mem.prof` (`flat` is self, `cum` is total; heap profiles carry four sample columns, so `stackcollapse-go.pl` cannot fold them — use `-http=:0` for the flame graph) |
| Rust   | `dhat` crate, or `nix shell nixpkgs#heaptrack` on Linux                                                                                                                                                                                            |
| Python | `py-spy` does not see allocations — use `tracemalloc` snapshots around the workload                                                                                                                                                                |

**Pipeline**

No sampler applies. Build the timeline from the system that ran it: per-step timestamps from the Actions API for CI, a trace (OpenTelemetry, browser devtools) for a request across services, `nix build --print-build-logs` timestamps or `just --timestamp` for a build graph. Save the table to `.ai/profiles/<label>-before.md`. The visualization rule still applies — the timeline is the picture.

### 4. Capture the Baseline Picture

Before touching the code. For the flame-graph rows:

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

### 5. Read the Picture

The SVG is the user's artifact — interactive in a browser (click to zoom, Ctrl+F to search). You cannot see it, so read the same data as text:

```bash
go run ~/.claude/skills/profile/scripts/hotspots/main.go .ai/profiles/<label>-before.folded
```

It prints the widest frames twice: **self** (the frame is the leaf — where the time actually is) and **total** (frame plus children — what the flame graph draws as width). Thread and loader frames (`Thread_…`, `dyld`) at the top of the total table are scaffolding; the first frame from your own code below them is the story.

- Wide plateaus in _self_ are the hot spots; a frame wide in _total_ but thin in _self_ is a caller, not a cause
- On a CPU graph, search for known-expensive patterns: allocation (`malloc`, `runtime.mallocgc`), serialization, regex, syscalls. On a wall-clock graph, the wide leaves are the waits (`kevent`, `epoll_wait`, `futex`, `read`) — the caller above them is what is waiting
- For a timeline, the widest step is the hot spot; for an allocation profile, the widest allocation site

Report the top hot spots with their percentage width, and the artifact path. This is the evidence for deciding what to change — only now does evaluation start.

### 6. Measure After the Change

Repeat steps 2 and 4 with the exact same workload, flags, and machine conditions, writing `<label>-after.*` files.

### 7. Compare and Report

- **Wall-clock**: `hyperfine` both commands in one invocation for a statistical comparison, or for Go: `benchstat .ai/profiles/<label>-before.txt .ai/profiles/<label>-after.txt` (shows delta with p-value)
- **Differential flame graph**: `difffolded.pl .ai/profiles/<label>-before.folded .ai/profiles/<label>-after.folded | flamegraph.pl > .ai/profiles/<label>-diff.svg` — red = grew, blue = shrank. Run the hotspots script on both folded files to put the same delta in the table.

Report using this structure:

```markdown
## Performance Measurement: <label>

**Workload**: <command / benchmark, input size, build flags; CPU-bound or wait-bound and why>
**Environment**: <machine, OS, notable conditions>

| Metric                             | Before | After | Delta |
| ---------------------------------- | ------ | ----- | ----- |
| wall-clock (mean ± σ)              | ...    | ...   | -XX%  |
| <hot function> (flame graph width) | XX%    | XX%   | ...   |

Flame graphs: .ai/profiles/<label>-{before,after,diff}.svg
```

If the delta is within the noise (overlapping ±σ, or benchstat says ~), say so plainly — "no measurable improvement" is a valid, useful result.

## Pitfalls

- An on-CPU flame graph of a waiting process is all `epoll`/`kevent` and tells you nothing — that is step 2 telling you to switch instruments, not a result
- Comparing a debug build against a release build, or runs on different machine states — the numbers are meaningless
- Single-run timings — always use warmup + repetition; report variance, not just the mean
- Missing symbols (all frames show hex addresses): install debug info / keep symbols in release builds, then re-profile
- On macOS, `perf` does not exist and dtrace needs SIP changes — prefer `sample`, `py-spy`, `cargo flamegraph`, or Instruments
