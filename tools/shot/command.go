package shot

import (
	"fmt"
	"time"

	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

const usage = "usage: rat shot --out <abs.png> --command <cmd> --wait <regex> [--setup <cmd>]... [--ready <regex>] [--width N] [--height N] [--font-size N] [--wait-timeout D] [--vhs vhs] [--tape-only]"

// Command returns `rat shot`.
func Command() *cobra.Command {
	var opts Options
	cmd := &cobra.Command{
		Use:   "shot --out <abs.png> --command <cmd> --wait <regex> [flags]",
		Short: "Capture one terminal screen with vhs from flags instead of a hand-written tape",
		Args:  cobra.ArbitraryArgs,
		// Run writes its own messages and exits 2 on a usage error
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(cmd *cobra.Command, args []string) error {
			return cli.Code(Run(opts, args, cmd.OutOrStdout(), cmd.ErrOrStderr()))
		},
	}
	cmd.SetFlagErrorFunc(func(cmd *cobra.Command, err error) error {
		fmt.Fprintf(cmd.ErrOrStderr(), "shot: %v\n%s\n", err, usage)
		return &cli.ExitError{Code: 2}
	})
	f := cmd.Flags()
	f.StringVar(&opts.Out, "out", "", "PNG to write (the .tape and .gif go beside it)")
	// StringArray, not StringSlice: a command is never split at a comma
	f.StringArrayVar(&opts.Setup, "setup", nil, "command typed while hidden, such as loading the config under test (repeatable)")
	f.StringVar(&opts.Ready, "ready", "", "regex the screen matches once the setup is done (required with --setup)")
	f.StringVar(&opts.Command, "command", "", "command typed while shown")
	f.StringVar(&opts.Wait, "wait", "", "regex the screen matches once --command has drawn its result")
	f.IntVar(&opts.Width, "width", 1200, "terminal width in pixels")
	f.IntVar(&opts.Height, "height", 600, "terminal height in pixels")
	f.IntVar(&opts.FontSize, "font-size", 18, "font size")
	f.DurationVar(&opts.WaitTimeout, "wait-timeout", 15*time.Second, "how long each wait may take before vhs fails")
	f.StringVar(&opts.VHS, "vhs", "vhs", "vhs executable")
	f.BoolVar(&opts.TapeOnly, "tape-only", false, "print the tape to stdout and run nothing")
	return cmd
}
