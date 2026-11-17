# Go

Read this when the repository has a `go.mod`. Versions below are what
nixos-unstable carried on 2026-11-17: Go 1.27, golangci-lint 2.15.0, gofumpt
0.12.0.

## Survey

Look for these before changing anything, and keep what exists:

| Found                                                         | Do                                                                                                                                                                  |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.golangci.yml` without `version: "2"`                        | `golangci-lint migrate` in its own commit, then merge the baseline below into it                                                                                    |
| `.golangci.yml` v2                                            | Keep every linter and setting it has; add the missing baseline linters and settings on top. Never drop a linter the repo enabled                                    |
| `formatters:` in `.golangci.yml`                              | See Formatting: move them to treefmt, or keep golangci-lint as the one formatter                                                                                    |
| Makefile / scripts running `go test`, `go vet`, `staticcheck` | Fold their flags into the just recipes; delete the old target only when the recipe covers it                                                                        |
| `golangci/golangci-lint-action` in CI                         | Replace with `just check` in the devShell (CI step); one version, from `flake.lock`                                                                                 |
| `go.work` or several `go.mod`                                 | Run each recipe once per module (`for m in $(go list -m -f '{{.Dir}}')`; inside a justfile write `{{{{.Dir}}`); golangci-lint and `./...` stop at a module boundary |

## devShell

| Package       | nixpkgs attribute                         | Note                                                                               |
| ------------- | ----------------------------------------- | ---------------------------------------------------------------------------------- |
| Go            | `go` (= `go_1_27`); `go_1_26` also exists | Only the two supported releases are packaged. Use `go` unless `go.mod` needs older |
| golangci-lint | `golangci-lint`                           | Built with `buildGo127Module`; take it from the same nixpkgs as `go`               |
| gopls         | `gopls`                                   | Optional, for editors                                                              |
| gofumpt       | `gofumpt`                                 | Comes in through `config.treefmt.build.devShell`; do not list it again             |

Verified at https://github.com/NixOS/nixpkgs/tree/nixos-unstable/pkgs/by-name/go
and `pkgs/top-level/all-packages.nix` (`go = go_1_27`, `go_latest = go_1_27`).

```nix
devShells.default = pkgs.mkShell {
  inputsFrom = [ config.treefmt.build.devShell ];
  packages = [ pkgs.go pkgs.golangci-lint pkgs.gopls pkgs.just ];
  # Use the Go from nixpkgs. Without this, a newer `go`/`toolchain` line in
  # go.mod makes the go command download a toolchain outside Nix.
  GOTOOLCHAIN = "local";
};
```

With `GOTOOLCHAIN=local` the go command "always runs the bundled Go
toolchain" (https://go.dev/doc/toolchain), so a `go.mod` newer than nixpkgs
fails loudly instead of silently fetching. Fix that by updating `flake.lock`,
not by unsetting the variable.

`go test -race` needs a host C toolchain on Linux (not on macOS since Go 1.20,
https://go.dev/doc/go1.20). `mkShell` provides the stdenv compiler; do not set
`CGO_ENABLED=0` in the shell.

## Formatting: treefmt owns it

Pick one formatter writer. Default: **gofumpt via treefmt-nix, and no
`formatters:` section in `.golangci.yml`.**

```nix
treefmt.programs.gofumpt.enable = true;
```

Why:

- `nix fmt` is the single writer for every language, and `treefmt --ci`
  (`just fmt-check`) is the single format gate.
- golangci-lint vendors its own gofumpt. If both run, a version skew between
  the vendored copy and `pkgs.gofumpt` makes `nix fmt` and `golangci-lint run`
  disagree. `golangci-lint run` "executes enabled linters, and the formatters
  defined in `formatters`" (https://golangci-lint.run/docs/configuration/cli/),
  so leaving `formatters:` empty keeps it out of formatting.
- gofumpt is stricter than gofmt and "running `gofmt` after `gofumpt` should
  produce no changes" (https://github.com/mvdan/gofumpt). Leave
  `programs.gofumpt.extra` off (it adds `-extra`); its extra rules (group
  same-type params, no naked returns, balanced multi-line calls) are taste, not
  correctness.
- Do not use treefmt-nix `programs.golangci-lint`: it runs `golangci-lint run
  --fix` on the file list treefmt passes, which puts a linter in the formatter
  slot and lints file batches instead of packages
  (https://github.com/numtide/treefmt-nix/blob/main/programs/golangci-lint.nix).

Exception: the repo already uses `gci` or `golines` through golangci-lint
(treefmt-nix has no `gci` program). Then keep golangci-lint as the only Go
formatter and call it from treefmt, so there is still one writer and one
version (`golangci-lint fmt` takes file or directory arguments and uses the
`formatters:` section, per `pkg/commands/fmt.go` at v2.15.0):

```nix
treefmt.settings.formatter.golangci-lint-fmt = {
  command = "${pkgs.golangci-lint}/bin/golangci-lint";
  options = [ "fmt" ];
  includes = [ "*.go" ];
};
```

Mature repo: switching gofmt to gofumpt reformats many files. Do it in one
`style(go): format with gofumpt` commit and add its SHA to
`.git-blame-ignore-revs`. No ratchet for formatting.

## `.golangci.yml`

Schema: https://golangci-lint.run/docs/configuration/file/ and the full
reference https://github.com/golangci/golangci-lint/blob/v2.15.0/.golangci.reference.yml.
`linters.default: standard` is errcheck, govet, ineffassign, staticcheck,
unused. The list below is explicit rather than `default: all` so a
golangci-lint bump in `flake.lock` never adds a linter without a commit that
says so.

```yaml
version: "2"

linters:
  default: standard
  enable:
    # Suppressions and boundaries
    - nolintlint
    - depguard
    - forbidigo
    # Errors
    - errorlint
    - errname
    - errchkjson
    - nilerr
    - nilnesserr
    - nilnil
    # Correctness
    - asasalint
    - bidichk
    - bodyclose
    - containedctx
    - contextcheck
    - durationcheck
    - exhaustive
    - fatcontext
    - forcetypeassert
    - gochecknoinits
    - gochecksumtype
    - gocheckcompilerdirectives
    - gosec
    - makezero
    - musttag
    - noctx
    - predeclared
    - reassign
    - recvcheck
    - rowserrcheck
    - sqlclosecheck
    - spancheck
    - sloglint
    - loggercheck
    # Modern, simple code
    - copyloopvar
    - exptostd
    - intrange
    - modernize
    - usestdlibvars
    - unconvert
    - unparam
    - wastedassign
    - mirror
    - perfsprint
    - gocritic
    - revive
    - gocognit
    - misspell
    - dupword
    - goprintffuncname
    - gomoddirectives
    # Tests
    - testifylint
    - thelper
    - tparallel
    - usetesting

  settings:
    nolintlint:
      allow-unused: false
      require-explanation: true
      require-specific: true
    errcheck:
      check-type-assertions: true
      check-blank: true
    govet:
      enable-all: true
      disable:
        - fieldalignment # struct layout churn, no correctness value
        - shadow         # flags every idiomatic `err` re-declaration
    staticcheck:
      # Same as golangci-lint's default, written out so it is visible. The
      # dropped checks duplicate revive default rules: ST1000 package-comments,
      # ST1003 var-naming, ST1016 receiver-naming, ST1020-22 exported.
      checks: ["all", "-ST1000", "-ST1003", "-ST1016", "-ST1020", "-ST1021", "-ST1022"]
    gosec:
      config:
        global:
          nosec: true # ignore `#nosec`; the only off switch is //nolint:gosec with a HACK
    revive:
      enable-default-rules: true
      directives:
        - name: specify-disable-reason
          severity: error
        - name: specify-disable-rule
          severity: error
      rules:
        - name: deep-exit          # os.Exit / log.Fatal only in main and init
        - name: use-any
        - name: unconditional-recursion
        - name: identical-branches
        - name: modifies-value-receiver
        - name: datarace
        - name: redundant-import-alias
        - name: early-return
        - name: bare-return
    gocritic:
      enabled-tags: [diagnostic, style, performance]
      disabled-checks:
        - whyNoLint # nolintlint already requires the reason
    gocognit:
      min-complexity: 20
    exhaustive:
      check: [switch, map]
      default-signifies-exhaustive: false
    usetesting:
      os-temp-dir: true
      context-background: true
      context-todo: true
    testifylint:
      enable-all: true
    forbidigo:
      analyze-types: true
      forbid:
        - pattern: ^print(ln)?$
          msg: use log/slog, or fmt.Fprint to an io.Writer the caller passes in
        - pattern: ^fmt\.Print(f|ln)?$
          msg: write to an io.Writer the caller passes in (fmt.Fprintln(w, ...)) or use log/slog
        - pattern: ^log\.(Print|Fatal|Panic)(f|ln)?$
          msg: use a *slog.Logger the caller passes in; return errors instead of Fatal/Panic
    depguard:
      rules:
        # Without any rule depguard allows only the standard library. Keep at
        # least this one.
        replaced:
          list-mode: lax
          deny:
            - pkg: "math/rand$"
              desc: use math/rand/v2, or crypto/rand for anything secret
            - pkg: "io/ioutil"
              desc: use io and os
            - pkg: "github.com/pkg/errors"
              desc: use errors and fmt.Errorf("...: %w", err)
        # Boundary template: edit paths to the repo's layout or delete.
        # `files` globs match the file's absolute path, so keep the `**/` prefix.
        # use-cases:
        #   files: ["**/internal/jobs/**"]
        #   deny:
        #     - pkg: "github.com/aws/aws-sdk-go-v2"
        #       desc: jobs call the port in internal/state.go; S3 code lives in internal/lib/s3

  exclusions:
    generated: strict
    warn-unused: true
    presets:
      - std-error-handling # unchecked Close/Flush/Remove/Setenv/print
    # Every rule added here needs `# HACK(<issue URL>): why` above it.
    rules: []

issues:
  max-issues-per-linter: 0
  max-same-issues: 0
```

Choices an agent may be asked about:

- `check-blank: true` closes `_ = f()`; `std-error-handling` keeps
  `defer f.Close()` on read paths from becoming boilerplate.
- `exhaustive` with `default-signifies-exhaustive: false`: a `default:` does not
  excuse a missing enum case, so a new constant breaks every switch that
  forgot it.
- Not enabled, on purpose: `exhaustruct`, `varnamelen`, `wsl`/`wsl_v5`,
  `nlreturn`, `lll`, `mnd`, `funlen`, `err113`, `wrapcheck`, `ireturn`,
  `gochecknoglobals`, `testpackage`, `paralleltest`, `nonamedreturns`,
  `noinlineerr`, `godox`. They are noise or style a formatter already decides;
  noisy linters train agents to suppress. A repo that already enables any of
  them keeps it.
- Structure beats lint: a package that only its parent may import goes under
  `internal/` (the compiler enforces it). Use depguard only for what
  `internal/` cannot express, such as "use cases do not import cloud SDKs".
- `depguard` `desc` and `forbidigo` `msg` are the error the agent reads: always
  name the replacement, never just "not allowed".
- revive's default rules include `exported` and `package-comments`, so every
  exported identifier and package needs a doc comment. If the repo does not
  want that, add the `comments` exclusion preset and record why in an ADR.
- `golangci-lint config verify` checks the file against the JSON schema
  embedded in the binary (no network; `pkg/commands/config_verify.go`).
  UNVERIFIED: that `run` ignores unknown keys silently; run `config verify`
  regardless.

## Escape hatches

| Hatch                                | Rule                                                                                                                                                                                                                                        |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `//nolint:<linter>`                  | Allowed only as `//nolint:errcheck // HACK(https://…/issues/N): why`. nolintlint rejects a bare `//nolint`, `//nolint:all`, a missing reason and an unused directive                                                                        |
| `//revive:disable`                   | Same form (`//revive:disable-next-line:<rule> HACK(…): why`); revive's `specify-disable-rule` and `specify-disable-reason` reject it without a rule or a reason                                                                             |
| `#nosec`                             | Ignored (`gosec.config.global.nosec: true`); use `//nolint:gosec // HACK(…)`                                                                                                                                                                |
| `//lint:ignore`                      | staticcheck-only syntax; not honored by golangci-lint (https://github.com/golangci/golangci-lint/issues/1658, open). Forbid                                                                                                                 |
| `linters.exclusions.rules` / `paths` | Comment `# HACK(<issue URL>)` above each; `warn-unused` reports stale ones                                                                                                                                                                  |
| `t.Skip(`, `t.Skipf(`, `t.SkipNow(`  | Only with `// HACK(https://…/issues/N): <environment>` on the line directly above, and only for a test the environment cannot run (an OS, an outside service). A flaky test is fixed or deleted, never skipped. Enforced by `lint-go-tests` |
| `time.Sleep(` in `_test.go`          | Same HACK rule, also `lint-go-tests`. Wait on a channel or a condition, or use `testing/synctest` for code that waits on timers                                                                                                             |

nolintlint only demands _a_ reason. The HACK URL is enforced by
`lint-go-suppressions` below, which looks only at added lines when ratcheting,
so old `//nolint`s in a mature repo do not fail the build until touched.
`lint-go-tests` does the same for skips and sleeps in tests. A slow test leaves
`check` through a build tag (`//go:build slow`, run by `test-slow` with
`-tags slow`), not through `t.Skip`.

## Ratchet (mature repo)

Run `golangci-lint run ./...` once. If it is clean, use the plain recipe.
Otherwise use the ratchet recipe, record the decision in an ADR, and file
one issue for burning down the backlog. Do not mass-fix or mass-`//nolint`.

v2 keys (config `issues.*`, same names as CLI flags):
`new`, `new-from-merge-base`, `new-from-rev`, `new-from-patch`, `whole-files`
(requires `new-from-rev` or `new-from-patch`). Pass the base as a flag, not in
`.golangci.yml`, so the config file stays the full rule set.

- Use `--new-from-rev=<sha>`. Avoid `--new`: the docs warn it "can skip
  linting the current patch if any scripts generate unstaged files"
  (`golangci-lint run --help`, mirrored in
  https://github.com/golangci/golangci-lint/blob/v2.15.0/docs/data/cli_help.json).
- Base: `LINT_BASE` from CI, else the merge-base with `origin/<default>`. On the
  default branch locally that is the last fetched remote tip, so unpushed
  commits and uncommitted changes are linted (`--new-from-rev` diffs the rev
  against the working tree).
- CI must check out full history (`actions/checkout` with `fetch-depth: 0`) and
  set `LINT_BASE`: `github.event.pull_request.base.sha` on `pull_request`,
  `github.event.before` on `push`. `assets/check.yml` does both.
- `--whole-files` (boy-scout: any issue in a touched file) is opt-in, not the
  default.
- The ratchet covers lint only. Formatting, build, `go mod tidy -diff` and tests
  must pass on the whole tree.

## just recipes

The core `check` recipe calls these. `lint` and `typecheck` in the core list
include the Go ones.

```just
default_branch := "main"

# Lint Go: golangci-lint plus the HACK rule for suppressions and test markers
lint-go: lint-go-suppressions lint-go-tests (lint-comments "//" "*.go")
    golangci-lint config verify
    golangci-lint run ./...

# Every //nolint and //revive:disable must name the issue that removes it
lint-go-suppressions:
    #!/usr/bin/env bash
    set -euo pipefail
    hatch='//(nolint|revive:disable|lint:ignore)|#nosec'
    found=$(git grep -n -E "$hatch" -- '*.go' || true)
    bad=$(printf '%s\n' "$found" | grep -E "$hatch" | grep -v -E 'HACK\(https?://[^)]+\)' || true)
    if [ -n "$bad" ]; then
        printf '%s\n' "$bad"
        echo 'Fix the code instead. If you cannot, write //nolint:<linter> // HACK(<issue URL>): <why>'
        exit 1
    fi

# t.Skip and time.Sleep in tests need a HACK(<issue URL>) on the line above
lint-go-tests:
    #!/usr/bin/env bash
    set -euo pipefail
    # Diffing against the empty tree checks every line of every tracked test file.
    base=$(git hash-object -t tree /dev/null)
    bad=$(git diff -U1 "$base" -- '*_test.go' | awk '
        /^\+\+\+ / { file = substr($0, 7); next }
        /^@@/ { prev = ""; next }
        /^-/ { next }
        { line = substr($0, 2) }
        /^\+/ && line ~ /\.Skip(f|Now)?\(|time\.Sleep\(/ && prev !~ /HACK\(https?:\/\/[^)]+\)/ { print file ": " line }
        { prev = line }')
    if [ -n "$bad" ]; then
        printf '%s\n' "$bad"
        echo 'A flaky test is fixed or deleted, never skipped or slept on. Wait on a channel or use testing/synctest instead of time.Sleep. A test the environment cannot run: // HACK(<issue URL>): <environment> on the line above.'
        exit 1
    fi

# Compile everything and keep go.mod / go.sum tidy
typecheck-go:
    go build ./...
    go mod tidy -diff

# Run tests with the race detector, in random order
test-go:
    go test -race -shuffle=on ./...

# Coverage report; not part of check
cover-go:
    go test -race -shuffle=on -covermode=atomic -coverprofile=coverage.out ./...
    go tool cover -func=coverage.out | tail -n 1
```

Ratchet variant (replace `lint-go` and `lint-go-suppressions`, and in
`lint-go-tests` replace the `base=` line with the `base=` line below so it
looks only at added lines; the `-U1` context still shows the line above an
added one):

```just
# Lint only what changed since LINT_BASE (CI) or the merge-base (local)
lint-go: lint-go-tests (lint-comments "//" "*.go")
    #!/usr/bin/env bash
    set -euo pipefail
    base="${LINT_BASE:-$(git merge-base HEAD origin/{{ default_branch }})}"
    golangci-lint config verify
    golangci-lint run --new-from-rev="$base" ./...
    hatch='//(nolint|revive:disable|lint:ignore)|#nosec'
    bad=$(git diff -U0 "$base" -- '*.go' | grep -E "^\+.*($hatch)" | grep -v -E 'HACK\(https?://[^)]+\)' || true)
    if [ -n "$bad" ]; then
        printf '%s\n' "$bad"
        echo 'Fix the code instead. If you cannot, write //nolint:<linter> // HACK(<issue URL>): <why>'
        exit 1
    fi
```

Notes:

- No separate `go vet`: `govet` with `enable-all` inside golangci-lint covers
  it and is ratchetable, and `go test` already runs vet's high-confidence
  subset (atomic, bools, buildtag, directive, errorsas, ifaceassert, nilfunc,
  printf, stdversion, stringintconv, tests) on every package
  (https://pkg.go.dev/cmd/go#hdr-Test_packages).
- `-shuffle=on` randomizes test order and prints the seed; rerun a failure
  with `-shuffle=<seed>` (https://pkg.go.dev/cmd/go#hdr-Testing_flags).
- Property tests: a standard fuzz target (`func FuzzX(f *testing.F)`) asserting
  the invariant. Without `-fuzz`, `go test` runs it on its seed corpus
  (`f.Add` and `testdata/fuzz/`) like any test, so `test-go` covers it and no
  recipe is added; commit the `testdata/fuzz/` file a fuzzing run writes for
  a failure. When the input needs a generator the fuzzer's primitive
  arguments cannot express (a struct, a sequence of operations), use
  `pgregory.net/rapid` in an ordinary test, which generates inputs on every
  `go test` run. Not `testing/quick`: it is frozen, and fuzzing does its job.
  A long `-fuzz` run is not part of `check`.
- `go mod tidy -diff` (Go 1.23+) prints the diff and exits non-zero instead of
  writing (https://go.dev/doc/go1.23#go-command).
- `just` `env(key, default)` exists since 1.15 if a recipe needs it in an
  expression (https://just.systems/man/en/functions.html); the recipes above
  read `LINT_BASE` in bash instead.

## Sources

- golangci-lint v2.15.0 release: https://github.com/golangci/golangci-lint/releases/tag/v2.15.0
- Config file: https://golangci-lint.run/docs/configuration/file/
- Reference config: https://github.com/golangci/golangci-lint/blob/v2.15.0/.golangci.reference.yml
- CLI (run vs fmt, `config verify`, `migrate`): https://golangci-lint.run/docs/configuration/cli/
- nolint syntax: https://golangci-lint.run/docs/linters/false-positives/
- treefmt-nix Go programs: https://github.com/numtide/treefmt-nix/tree/main/programs
- nixpkgs: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/go/golangci-lint/package.nix
- Go toolchain selection: https://go.dev/doc/toolchain
- Go fuzzing (seed corpus run by plain `go test`): https://go.dev/doc/security/fuzz/ ; `testing/quick` frozen: https://pkg.go.dev/testing/quick
- rapid: https://pkg.go.dev/pgregory.net/rapid
