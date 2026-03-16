---
name: execute-plan
description: Execute a previously created plan autonomously with continuous verification. Use this skill when the user asks to execute a plan from the ./plans/ directory, wants to run a planned implementation end-to-end, or says something like "execute the plan" or "run the plan". Works best after /clear to start with full context capacity.
---

# Execute Plan

Use this skill to execute a plan that was created in a previous session.
This skill is designed for use after clearing context (`/clear`) to start fresh with full capacity.

## Golden Rule: Never Send a Text-Only Response

Until the entire plan is complete, **every single response MUST contain at least one tool call**. A response with only text and no tool call causes execution to stall — the system interprets it as "waiting for user input" and silently stops. This is the #1 cause of plans stopping midway through.

**Self-check before every response**: "Have I completed ALL steps in the plan? If no, this response MUST include a tool call to continue working. If I just finished a phase, I must immediately start the next phase with a tool call in this same response."

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
- **Bridge action between phases**: When you finish a phase or step, your very next action in the same response must be a tool call that starts the next phase — typically reading the next file to edit, running a command, or writing code. Never "announce" the next phase in text without simultaneously starting it with a tool call.
- **Continuous verification**: Run `/verify` skill after completing each logical unit of work (e.g., after each feature, each bug fix, or each major refactoring step)
- **Fix before proceeding**: If `/verify` finds issues, fix them immediately and re-run `/verify`. Do NOT stop to report the failure — just fix it and continue.
- **Commit discipline**: Use `/commit` skill after each passing verification to create atomic commits
- **Autonomous decisions**: Make reasonable decisions on your own. Choose the simpler option when unsure. Do NOT ask the user for guidance.

**The ONLY reason to stop mid-execution** is if continuing would cause irreversible damage (e.g., destructive operations on production data). Ambiguity, minor uncertainty, or multiple valid approaches are NOT reasons to stop — pick the approach most consistent with the plan and proceed.

**Prohibited behaviors during execution:**

- Sending a response that contains NO tool calls (this silently stalls execution — the system will stop and wait for user input)
- Stopping to summarize progress or show intermediate results
- Asking "should I continue?" or "shall I proceed to the next step?"
- Reporting what you just did and waiting for acknowledgment
- Asking the user to choose between implementation options
- Outputting a phase completion message without immediately starting the next phase in the same response

### 4. Final Verification

After all steps are complete:

1. Run `/verify` skill one final time
2. Confirm all tests pass
3. Report a summary of what was implemented and the commits created
4. Recommend creating a decision record: suggest the user run `/decision-record` to document the rationale and outcomes

## Error Recovery

When encountering errors during execution:

- **Test failures**: Read the error message, fix the code, re-run tests. Do not skip failing tests.
- **Dependency issues**: Install missing dependencies (`nix develop`, `npm install`, `go mod download`) and retry.
- **Plan ambiguity**: Choose the simpler interpretation consistent with the plan's intent. Document the decision in the commit message.
- **Conflicting steps**: If a later step contradicts an earlier one, follow the later step (it likely reflects updated thinking).
- **External service unavailable**: Skip the step, note it in the final summary, and continue with remaining steps.

## Quality Gates

Each logical unit of work must pass these gates before proceeding:

1. Static analysis passes (linting, type checking)
2. All tests pass
3. Code is properly formatted
4. Changes are committed with Conventional Commits format
