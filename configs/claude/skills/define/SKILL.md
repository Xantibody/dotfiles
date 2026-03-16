---
name: define
description: Requirements definition before implementation. Use this skill when the user asks to define requirements, clarify specifications, plan what to build, or wants to understand technical constraints before coding. Also use when the user says "define", "requirements", "what should we build", or wants a technical spec. This skill is read-only and never modifies files.
---

# Requirements Definition

Conduct detailed requirements definition before implementation, clarifying technical constraints, design policies, and specifications.

This skill is strictly **read-only** — never modify, create, or delete files. The goal is to produce a clear requirements document and task breakdown that can be handed off to `/execute-plan` or `/implement`.

## Core Rules

- Never modify, create, or delete files
- Never implement code; requirements definition only
- Clearly identify technically impossible requests
- Prioritize technical validity over user preferences — technical evidence over speculation
- Ask questions without limit until requirements are clear
- Always include a (Recommended) option when presenting choices via AskUserQuestion

## Workflow

### 1. Prepare

Gather context from the existing codebase and tools:

- If LSP tools are available (e.g., Serena MCP), activate the project and check for relevant patterns or memories
- If Context7 MCP is available, look up documentation for relevant libraries
- Read existing code patterns, configuration, and architecture to understand the current state

### 2. Analyze

Parse the user's request and identify what needs clarification:

- Extract core requirements from the request
- Identify technical constraints from the codebase context
- Determine design decisions that require user input
- Assess technical feasibility at a high level

### 3. Investigate

Delegate investigations to sub-agents in parallel where possible:

- **Explore agent**: Find relevant files, existing patterns, and code conventions
- **Design agent**: Evaluate architecture consistency and dependency impact (use `design` skill principles — Unix Philosophy for CLI, Twelve-Factor for web apps)
- **General-purpose agent**: Analyze requirements scope and estimate effort

All sub-agents must be read-only — no file modifications.

After investigation, reflect on completeness:

- Have all relevant files and patterns been identified?
- Is the scope clearly understood?
- Are there any technical blockers?

If gaps remain, expand the investigation scope or ask the user.

### 4. Clarify

Resolve ambiguities through structured interaction. Score each question on four dimensions (1-5 each):

| Dimension                   | What it measures                                           |
| --------------------------- | ---------------------------------------------------------- |
| Design branching            | How many implementation paths does this decision create?   |
| Irreversibility             | How costly is it to change this decision later?            |
| Investigation impossibility | Can this be answered by reading code, or only by the user? |
| Effort impact               | How much does this change the implementation effort?       |

Rules for clarification:

- Present high-score questions first
- Use AskUserQuestion tool for all interactions (2-4 structured options per question)
- Do not proceed without clear answers to high-score questions
- Classify questions by type: spec confirmation, design choice, constraint, scope, priority

### 5. Verify

Validate the user's decisions against technical evidence:

- Cross-reference user choices with codebase findings from the investigation phase
- Check that the chosen approach is consistent with existing architecture patterns
- Identify any conflicts between user decisions and technical constraints
- If conflicts are found, present them to the user with evidence and alternatives

### 6. Document

Create the requirements document and task breakdown.

#### Requirements Document Template

```markdown
## Summary

(One-sentence description of the request, background context, and expected outcomes)

## Current State

(Existing system overview, relevant tech stack, and current behavior)

## Functional Requirements

| ID     | Requirement | Priority  |
| ------ | ----------- | --------- |
| FR-001 | ...         | Mandatory |
| FR-002 | ...         | Optional  |

## Non-Functional Requirements

(Performance targets, security considerations, maintainability expectations)

## Technical Specifications

- Design policies and architectural decisions made
- Impact scope (files, modules, APIs affected)
- Key technical decisions with rationale

## Constraints

- Technical constraints (language, framework, compatibility)
- Operational constraints (deployment, infrastructure)

## Test Requirements

- Acceptance criteria for each functional requirement
- Key test scenarios (unit, integration)
- Edge cases identified during analysis

## Outstanding Issues

(Unresolved questions or deferred decisions)
```

#### Task Breakdown

Break down the implementation into phases suitable for `/execute-plan` handoff:

- Dependency graph showing task ordering
- Each phase lists: target files, overview, dependencies, and estimated complexity
- Include decisions made, references gathered, and constraints to respect

## Quality Checks

Before finalizing, verify the requirements document against these criteria:

| Factor                | Weight | What to check                                     |
| --------------------- | ------ | ------------------------------------------------- |
| Requirement clarity   | 40%    | All requirements documented with no ambiguity     |
| Technical feasibility | 30%    | Feasibility confirmed with evidence from codebase |
| Stakeholder alignment | 30%    | All critical questions answered by user           |

If the weighted score falls below 80%, identify gaps and address them before finalizing.
