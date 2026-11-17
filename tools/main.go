// rat gathers the agent hooks and helper commands of this repository into
// one binary, one subcommand per tool.
package main

import (
	"os"

	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/version"
)

// buildVersion is set by the nix build with -ldflags "-X main.buildVersion=...".
var buildVersion = "dev"

func main() {
	root := &cobra.Command{
		Use:          "rat",
		Short:        "Agent hooks and helper commands from the dotfiles repository",
		SilenceUsage: true,
	}
	root.AddCommand(version.Command(buildVersion))
	if err := root.Execute(); err != nil {
		os.Exit(1)
	}
}
