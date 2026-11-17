---
name: check
description: Run all verification checks (static analysis, tests, formatting) on the codebase. Discovers project-configured commands from build files and runs them in the right order.
when_to_use: Whenever the user asks to verify code quality, run all checks, lint, type check, run tests, format code, or ensure the codebase is clean before committing or deploying — "チェック回して", "lint して", "テスト通る?", "fmt かけて", "CI 通るか見て".
---

# Verify

Run static analysis, tests, and formatters to ensure the codebase is in a clean state.

This skill is the single entry point for all routine quality checks, handling discovery and orchestration in one place.

## Workflow

### 1. Discover Project Commands

Investigate available commands by checking project files in this priority order:

1. **A `check` recipe in the `justfile`** (`just --summary` lists it): run `just check`, the command CI runs in a repository the `baseline` skill set up. Inside the devShell (direnv loaded it, so `$IN_NIX_SHELL` is set) run it as is; otherwise, with a flake, run `nix develop --command just check`. Reach for the other recipes (`fmt`, `test`) only for what `check` leaves out.
2. **`flake.nix` / `flake.lock`** with no `check` recipe: `nix flake check` for analysis+tests and `nix fmt` (treefmt) for formatting. One command covers a multi-language project, but it is slower than `just check` and may test something else, so it stands in only where no recipe exists.
3. **`Makefile` / `justfile`** without `check`: look for `lint`, `typecheck`, `test`, `format`, `fmt` targets.
4. **`package.json`**: check `scripts` for `lint`, `typecheck`, `test`, `format`, plus common tools (`eslint`, `tsc --noEmit`, `vitest`, `jest`, `prettier`, `biome`).
5. **Language-native fallbacks** (when no project-configured command exists):
   - Go: `go vet ./...`, `golangci-lint run`, `go test ./...`, `gofmt -w .` / `goimports -w .`
   - Rust: `cargo clippy`, `cargo test`, `cargo fmt`
   - Python: `ruff check`, `mypy` / `pyright`, `pytest`, `ruff format` / `black .`

**Heavy checks.** Some flakes wire checks into `checks` that build or evaluate a whole system — a host's `system.build.toplevel`, or an `eval-<host>` check that only writes its `drvPath` but still evaluates the host. One of those takes minutes and gigabytes, and several at once can freeze the machine. Tell them from the check names, the module that defines them, and the repository's CLAUDE.md, which may forbid evaluating a host locally. When the command chosen above would run them — `nix flake check` directly, or a `check` recipe that wraps it — run `nix fmt` plus the specific check the change touches (`nix build .#checks.<system>.<name>`) instead, and report which checks you skipped and that CI runs them.

Prefer project-configured commands over language defaults. If a command fails due to missing dependencies, recommend the appropriate setup (`nix develop`, `npm install`, `go mod download`, etc.) rather than falling back to a different tool.

### 2. Run Checks

Run in this order, fixing issues before moving to the next step:

1. **Static analysis** (lint + type check)
2. **Tests** (full suite)
3. **Formatter** (auto-fix style)

Rationale: lint/type errors often surface issues that would otherwise cause confusing test failures; running the formatter last avoids reformatting code that you are about to fix.

If the formatter rewrites files that the current change did not touch, that churn is a structural change — commit it separately (Tidy First) rather than folding it into the behavioral commit, where it hides the real diff from the reviewer.

### 3. Report and Fix

- Report results clearly per step: passed / failed / skipped, with failing test names and lint messages.
- Fix errors before proceeding. Distinguish errors (must fix) from warnings (fix if straightforward).
- Never skip failing tests. Never disable lint rules to pass.
- If no test framework or formatter is configured, propose adding one appropriate for the project rather than silently skipping.
