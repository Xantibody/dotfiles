// Package skill groups the commands that work on agent skills under `rat skill`.
package skill

import "github.com/spf13/cobra"

// Command returns `rat skill` with each tool as a subcommand.
func Command(tools ...*cobra.Command) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "skill",
		Short: "Tools for the agent skills under configs/agents/skills",
	}
	cmd.AddCommand(tools...)
	return cmd
}
