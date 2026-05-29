---
name: verify
description: Run all verification checks (static analysis, tests, formatting) on the codebase. Use this skill whenever the user asks to verify code quality, run all checks, lint, type check, run tests, format code, or ensure the codebase is clean before committing or deploying. Discovers project-configured commands from build files and runs them in the right order.
---

# Verify

Run static analysis, tests, and formatters to ensure the codebase is in a clean state.

This skill is the single entry point for all routine quality checks. It supersedes separate `test`, `format`, and `static-analysis` skills by handling discovery and orchestration in one place.

## Workflow

### 1. Discover Project Commands

Investigate available commands by checking project files in this priority order:

1. **`flake.nix` / `flake.lock`**: prefer `nix flake check` for analysis+tests and `nix fmt` (treefmt) for formatting. Single command covers multi-language projects.
2. **`Makefile` / `justfile`**: look for `lint`, `check`, `typecheck`, `test`, `format`, `fmt` targets.
3. **`package.json`**: check `scripts` for `lint`, `typecheck`, `test`, `format`, plus common tools (`eslint`, `tsc --noEmit`, `vitest`, `jest`, `prettier`, `biome`).
4. **Language-native fallbacks** (when no project-configured command exists):
   - Go: `go vet ./...`, `golangci-lint run`, `go test ./...`, `gofmt -w .` / `goimports -w .`
   - Rust: `cargo clippy`, `cargo test`, `cargo fmt`
   - Python: `ruff check`, `mypy` / `pyright`, `pytest`, `ruff format` / `black .`

Prefer project-configured commands over language defaults. If a command fails due to missing dependencies, recommend the appropriate setup (`nix develop`, `npm install`, `go mod download`, etc.) rather than falling back to a different tool.

### 2. Run Checks

Run in this order, fixing issues before moving to the next step:

1. **Static analysis** (lint + type check)
2. **Tests** (full suite)
3. **Formatter** (auto-fix style)

Rationale: lint/type errors often surface issues that would otherwise cause confusing test failures; running the formatter last avoids reformatting code that you are about to fix.

### 3. Report and Fix

- Report results clearly per step: passed / failed / skipped, with failing test names and lint messages.
- Fix errors before proceeding. Distinguish errors (must fix) from warnings (fix if straightforward).
- Never skip failing tests. Never disable lint rules to pass.
- If no test framework or formatter is configured, propose adding one appropriate for the project rather than silently skipping.
