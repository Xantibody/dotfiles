// Package version prints the version rat was built as.
package version

import (
	"fmt"

	"github.com/spf13/cobra"
)

// Command returns `rat version`, which prints v on stdout.
func Command(v string) *cobra.Command {
	return &cobra.Command{
		Use:   "version",
		Short: "Print the version rat was built as",
		Args:  cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			_, err := fmt.Fprintln(cmd.OutOrStdout(), v)
			return err
		},
	}
}
