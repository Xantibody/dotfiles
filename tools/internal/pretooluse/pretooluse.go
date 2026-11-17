// Package pretooluse reads and answers a Claude Code PreToolUse hook call for
// the Bash tool: {"tool_input":{"command":...},"cwd":...} on stdin, and on
// stdout a hookSpecificOutput with a permissionDecision, or nothing to let the
// call through. A hook that refuses with a message for Claude instead returns
// a *BlockError, which rat turns into exit code 2.
package pretooluse

import (
	"encoding/json"
	"fmt"
	"io"
)

// Input is the part of the hook input the Bash hooks read.
type Input struct {
	// Command is the Bash command, "" when there is none.
	Command string
	// Cwd is the directory the command runs in.
	Cwd string
}

// Read reads the hook input.
func Read(stdin io.Reader) (Input, error) {
	var in struct {
		Cwd       string `json:"cwd"`
		ToolInput struct {
			Command string `json:"command"`
		} `json:"tool_input"`
	}
	if err := json.NewDecoder(stdin).Decode(&in); err != nil {
		return Input{}, fmt.Errorf("read hook input: %w", err)
	}
	return Input{Command: in.ToolInput.Command, Cwd: in.Cwd}, nil
}

// Command reads the hook input and returns the Bash command it carries, ""
// when there is none.
func Command(stdin io.Reader) (string, error) {
	in, err := Read(stdin)
	return in.Command, err
}

// Decide writes a permissionDecision ("deny", "ask" or "allow") with its reason.
func Decide(stdout io.Writer, decision, reason string) error {
	type output struct {
		HookEventName            string `json:"hookEventName"`
		PermissionDecision       string `json:"permissionDecision"`
		PermissionDecisionReason string `json:"permissionDecisionReason"`
	}
	return json.NewEncoder(stdout).Encode(map[string]output{
		"hookSpecificOutput": {"PreToolUse", decision, reason},
	})
}

// BlockError refuses the tool call the way exit code 2 does: Claude Code
// stops the call and shows Message, written to stderr as it is, to Claude.
type BlockError struct{ Message string }

func (e *BlockError) Error() string { return e.Message }

// ExitCode is the code rat exits with, 2 for a blocking PreToolUse error.
func (e *BlockError) ExitCode() int { return 2 }

// Block returns a *BlockError with the message.
func Block(message string) error { return &BlockError{Message: message} }
