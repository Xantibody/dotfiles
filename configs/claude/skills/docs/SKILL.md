---
name: docs
description: Automated documentation and technical writing. Use this skill when the user wants to create, update, or audit documentation — including README, /docs directory, and inline code comments. Also use when adding a new module, after refactoring, or when the user mentions "docs", "documentation", "README", or "comments need updating". This skill both analyzes and executes documentation changes.
---

# Docs

Maintain a world-class documentation structure inspired by high-star, modern OSS projects. Ensure seamless synchronization between the codebase, inline comments, and the `/docs` directory.

## Core Principle: Single Source of Truth

Documentation must stay in sync with code. When code changes, all impacted documentation — inline comments, module docs, and top-level indexes — must be identified and updated together. Stale docs are worse than no docs.

## Documentation Structure

### Root `README.md` — The Storefront

The project's front door. It should contain:

- **Value proposition**: What this project does and why it exists (1-2 sentences)
- **Quick Start**: Minimal steps to get running
- **Table of contents**: Links into `/docs` for deeper reading
- **Badges** (optional): CI status, version, license

> [!IMPORTANT]
> README must be scannable in under 30 seconds. If it's longer than 2 screens, move detail into `/docs`.

### `docs/introduction.md` — The Map

Technical summary and orientation guide:

- Architecture overview (use Mermaid diagrams where they clarify structure)
- Key design decisions and their rationale
- Module index with one-line descriptions linking to detail pages
- Glossary of domain-specific terms (if applicable)

### `docs/modules/*.md` or `docs/reference/*.md` — The Deep Dives

Detailed technical documentation per component:

- Purpose and responsibility of the module
- Public API / interface description
- Internal logic walkthrough for complex parts
- Dependencies and interactions with other modules
- Examples and edge cases

## Inline Code Comments

Comments explain **why**, not **what**. The code itself should be readable enough to explain what it does.

### Rules

- **Why comments**: Explain non-obvious decisions, workarounds, constraints, and business rules
- **No narration**: Do not restate what the code does (`// increment counter` on `counter++`)
- **Link to docs**: For complex business logic, add a brief inline comment and reference the relevant doc (`// See docs/modules/billing.md for rate calculation details`)
- **TODO/FIXME**: Use sparingly. Include a reason and ideally a tracking reference

### Format by Language

- **Go**: Follow standard Go doc comment conventions (`// FunctionName does X`)
- **TypeScript/JavaScript**: Use JSDoc for public APIs, plain `//` for internal comments
- **Other languages**: Follow the language's idiomatic comment style

## Workflow

### 1. Audit Current State

Read the codebase and existing documentation:

- Does a `/docs` directory exist? What's in it?
- Is there a `README.md`? How complete is it?
- What's the inline comment density and quality?
- Are there orphaned docs (referencing code that no longer exists)?
- Are there undocumented modules or complex logic?

Present a summary of gaps to the user.

### 2. Plan Documentation Changes

Based on the audit, determine what needs to be created or updated:

- **New docs**: Modules or concepts with no documentation
- **Stale docs**: Documentation that doesn't match current code
- **Missing structure**: If `/docs` directory doesn't follow the storefront/map/deep-dive pattern
- **Comment gaps**: Complex logic without "why" comments

### 3. Execute Changes

For each documentation change:

- **New module added**: Create `docs/modules/<module-name>.md` and update `docs/introduction.md` index
- **Code refactored**: Identify all impacted docs and update them
- **New feature**: Add inline "why" comments for non-obvious logic, create or update relevant module doc
- **Structure missing**: Set up the directory structure and populate with initial content

### 4. Formatting Standards

All documentation must follow:

- **GitHub Flavored Markdown (GFM)**
- **Callouts** for key information:
  - `> [!NOTE]` — Helpful context
  - `> [!TIP]` — Best practices
  - `> [!IMPORTANT]` — Critical information
  - `> [!WARNING]` — Potential issues
  - `> [!CAUTION]` — Dangerous actions
- **Mermaid diagrams** for architecture and flow visualization (only when they add clarity)
- **Concise English** for technical references — short sentences, active voice
- **Code blocks** with language identifiers for all code examples

### 5. Verify

- All links in docs resolve to existing files or sections
- Module docs match actual module structure
- `docs/introduction.md` index is complete and up-to-date
- No orphaned documentation referencing removed code

## What This Skill Does NOT Do

- **Rewrite code for readability**: Improving code itself is `/refactor`'s job. This skill adds comments and docs around existing code.
- **Generate API docs from code**: Use language-specific tools (godoc, typedoc) for that. This skill writes conceptual and architectural documentation.
