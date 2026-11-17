package shot

import (
	"fmt"
	"time"

	"github.com/spf13/cobra"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

// Command returns `rat shot`.
func Command() *cobra.Command {
	var opts Options
	cmd := &cobra.Command{
		Use:   "shot --out <abs.png> --command <cmd> --wait <regex> [flags]",
		Short: "Capture one terminal screen with vhs from flags instead of a hand-written tape",
		Args: func(_ *cobra.Command, args []string) error {
			if len(args) > 0 {
				return fmt.Errorf("unexpected argument %q; the command goes in --command", args[0])
			}
			return nil
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			return cli.Code(Run(opts, cmd.OutOrStdout(), cmd.ErrOrStderr()))
		},
	}
	// AIDEV-NOTE: --out, --command and --wait are checked by tape() rather than MarkFlagRequired, whose "required flag(s) not set" drops the hint on what each should hold
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
