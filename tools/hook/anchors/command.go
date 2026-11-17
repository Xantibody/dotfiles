package anchors

import "github.com/spf13/cobra"

// Command returns `rat hook anchors`.
func Command() *cobra.Command {
	return &cobra.Command{
		Use:   "anchors",
		Short: "PreToolUse hook that shows the anchors next to a file before it is edited",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			return run(cmd.InOrStdin(), cmd.OutOrStdout())
		},
	}
}
