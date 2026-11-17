package deny

import (
	"bytes"
	"strings"
	"testing"
)

func execute(t *testing.T, stdin string) (string, error) {
	t.Helper()
	var out bytes.Buffer
	cmd := Command()
	cmd.SetIn(strings.NewReader(stdin))
	cmd.SetOut(&out)
	cmd.SetErr(&bytes.Buffer{})
	cmd.SetArgs(nil)
	err := cmd.Execute()
	return out.String(), err
}

func TestCommandDeniesFromStdin(t *testing.T) {
	out, err := execute(t, `{"tool_name":"Bash","tool_input":{"command":"git push"}}`)
	if err != nil {
		t.Fatalf("Execute: %v", err)
	}
	if !strings.Contains(out, `"permissionDecision":"deny"`) {
		t.Errorf("stdout = %q, want a deny decision", out)
	}
}

func TestCommandSilentWhenAllowed(t *testing.T) {
	out, err := execute(t, `{"tool_name":"Bash","tool_input":{"command":"git status"}}`)
	if err != nil {
		t.Fatalf("Execute: %v", err)
	}
	if out != "" {
		t.Errorf("stdout = %q, want none", out)
	}
}

func TestCommandFailsOnBadInput(t *testing.T) {
	if _, err := execute(t, "not json"); err == nil {
		t.Error("Execute accepted input that is not JSON")
	}
}
