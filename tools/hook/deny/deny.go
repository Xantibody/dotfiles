// Package deny is `rat hook deny`, a PreToolUse hook for Claude Code's Bash
// tool: it reads {"tool_input":{"command":...}} on stdin and writes a
// hookSpecificOutput permissionDecision "deny" on stdout. codex uses
// modules/ai/codex-rules/deny.rules instead.
//
// It refuses git push and rm with both -r and -f, in any spelling the
// permission rules' prefix match misses: git -C <dir> push, rm -fr, rm -r -f,
// a wrapper such as env or rtk in front, or the call inside bash -c, $(...)
// or a pipeline. Anything else passes with no output.
//
// AIDEV-NOTE: not listed in codex's ~/.codex/hooks.json: a user-layer hook runs only after /hooks trusts its hash, and every store path change drops that trust (#137)
// AIDEV-NOTE: permissions.deny matches by prefix and let git -C <dir> push and rm -fr through (#127); adding more deny patterns was rejected because it grows with every wrapper and bash -c form
package deny

import (
	"io"
	"path/filepath"
	"strings"

	"github.com/Xantibody/dotfiles/tools/internal/pretooluse"
	"github.com/Xantibody/dotfiles/tools/internal/shell"
)

const (
	pushReason = "rat hook deny: git push is left to the user. Commit, then report the commit and let the user push."
	rmReason   = "rat hook deny: rm with both -r and -f is refused. Remove the specific files by name, or ask the user to delete the directory."
)

func run(stdin io.Reader, stdout io.Writer) error {
	cmd, err := pretooluse.Command(stdin)
	if err != nil {
		return err
	}
	reason := checkCommand(cmd)
	if reason == "" {
		return nil
	}
	return pretooluse.Decide(stdout, "deny", reason)
}

// checkCommand returns why cmd is refused, or "" when it may run.
func checkCommand(cmd string) string {
	for _, args := range shell.Commands(cmd) {
		var reason string
		switch filepath.Base(args[0]) {
		case "git":
			reason = checkGit(args[1:])
		case "rm":
			reason = checkRm(args[1:])
		}
		if reason != "" {
			return reason
		}
	}
	return ""
}

// gitGlobalWithArg are git's options before the subcommand that take the
// next word as their value.
var gitGlobalWithArg = []string{"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--super-prefix"}

func checkGit(args []string) string {
	args = shell.SkipOptions(args, gitGlobalWithArg)
	if len(args) > 0 && args[0] == "push" {
		return pushReason
	}
	return ""
}

func checkRm(args []string) string {
	recursive, force := false, false
	for _, a := range args {
		switch {
		case a == "--":
			return ""
		case a == "--recursive":
			recursive = true
		case a == "--force":
			force = true
		case strings.HasPrefix(a, "-") && !strings.HasPrefix(a, "--"):
			recursive = recursive || strings.ContainsAny(a, "rR")
			force = force || strings.Contains(a, "f")
		}
		if recursive && force {
			return rmReason
		}
	}
	return ""
}
