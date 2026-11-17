package ghguard

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

func TestCommandAsksFromStdin(t *testing.T) {
	out, err := execute(t, `{"tool_name":"Bash","tool_input":{"command":"gh api -X PUT repos/o/r/contents/x"}}`)
	if err != nil {
		t.Fatalf("Execute: %v", err)
	}
	if !strings.Contains(out, `"permissionDecision":"ask"`) {
		t.Errorf("stdout = %q, want an ask decision", out)
	}
}

func TestCommandFailsOnBadInput(t *testing.T) {
	if _, err := execute(t, "not json"); err == nil {
		t.Error("Execute accepted input that is not JSON")
	}
}
