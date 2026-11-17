package checklist

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

// Command returns `rat checklist`, applied to the repository the working
// directory is in.
func Command() *cobra.Command { return command(".") }

// command is Command run against the repository dir is in, for the tests.
func command(dir string) *cobra.Command {
	var base string
	cmd := &cobra.Command{
		Use:   "checklist",
		Short: "Print the rows of the base's REVIEW.md that the current change hits",
		Args: func(_ *cobra.Command, args []string) error {
			if len(args) > 0 {
				return fmt.Errorf("unexpected argument %q; the change is always the current repository's", args[0])
			}
			return nil
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			return cli.Code(Run(dir, base, cmd.OutOrStdout(), cmd.ErrOrStderr()))
		},
	}
	cmd.Flags().StringVar(&base, "base", "", "ref whose REVIEW.md applies and whose merge base starts the change (default: origin/HEAD)")
	return cmd
}
