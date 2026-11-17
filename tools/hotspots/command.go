package hotspots

import (
	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

// Command returns `rat hotspots`.
func Command() *cobra.Command {
	var n int
	cmd := &cobra.Command{
		Use:   "hotspots <file.folded>",
		Short: "Rank the frames of a folded-stacks file, self and total, as text",
		Args:  cobra.ExactArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return cli.Code(Run(n, args[0], cmd.OutOrStdout(), cmd.ErrOrStderr()))
		},
	}
	// -n as before, both as the shorthand and the long name
	cmd.Flags().IntVarP(&n, "n", "n", 15, "number of frames to list per table")
	return cmd
}
