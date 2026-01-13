---
name: lint
description: Run linter on the codebase.
---

# Lint

Run linting tools to check code style and potential issues.

## Steps

1. Detect the project type and find the lint command:
   - TypeScript/JavaScript: `eslint`, `biome lint`
   - Go: `golangci-lint run`
   - Rust: `cargo clippy`
   - Python: `ruff check`, `flake8`
   - Nix: `statix check`

2. If no linter is configured, propose adding one appropriate for the project.

3. Run the command and fix any issues found.
