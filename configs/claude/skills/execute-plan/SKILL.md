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

Execute each step of the plan following these rules:

- **Do not stop**: Work through all steps until the plan is fully implemented
- **Continuous verification**: Run `/verify` skill after completing each logical unit of work (e.g., after each feature, each bug fix, or each major refactoring step)
- **Fix before proceeding**: If `/verify` finds issues, fix them immediately before moving to the next step
- **Commit discipline**: Use `/commit` skill after each passing verification to create atomic commits
- **No questions during execution**: Make reasonable decisions autonomously. Only ask the user if a critical ambiguity would lead to fundamentally different implementations

### 4. Final Verification

After all steps are complete:

1. Run `/verify` skill one final time
2. Confirm all tests pass
3. Report a summary of what was implemented and the commits created

## Quality Gates

Each logical unit of work must pass these gates before proceeding:

1. Static analysis passes (linting, type checking)
2. All tests pass
3. Code is properly formatted
4. Changes are committed with Conventional Commits format
