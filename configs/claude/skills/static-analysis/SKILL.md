---
name: static-analysis
description: Run static analysis (type checking, etc.) on the codebase.
---

# Static Analysis

Run static analysis tools to verify code correctness.

## Steps

1. Detect the project type and find the static analysis command:
   - TypeScript/JavaScript: `tsc --noEmit`, `npx tsc --noEmit`
   - Go: `go vet ./...`
   - Rust: `cargo check`
   - Python: `mypy`, `pyright`
   - Nix: `nix flake check`

2. If no static analysis tool is configured, propose adding one appropriate for the project.

3. Run the command and fix any errors found.
