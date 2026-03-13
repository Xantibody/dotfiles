---
name: format
description: Run code formatter on the codebase. Use this skill whenever the user asks to format code, fix code style, run prettier/biome/gofmt, or wants to ensure consistent code formatting. Also triggered as part of the verify workflow.
---

# Format

Run code formatters to automatically fix code style.

## Workflow

### 1. Discover Format Command

Investigate available commands by checking project files in priority order:

1. `flake.nix` with treefmt: Use `nix fmt` (preferred for multi-language projects as it handles all formatters)
2. `Makefile` / `justfile`: Look for `format` or `fmt` target
3. Language-specific formatters:
   - TypeScript/JavaScript: `prettier --write .`, `biome format --write .`
   - Go: `gofmt -w .`, `goimports -w .`
   - Rust: `cargo fmt`
   - Python: `black .`, `ruff format .`

### 2. Run Formatter

- Run the discovered format command
- If the command fails due to missing dependencies, recommend the appropriate setup (e.g., `nix develop`, `npm install`)
- If no formatter is configured, propose adding one appropriate for the project
