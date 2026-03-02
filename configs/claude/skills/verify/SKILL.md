---
name: verify
description: Run all verification checks (static analysis, test, format).
---

# Verify

Run all verification checks to ensure code quality.

## Steps

### 1. Discover Project Commands and Runtime

Before running any checks, identify available CLI commands and the execution environment:

- Investigate available commands by checking project files such as `package.json` (scripts), `Makefile`, `justfile`, `README.md`, `flake.nix`, and any other relevant configuration
- Also consider language-native commands (e.g., `go test`, `cargo test`, `cargo clippy`, `pytest`) based on the detected project type
- Detect the runtime environment from lock files and configuration (e.g., `flake.lock`, `package-lock.json`, `go.sum`, `Cargo.lock`)
- If a command fails on first execution, recommend the appropriate setup (e.g., `nix develop`, `npm install`, `go mod download`)

### 2. Run Checks

Run in this order:

- `static-analysis` skill (linting and type checking)
- `test` skill (run the test suite)
- `format` skill (run code formatters)

### 3. Fix Issues

Fix any issues before proceeding to the next step. Do not go back to completed steps.
