---
name: test
description: Run tests on the codebase. Use this skill whenever the user asks to run tests, check if tests pass, verify test results, or wants to know the test status of the project. Also use when implementing features (after writing code) to confirm correctness.
---

# Test

Run the test suite to verify functionality.

## Workflow

### 1. Discover Test Command

Investigate available commands by checking project files:

- `flake.nix` / `flake.lock`: Use `nix flake check` or project-specific test commands
- `Makefile` / `justfile`: Look for `test` target
- `package.json`: Check `scripts.test` (use `npm test`, `vitest`, `jest`)
- `go.mod`: Use `go test ./...`
- `Cargo.toml`: Use `cargo test`
- `pyproject.toml` / `setup.py`: Use `pytest` or `python -m unittest`

Prefer project-configured commands over language defaults. If multiple options exist, use the one defined in the project's build configuration.

### 2. Run Tests

- Run the discovered test command
- If the command fails due to missing dependencies, recommend the appropriate setup (e.g., `nix develop`, `npm install`, `go mod download`)
- If no test framework is configured, propose adding one appropriate for the project

### 3. Report and Fix

- Report test results clearly: total, passed, failed, skipped
- Fix any failing tests before proceeding
