---
name: design
description: Architecture and design consultation for new applications and features. Use this skill when discussing system architecture, design patterns, tech stack decisions, API design, or module structure — including phrasings like "設計相談", "アーキテクチャどうする", "技術選定", "構成を考えたい". Covers Unix/Linux Philosophy for CLI tools and Twelve-Factor App for web applications and microservices. For reshaping code that already exists, the refactor skill has the migration patterns.
---

# Design Consultation

The two checklists below are not rules; they are the accumulated answers to "what makes this kind of program pleasant to operate". A CLI that writes diagnostics to stdout breaks the next pipe; a web process that keeps session state can't be restarted or scaled. Use them to notice what a proposed design will cost later, then recommend the simpler option.

## Workflow

1. **Identify the application type** and the matching design philosophy:
   - CLI tools, scripts, system utilities → Unix/Linux Philosophy
   - Web applications, APIs, microservices → The Twelve-Factor App
   - Libraries, shared modules → both (Unix for API design, Twelve-Factor for deployment)
2. **Apply the checklist** for the identified type. Raise concerns where the current design violates principles.
3. **Provide recommendations** with rationale. When trade-offs exist, explain the pros/cons and recommend the simpler option.

## Unix/Linux Philosophy Checklist

- [ ] Single responsibility per module/function ("do one thing well")
- [ ] Composable via standard I/O — stdout for output, stderr for diagnostics
- [ ] Meaningful exit codes (0=success, non-zero=error); fail fast with clear messages
- [ ] Explicit over implicit behavior; safe defaults, flags required for dangerous operations
- [ ] No hidden side effects

## Twelve-Factor App Checklist

- [ ] No hardcoded config — store config in environment variables
- [ ] Dependencies explicitly declared in a manifest (package.json, go.mod, etc.)
- [ ] Stateless processes (no local session state); scale out via the process model
- [ ] Logs to stdout as event streams (no local log files)
- [ ] Fast startup and graceful shutdown; health check endpoints
- [ ] Dev/prod parity; admin tasks as one-off processes
