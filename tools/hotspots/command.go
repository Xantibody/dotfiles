package hotspots

import (
	"fmt"

	"github.com/spf13/cobra"
)

const usage = "usage: rat hotspots [-n N] <file.folded>"

// exitError makes rat exit with code; Run has already written the message,
// so it carries none of its own.
type exitError struct{ code int }

func (e *exitError) Error() string { return "" }

func (e *exitError) ExitCode() int { return e.code }

// Command returns `rat hotspots`.
func Command() *cobra.Command {
	var n int
	cmd := &cobra.Command{
		Use:   "hotspots [-n N] <file.folded>",
		Short: "Rank the frames of a folded-stacks file, self and total, as text",
		Args:  cobra.ArbitraryArgs,
		// Run writes its own messages and exits 2 on a usage error
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			if code := Run(n, args, cmd.OutOrStdout(), cmd.ErrOrStderr()); code != 0 {
				return &exitError{code: code}
			}
			return nil
		},
	}
	cmd.SetFlagErrorFunc(func(cmd *cobra.Command, err error) error {
		fmt.Fprintf(cmd.ErrOrStderr(), "%v\n%s\n", err, usage)
		return &exitError{code: 2}
	})
	// -n as before, both as the shorthand and the long name
	cmd.Flags().IntVarP(&n, "n", "n", 15, "number of frames to list per table")
	return cmd
}
