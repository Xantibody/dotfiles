---
name: execute-plan
description: Execute a multi-file plan from ./plans/ autonomously with continuous verification. Plan files are numbered (e.g., 01-setup.md, 02-implement.md) and executed in order as sequential steps of a single plan. Use this skill when the user asks to execute a plan, run a planned implementation, or says "execute the plan" or "run the plan". Works best after /clear and ideally wrapped with /goal for autonomous completion.
---

# Execute Plan

Execute a plan created in a previous session. All files in `./plans/` together form one plan — each file is a sequential step, ordered by its numeric prefix.

## How to Run

- **Preferred**: invoke this skill inside a `/goal` so Claude Code drives the loop until every step is complete. The goal supplies the "do not stop" guarantee; this skill supplies the per-step procedure.
- **Without `/goal`**: invoke manually and keep each response tool-using until done — a text-only reply is treated as "waiting for user input" and pauses execution.

Either way, best used after `/clear` to start with full context capacity.

## Workflow

### 1. Discover and Order Plan Files

- List all files in `./plans/`
- Sort by numeric prefix (`01-…` → `02-…` → `03-…`); files without a prefix sort alphabetically after numbered files
- Present the ordered file list and confirm with the user before starting

### 2. Validate Plan

- Read all plan files in sequence — they form a single continuous plan
- Identify task dependencies across files
- Confirm the current branch is appropriate for the work (use `branch-start` skill if unsure)

### 3. Execute

For each step:

1. Implement the changes
2. Run `verify` skill (static analysis + tests + format)
3. If verification fails, fix and re-verify
4. Run `commit` skill to create an atomic commit

Make reasonable decisions autonomously — choose the simpler option when unsure. Stop mid-execution only if continuing would cause irreversible damage (destructive operations on production data, force-push to shared branches, etc.).

### 4. Final Report

After all steps complete:

1. Run `verify` skill one final time
2. Report what was implemented and list the commits created

## Error Recovery

- **Test failures**: read the error, fix the code, re-run. Never skip failing tests.
- **Dependency issues**: install missing dependencies and retry.
- **Plan ambiguity**: choose the simpler interpretation. Document the decision in the commit message.
- **Conflicting steps**: follow the later step (it likely reflects updated thinking).
- **External service unavailable**: skip, note in the final summary, continue.
