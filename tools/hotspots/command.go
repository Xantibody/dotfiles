package hotspots

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

const usage = "usage: rat hotspots [-n N] <file.folded>"

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
			return cli.Code(Run(n, args, cmd.OutOrStdout(), cmd.ErrOrStderr()))
		},
	}
	cmd.SetFlagErrorFunc(func(cmd *cobra.Command, err error) error {
		fmt.Fprintf(cmd.ErrOrStderr(), "%v\n%s\n", err, usage)
		return &cli.ExitError{Code: 2}
	})
	// -n as before, both as the shorthand and the long name
	cmd.Flags().IntVarP(&n, "n", "n", 15, "number of frames to list per table")
	return cmd
}
