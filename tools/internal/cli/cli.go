// Package cli is how rat turns what a subcommand returns into an exit code
// and the lines on stderr, shared by main and the tests of each subcommand.
package cli

import (
	"errors"
	"fmt"
	"io"
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

// Exit writes err to stderr the way rat reports it and returns the code rat
// exits with: an error that carries its own code (an *ExitError, a hook
// blocking with 2) is written as it is when it has a message; any other is
// written after "Error:" and exits 1.
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
	fmt.Fprintln(stderr, "Error:", err)
	return 1
}
