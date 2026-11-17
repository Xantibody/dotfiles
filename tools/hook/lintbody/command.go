package lintbody

import "github.com/spf13/cobra"

// Command returns `rat hook lint-body`.
func Command() *cobra.Command {
	return &cobra.Command{
		Use:   "lint-body",
		Short: "PreToolUse hook that runs lint-body on the --body-file of gh pr / issue and blocks while findings remain",
		Args:  cobra.NoArgs,
		// a block is the hook's answer, not a usage mistake
		SilenceUsage: true,
		RunE: func(cmd *cobra.Command, _ []string) error {
			return run(cmd.InOrStdin())
		},
	}
}
