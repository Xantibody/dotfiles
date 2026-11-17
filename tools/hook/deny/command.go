package deny

import "github.com/spf13/cobra"

// Command returns `rat hook deny`.
func Command() *cobra.Command {
	return &cobra.Command{
		Use:   "deny",
		Short: "PreToolUse hook that refuses git push and rm -rf in any spelling",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			return run(cmd.InOrStdin(), cmd.OutOrStdout())
		},
	}
}
