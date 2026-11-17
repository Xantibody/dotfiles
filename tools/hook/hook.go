// Package hook groups the Claude Code hooks under `rat hook`.
package hook

import "github.com/spf13/cobra"

// Command returns `rat hook` with each hook as a subcommand.
func Command(hooks ...*cobra.Command) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "hook",
		Short: "Claude Code hooks, each reading the hook JSON on stdin",
	}
	cmd.AddCommand(hooks...)
	return cmd
}
