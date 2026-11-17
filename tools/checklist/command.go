package checklist

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

const usage = "usage: rat checklist [--base <ref>]"

// Command returns `rat checklist`, applied to the repository the working
// directory is in.
func Command() *cobra.Command { return command(".") }

// command is Command run against the repository dir is in, for the tests.
func command(dir string) *cobra.Command {
	var base string
	cmd := &cobra.Command{
		Use:   "checklist [--base <ref>]",
		Short: "Print the rows of the base's REVIEW.md that the current change hits",
		Args:  cobra.ArbitraryArgs,
		// Run writes its own messages and exits 2 on a usage error
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			return cli.Code(Run(dir, base, args, cmd.OutOrStdout(), cmd.ErrOrStderr()))
		},
	}
	cmd.SetFlagErrorFunc(func(cmd *cobra.Command, err error) error {
		fmt.Fprintf(cmd.ErrOrStderr(), "checklist: %v\n%s\n", err, usage)
		return &cli.ExitError{Code: 2}
	})
	cmd.Flags().StringVar(&base, "base", "", "ref whose REVIEW.md applies and whose merge base starts the change (default: origin/HEAD)")
	return cmd
}
