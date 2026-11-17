// Package cli is how rat runs a subcommand and turns what it returns into an
// exit code and the lines on stderr, shared by main and the tests of each
// subcommand so that both go through the same path.
//
// A flag the command does not know, a flag value that does not parse, or
// positional arguments its cobra Args validator rejects are a usage error:
// exit 2 with the command's usage on stderr. A group such as `rat hook`
// prints its help when called alone and refuses a subcommand it does not
// have.
package cli

import (
	"errors"
	"fmt"
	"io"
	"strings"

	"github.com/spf13/cobra"
)

// ExitError makes rat exit with Code, writing Msg to stderr when there is
// one. A subcommand that has already written its own messages returns one
// without Msg.
type ExitError struct {
	Code int
	Msg  string
}

func (e *ExitError) Error() string { return e.Msg }

// ExitCode is the code rat exits with.
func (e *ExitError) ExitCode() int { return e.Code }

// Code is nil for 0 and otherwise a silent *ExitError with code, for a Run
// that returns its exit code and has written its messages itself.
func Code(code int) error {
	if code == 0 {
		return nil
	}
	return &ExitError{Code: code}
}

// Usage is the usage error for cmd: exit 2, with what was wrong and how cmd
// is called.
func Usage(cmd *cobra.Command, err error) error {
	return &ExitError{Code: 2, Msg: fmt.Sprintf("%s: %v\n%s", cmd.CommandPath(), err, strings.TrimRight(cmd.UsageString(), "\n"))}
}

// Root returns the rat command with subs under it.
func Root(subs ...*cobra.Command) *cobra.Command {
	root := &cobra.Command{
		Use:   "rat",
		Short: "Agent hooks and helper commands from the dotfiles repository",
	}
	root.AddCommand(subs...)
	return root
}

// Main runs root with args and returns the code rat exits with, having
// written any error to stderr.
func Main(root *cobra.Command, args []string, stdin io.Reader, stdout, stderr io.Writer) int {
	// errors are written by Exit, once, and the usage only for a usage error
	root.SilenceErrors = true
	root.SilenceUsage = true
	root.SetFlagErrorFunc(Usage)
	prepare(root)
	if args == nil {
		args = []string{} // cobra reads os.Args when given nil
	}
	root.SetArgs(args)
	root.SetIn(stdin)
	root.SetOut(stdout)
	root.SetErr(stderr)
	cmd, err := root.ExecuteC()
	var coded interface{ ExitCode() int }
	if err != nil && !errors.As(err, &coded) {
		err = fmt.Errorf("%s: %w", cmd.CommandPath(), err)
	}
	return Exit(err, stderr)
}

// prepare makes each group runnable, so it refuses an unknown subcommand
// instead of printing help and exiting 0, and turns every Args rejection
// into a usage error.
func prepare(c *cobra.Command) {
	if c.HasSubCommands() && !c.Runnable() {
		c.Args = cobra.NoArgs
		c.RunE = func(cmd *cobra.Command, _ []string) error { return cmd.Help() }
	}
	if check := c.Args; check != nil {
		c.Args = func(cmd *cobra.Command, args []string) error {
			if err := check(cmd, args); err != nil {
				return Usage(cmd, err)
			}
			return nil
		}
	}
	for _, sub := range c.Commands() {
		prepare(sub)
	}
}

// Exit writes err to stderr the way rat reports it and returns the code rat
// exits with: an error that carries its own code (an *ExitError, a hook
// blocking with 2) is written when it has a message; any other is written
// and exits 1.
func Exit(err error, stderr io.Writer) int {
	if err == nil {
		return 0
	}
	var coded interface{ ExitCode() int }
	if errors.As(err, &coded) {
		if msg := err.Error(); msg != "" {
			fmt.Fprintln(stderr, msg)
		}
		return coded.ExitCode()
	}
	fmt.Fprintln(stderr, err)
	return 1
}
