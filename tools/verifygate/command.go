package verifygate

import "github.com/spf13/cobra"

const usage = "usage: rat verify-gate run [--] <command>... | rat verify-gate commit-msg <file>"

// Command returns `rat verify-gate` with run and commit-msg.
func Command() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "verify-gate",
		Short: "Commit gate that records each commit's verification as Verified-by trailers",
		Args:  cobra.ArbitraryArgs,
		// errors carry their own "verify-gate:" message and exit code
		SilenceUsage:  true,
		SilenceErrors: true,
		RunE: func(*cobra.Command, []string) error {
			return fail(usage)
		},
	}

	run := &cobra.Command{
		Use:   "run [--] <command>...",
		Short: "Run command and, when it passes, record it against the working tree as it stands",
		Args:  cobra.ArbitraryArgs,
		RunE: func(cmd *cobra.Command, args []string) error {
			return Run(args, cmd.InOrStdin(), cmd.OutOrStdout(), cmd.ErrOrStderr())
		},
	}
	// everything from the command on is its own, -x included
	run.Flags().SetInterspersed(false)

	commitMsg := &cobra.Command{
		Use:   "commit-msg <file>",
		Short: "git's commit-msg hook: write the records of the committed tree as Verified-by trailers",
		Args:  cobra.ArbitraryArgs,
		RunE: func(_ *cobra.Command, args []string) error {
			if len(args) == 0 {
				return fail("usage: rat verify-gate commit-msg <file>")
			}
			return CommitMsg(args[0])
		},
	}

	cmd.AddCommand(run, commitMsg)
	return cmd
}
