---
name: execute-plan
description: Execute a multi-file plan from ./plans/ autonomously with continuous verification. Plan files are numbered (e.g., 01-setup.md, 02-implement.md) and executed in order as sequential steps of a single plan. Use this skill when the user asks to execute a plan, run a planned implementation, or says "execute the plan" or "run the plan". Works best after /clear to start with full context capacity.
---

# Execute Plan

Execute a plan created in a previous session. All files in `./plans/` together form one plan — each file is a sequential step, ordered by its numeric prefix.

Best used after clearing context (`/clear`) to start with full capacity.

## Why Continuous Execution Matters

Claude Code treats a text-only response (no tool calls) as "waiting for user input" and pauses execution. If you finish a step and reply with just a progress update, the plan silently stalls. The user chose autonomous execution because they want to come back to a finished result — not babysit each step.

To keep execution flowing: every response must include at least one tool call until the entire plan is complete. When finishing one step, start the next in the same response by immediately making a tool call (read the next file, run a command, write code). Never announce what you're about to do without also doing it.

**Self-check**: "Have I completed ALL steps? If no, this response needs a tool call."

## Workflow

### 1. Discover and Order Plan Files

- List all files in `./plans/` directory
- Sort by numeric prefix to determine execution order (e.g., `01-setup-database.md` → `02-add-api-endpoints.md` → `03-write-tests.md`)
- If any files lack a numeric prefix, sort them alphabetically after numbered files
- Present the file list in order and confirm with the user before starting

### 2. Validate Plan

- Read all plan files in sequence — they form a single continuous plan
- Identify all tasks and their dependencies across files
- Confirm the current branch state is appropriate for the work

### 3. Execute Autonomously

Work through all steps from start to finish without pausing. For each logical unit of work:

1. Implement the changes
2. Run `/verify` (static analysis + tests + format)
3. If verification fails, fix and re-verify
4. Run `/commit` to create an atomic commit

Make reasonable decisions on your own — choose the simpler option when unsure. The only reason to stop mid-execution is if continuing would cause irreversible damage (e.g., destructive operations on production data).

### 4. Final Report

After all steps are complete:

1. Run `/verify` one final time
2. Report a summary of what was implemented and the commits created

## Error Recovery

- **Test failures**: Read the error, fix the code, re-run. Never skip failing tests.
- **Dependency issues**: Install missing dependencies and retry.
- **Plan ambiguity**: Choose the simpler interpretation. Document the decision in the commit message.
- **Conflicting steps**: Follow the later step (it likely reflects updated thinking).
- **External service unavailable**: Skip, note in the final summary, continue.
