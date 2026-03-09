---
name: execute-plan
description: Execute a previously created plan autonomously with continuous verification.
---

# Execute Plan

Use this skill to execute a plan that was created in a previous session.
This skill is designed for use after clearing context (`/clear`) to start fresh with full capacity.

## Workflow

### 1. Discover and Select Plan

- Read all files in `./plans/` directory
- If multiple plan files exist, present a summary of each plan and ask the user which one to execute
- If only one plan file exists, confirm with the user before proceeding

### 2. Validate Plan

- Read the selected plan file thoroughly
- Identify all tasks and their dependencies
- Confirm the current branch state is appropriate for the work

### 3. Execute Plan Autonomously

**CRITICAL: You MUST execute ALL steps in a single uninterrupted session. Do NOT pause between steps to report progress or ask for confirmation.**

Execute each step of the plan following these rules:

- **Continuous execution**: Work through ALL steps from start to finish without stopping. After completing one step, immediately begin the next step. The only acceptable output between steps is tool calls — never a text-only message that waits for user input.
- **Continuous verification**: Run `/verify` skill after completing each logical unit of work (e.g., after each feature, each bug fix, or each major refactoring step)
- **Fix before proceeding**: If `/verify` finds issues, fix them immediately and re-run `/verify`. Do NOT stop to report the failure — just fix it and continue.
- **Commit discipline**: Use `/commit` skill after each passing verification to create atomic commits
- **Autonomous decisions**: Make reasonable decisions on your own. Choose the simpler option when unsure. Do NOT ask the user for guidance.

**The ONLY reason to stop mid-execution** is if continuing would cause irreversible damage (e.g., destructive operations on production data). Ambiguity, minor uncertainty, or multiple valid approaches are NOT reasons to stop — pick the approach most consistent with the plan and proceed.

**Prohibited behaviors during execution:**

- Stopping to summarize progress or show intermediate results
- Asking "should I continue?" or "shall I proceed to the next step?"
- Reporting what you just did and waiting for acknowledgment
- Asking the user to choose between implementation options

### 4. Final Verification

After all steps are complete:

1. Run `/verify` skill one final time
2. Confirm all tests pass
3. Report a summary of what was implemented and the commits created
4. Recommend creating a decision record: suggest the user run `/decision-record` to document the rationale and outcomes

## Quality Gates

Each logical unit of work must pass these gates before proceeding:

1. Static analysis passes (linting, type checking)
2. All tests pass
3. Code is properly formatted
4. Changes are committed with Conventional Commits format
