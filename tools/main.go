// rat gathers the agent hooks and helper commands of this repository into
// one binary, one subcommand per tool.
package main

import (
	"errors"
	"fmt"
	"os"

	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/hook"
	"github.com/Xantibody/dotfiles/tools/hook/anchors"
	"github.com/Xantibody/dotfiles/tools/hook/deny"
	"github.com/Xantibody/dotfiles/tools/hook/ghguard"
	"github.com/Xantibody/dotfiles/tools/hook/lintbody"
	"github.com/Xantibody/dotfiles/tools/shot"
	"github.com/Xantibody/dotfiles/tools/skill"
	"github.com/Xantibody/dotfiles/tools/skill/validate"
	"github.com/Xantibody/dotfiles/tools/verifygate"
	"github.com/Xantibody/dotfiles/tools/version"
)

// buildVersion is set by the nix build with -ldflags "-X main.buildVersion=...".
var buildVersion = "dev"

func main() {
	root := &cobra.Command{
		Use:           "rat",
		Short:         "Agent hooks and helper commands from the dotfiles repository",
		SilenceUsage:  true,
		SilenceErrors: true,
	}
	root.AddCommand(
		version.Command(buildVersion),
		hook.Command(deny.Command(), ghguard.Command(), anchors.Command(), lintbody.Command()),
		verifygate.Command(),
		skill.Command(validate.Command()),
		shot.Command(),
	)
	if err := root.Execute(); err != nil {
		// An error that carries its own exit code (a hook blocking with 2, the
		// exit code of the command verify-gate ran) is written as it is, for
		// whoever reads stderr, when it has a message; any other is reported
		// the way cobra does and exits 1.
		var coded interface{ ExitCode() int }
		if errors.As(err, &coded) {
			if msg := err.Error(); msg != "" {
				fmt.Fprintln(os.Stderr, msg)
			}
			os.Exit(coded.ExitCode())
		}
		fmt.Fprintln(os.Stderr, "Error:", err)
		os.Exit(1)
	}
}
