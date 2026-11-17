package cli

import (
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/spf13/cobra"
)

func TestExit(t *testing.T) {
	for _, tc := range []struct {
		name   string
		err    error
		code   int
		stderr string
	}{
		{"nil", nil, 0, ""},
		{"coded with a message", &ExitError{Code: 3, Msg: "tool: broke"}, 3, "tool: broke\n"},
		{"silent coded", &ExitError{Code: 2}, 2, ""},
		{"wrapped coded", fmt.Errorf("outer: %w", &ExitError{Code: 4}), 4, "outer: \n"},
		{"plain", errors.New("tool: broke"), 1, "tool: broke\n"},
		{"Code(0)", Code(0), 0, ""},
		{"Code(5)", Code(5), 5, ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var stderr strings.Builder
			if code := Exit(tc.err, &stderr); code != tc.code || stderr.String() != tc.stderr {
				t.Errorf("Exit = %d with stderr %q, want %d with %q", code, stderr.String(), tc.code, tc.stderr)
			}
		})
	}
}

// tree is rat with a group holding one command that takes exactly one
// argument and an int flag, and one that fails with a plain error.
func tree() *cobra.Command {
	var n int
	one := &cobra.Command{
		Use:  "one <arg>",
		Args: cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Fprintf(cmd.OutOrStdout(), "%s %d\n", args[0], n)
			return nil
		},
	}
	one.Flags().IntVarP(&n, "n", "n", 1, "a number")
	broken := &cobra.Command{
		Use:  "broken",
		Args: cobra.NoArgs,
		RunE: func(*cobra.Command, []string) error { return errors.New("it broke") },
	}
	group := &cobra.Command{Use: "group", Short: "a group"}
	group.AddCommand(one, broken)
	return Root(group)
}

func TestMainRuns(t *testing.T) {
	for _, tc := range []struct {
		name           string
		args           []string
		code           int
		stdout, stderr string // stdout exactly; stderr as a substring, "" for none
	}{
		{"runs", []string{"group", "one", "a", "-n", "3"}, 0, "a 3\n", ""},
		{"missing argument", []string{"group", "one"}, 2, "", "rat group one: accepts 1 arg(s), received 0\nUsage:\n  rat group one <arg> [flags]"},
		{"extra argument", []string{"group", "one", "a", "b"}, 2, "", "accepts 1 arg(s), received 2"},
		{"unknown flag", []string{"group", "one", "--bogus", "a"}, 2, "", "rat group one: unknown flag: --bogus\nUsage:"},
		{"bad flag value", []string{"group", "one", "-n", "many", "a"}, 2, "", `invalid argument "many"`},
		{"unknown subcommand", []string{"group", "bogus"}, 2, "", `rat group: unknown command "bogus" for "rat group"`},
		{"unknown top-level command", []string{"bogus"}, 2, "", `unknown command "bogus" for "rat"`},
		{"plain error names the command", []string{"group", "broken"}, 1, "", "rat group broken: it broke\n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var stdout, stderr strings.Builder
			code := Main(tree(), tc.args, strings.NewReader(""), &stdout, &stderr)
			if code != tc.code || stdout.String() != tc.stdout || !strings.Contains(stderr.String(), tc.stderr) || (tc.stderr == "") != (stderr.Len() == 0) {
				t.Errorf("exit %d, stdout %q, stderr %q; want %d, %q and %q", code, stdout.String(), stderr.String(), tc.code, tc.stdout, tc.stderr)
			}
		})
	}
}

// A group called alone prints its help on stdout and exits 0.
func TestMainGroupAlone(t *testing.T) {
	var stdout, stderr strings.Builder
	if code := Main(tree(), []string{"group"}, strings.NewReader(""), &stdout, &stderr); code != 0 || !strings.Contains(stdout.String(), "Available Commands:") || stderr.Len() > 0 {
		t.Errorf("exit %d, stdout %q, stderr %q; want 0 and the group's help", code, stdout.String(), stderr.String())
	}
}
