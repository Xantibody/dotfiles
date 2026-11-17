package validate

import (
	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

// Command returns `rat skill validate`.
func Command() *cobra.Command {
	var opts Options
	cmd := &cobra.Command{
		Use:   "validate [flags] <skill-dir>...",
		Short: "Check SKILL.md frontmatter, skill references and the skill map against today's spec",
		Args:  cobra.MinimumNArgs(1),
		RunE: func(cmd *cobra.Command, args []string) error {
			return cli.Code(Run(opts, args, cmd.OutOrStdout(), cmd.ErrOrStderr()))
		},
	}
	f := cmd.Flags()
	f.BoolVar(&opts.Offline, "offline", false, "skip fetching the docs; use the baked-in field list")
	f.BoolVar(&opts.Strict, "strict", false, "fail on warnings as well as errors")
	f.StringVar(&opts.Readme, "readme", "", "skill map (configs/agents/README.md) that must name every validated skill")
	// StringArray, not StringSlice: a path is never split at a comma
	f.StringArrayVar(&opts.Known, "known", nil, "a skill that may be referred to but is not validated (repeatable)")
	return cmd
}
