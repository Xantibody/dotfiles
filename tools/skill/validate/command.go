package validate

import (
	"fmt"

	"github.com/spf13/cobra"
)

const usage = "usage: rat skill validate [--offline] [--strict] [--readme README.md] [--known <skill-dir>]... <skill-dir>..."

// exitError makes rat exit with code; the report is already written, so it
// carries no message of its own.
type exitError struct{ code int }

func (e *exitError) Error() string { return "" }

func (e *exitError) ExitCode() int { return e.code }

// Command returns `rat skill validate`.
func Command() *cobra.Command {
	var opts Options
	cmd := &cobra.Command{
		Use:   "validate [flags] <skill-dir>...",
		Short: "Check SKILL.md frontmatter, skill references and the skill map against today's spec",
		Args:  cobra.ArbitraryArgs,
		// the report and usage errors are written by Run, which exits 2 on a usage error
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			if code := Run(opts, args, cmd.OutOrStdout(), cmd.ErrOrStderr()); code != 0 {
				return &exitError{code: code}
			}
			return nil
		},
	}
	cmd.SetFlagErrorFunc(func(cmd *cobra.Command, err error) error {
		fmt.Fprintf(cmd.ErrOrStderr(), "%v\n%s\n", err, usage)
		return &exitError{code: 2}
	})
	f := cmd.Flags()
	f.BoolVar(&opts.Offline, "offline", false, "skip fetching the docs; use the baked-in field list")
	f.BoolVar(&opts.Strict, "strict", false, "fail on warnings as well as errors")
	f.StringVar(&opts.Readme, "readme", "", "skill map (configs/agents/README.md) that must name every validated skill")
	// StringArray, not StringSlice: a path is never split at a comma
	f.StringArrayVar(&opts.Known, "known", nil, "a skill that may be referred to but is not validated (repeatable)")
	return cmd
}
