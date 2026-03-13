---
name: static-analysis
description: Run static analysis (linting, type checking) on the codebase. Use this skill whenever the user asks to lint code, run type checking, check for code issues, or run clippy/eslint/golangci-lint. Also triggered as part of the verify workflow.
---

# Static Analysis

Run linting and type checking to verify code correctness and quality.

## Workflow

### 1. Discover Lint and Type Check Commands

Investigate available commands by checking project files:

- `flake.nix` / `flake.lock`: Look for check commands (e.g., `nix flake check`)
- `Makefile` / `justfile`: Look for `lint`, `check`, or `typecheck` targets
- `package.json`: Check scripts for lint/typecheck (e.g., `eslint`, `tsc --noEmit`, `biome check`)
- Language-specific tools:
  - Go: `go vet ./...`, `golangci-lint run`
  - Rust: `cargo clippy`
  - Python: `ruff check`, `mypy`, `pyright`

Prefer project-configured commands over language defaults.

### 2. Run Checks

- Run the linting command
- If a separate type checking command exists, run both
- If a command fails due to missing dependencies, recommend the appropriate setup (e.g., `nix develop`, `npm install`)

### 3. Fix Issues

- Fix any errors found before proceeding
- Distinguish between errors (must fix) and warnings (fix if straightforward)
