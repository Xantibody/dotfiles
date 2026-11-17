package ghguard

import "github.com/spf13/cobra"

// Command returns `rat hook gh-guard`.
func Command() *cobra.Command {
	return &cobra.Command{
		Use:   "gh-guard",
		Short: "PreToolUse hook that asks before gh writes repository protection or a branch",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			return run(cmd.InOrStdin(), cmd.OutOrStdout())
		},
	}
}
