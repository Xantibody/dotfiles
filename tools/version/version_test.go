package version

import (
	"bytes"
	"testing"
)

func TestCommandPrintsVersion(t *testing.T) {
	var out bytes.Buffer
	cmd := Command("1.2.3")
	cmd.SetOut(&out)
	cmd.SetArgs(nil)
	if err := cmd.Execute(); err != nil {
		t.Fatalf("Execute: %v", err)
	}
	if got, want := out.String(), "1.2.3\n"; got != want {
		t.Errorf("stdout = %q, want %q", got, want)
	}
}

func TestCommandRejectsArgs(t *testing.T) {
	cmd := Command("1.2.3")
	cmd.SetOut(&bytes.Buffer{})
	cmd.SetErr(&bytes.Buffer{})
	cmd.SetArgs([]string{"extra"})
	if err := cmd.Execute(); err == nil {
		t.Error("Execute with an argument succeeded, want an error")
	}
}
