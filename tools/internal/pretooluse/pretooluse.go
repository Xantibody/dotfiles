// Package pretooluse reads and answers a Claude Code PreToolUse hook call for
// the Bash tool: {"tool_input":{"command":...}} on stdin, and on stdout a
// hookSpecificOutput with a permissionDecision, or nothing to let the call
// through.
package pretooluse

import (
	"encoding/json"
	"fmt"
	"io"
)

// Command reads the hook input and returns the Bash command it carries, ""
// when there is none.
func Command(stdin io.Reader) (string, error) {
	var in struct {
		ToolInput struct {
			Command string `json:"command"`
		} `json:"tool_input"`
	}
	if err := json.NewDecoder(stdin).Decode(&in); err != nil {
		return "", fmt.Errorf("read hook input: %w", err)
	}
	return in.ToolInput.Command, nil
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
