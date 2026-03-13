---
name: design
description: Architecture and design consultation for applications. Use this skill when discussing system architecture, design patterns, tech stack decisions, API design, or module structure. Covers Unix/Linux Philosophy for CLI tools and Twelve-Factor App for web applications and microservices.
---

# Design Consultation

Use this skill when discussing architecture, design patterns, or system structure.

## Workflow

### 1. Identify the Application Type

Determine which design philosophy to apply based on the project:

- **CLI tools, scripts, system utilities** → Unix/Linux Philosophy
- **Web applications, APIs, microservices** → Twelve-Factor App
- **Libraries, shared modules** → Both (Unix for API design, Twelve-Factor for deployment)

### 2. Apply the Relevant Principles

Consult the checklist for the identified type. Raise concerns where the current design violates principles.

### 3. Provide Recommendations

Present design recommendations with rationale. When trade-offs exist, explain the pros/cons and recommend the simpler option.

## Unix/Linux Philosophy (for CLI tools and system architecture)

### Core Principles

1. **Do one thing well** - Each program/function should have a single purpose
2. **Compose with others** - Design for pipelines and composition
3. **Text streams** - Use text as universal interface
4. **Small, sharp tools** - Prefer focused tools over monolithic solutions
5. **Fail fast, fail loudly** - Exit on error with clear messages

### Design Guidelines

- Prefer explicit over implicit behavior
- Make default behavior safe; require flags for dangerous operations
- Support stdin/stdout for composition
- Use exit codes meaningfully (0=success, non-zero=error)
- Write to stderr for diagnostics, stdout for output

### Checklist

- [ ] Single responsibility per module/function
- [ ] Composable via standard I/O
- [ ] Clear error messages to stderr
- [ ] Meaningful exit codes
- [ ] No hidden side effects

## The Twelve-Factor App (for web applications and microservices)

### Factors

| #    | Factor              | Principle                                    |
| ---- | ------------------- | -------------------------------------------- |
| I    | Codebase            | One codebase tracked in VCS, many deploys    |
| II   | Dependencies        | Explicitly declare and isolate dependencies  |
| III  | Config              | Store config in environment variables        |
| IV   | Backing services    | Treat backing services as attached resources |
| V    | Build, release, run | Strictly separate build and run stages       |
| VI   | Processes           | Execute app as stateless processes           |
| VII  | Port binding        | Export services via port binding             |
| VIII | Concurrency         | Scale out via the process model              |
| IX   | Disposability       | Fast startup and graceful shutdown           |
| X    | Dev/prod parity     | Keep development and production similar      |
| XI   | Logs                | Treat logs as event streams                  |
| XII  | Admin processes     | Run admin tasks as one-off processes         |

### Checklist

- [ ] No hardcoded config (use env vars)
- [ ] Dependencies in manifest (package.json, go.mod, etc.)
- [ ] Stateless processes (no local session state)
- [ ] Logs to stdout (no local log files)
- [ ] Graceful shutdown handling
- [ ] Health check endpoints
