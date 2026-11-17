package lintbody

import (
	"bytes"
	"errors"
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

// A body with findings ends in an error that makes rat exit 2, with nothing
// on stdout.
func TestCommandExitsTwoOnFindings(t *testing.T) {
	cwd := setup(t)
	out, err := execute(t, `{"cwd":"`+cwd+`","tool_input":{"command":"gh pr create --body-file ng.md"}}`)
	var coded interface{ ExitCode() int }
	if !errors.As(err, &coded) || coded.ExitCode() != 2 {
		t.Errorf("Execute = %v, want an error with exit code 2", err)
	}
	if out != "" {
		t.Errorf("stdout = %q, want none", out)
	}
}

func TestCommandPassesSilently(t *testing.T) {
	cwd := setup(t)
	out, err := execute(t, `{"cwd":"`+cwd+`","tool_input":{"command":"gh pr create --body-file ok.md"}}`)
	if err != nil || out != "" {
		t.Errorf("Execute = %q, %v, want no output and no error", out, err)
	}
}
