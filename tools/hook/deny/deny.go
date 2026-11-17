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
	"encoding/json"
	"fmt"
	"io"
	"path/filepath"
	"slices"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

const (
	pushReason = "rat hook deny: git push is left to the user. Commit, then report the commit and let the user push."
	rmReason   = "rat hook deny: rm with both -r and -f is refused. Remove the specific files by name, or ask the user to delete the directory."
)

func run(stdin io.Reader, stdout io.Writer) error {
	var in struct {
		ToolInput struct {
			Command string `json:"command"`
		} `json:"tool_input"`
	}
	if err := json.NewDecoder(stdin).Decode(&in); err != nil {
		return fmt.Errorf("read hook input: %w", err)
	}
	reason := checkCommand(in.ToolInput.Command)
	if reason == "" {
		return nil
	}
	type output struct {
		HookEventName            string `json:"hookEventName"`
		PermissionDecision       string `json:"permissionDecision"`
		PermissionDecisionReason string `json:"permissionDecisionReason"`
	}
	return json.NewEncoder(stdout).Encode(map[string]output{
		"hookSpecificOutput": {"PreToolUse", "deny", reason},
	})
}

// checkCommand returns why cmd is refused, or "" when it may run.
func checkCommand(cmd string) string {
	for _, args := range calls(cmd) {
		if reason := checkCall(args); reason != "" {
			return reason
		}
	}
	return ""
}

// calls lists every simple command in cmd, nested ones included. A word that
// is not a plain literal ($x, $(...)) becomes "", which matches no rule.
func calls(cmd string) [][]string {
	file, err := syntax.NewParser().Parse(strings.NewReader(cmd), "")
	if err != nil {
		// AIDEV-NOTE: a parse error falls back to splitting on separators rather than allowing, so broken quoting cannot hide a push
		var out [][]string
		for _, seg := range strings.FieldsFunc(cmd, func(r rune) bool { return strings.ContainsRune(";&|()\n`", r) }) {
			if f := strings.Fields(seg); len(f) > 0 {
				for i := range f {
					f[i] = strings.Trim(f[i], `'"`)
				}
				out = append(out, f)
			}
		}
		return out
	}
	var out [][]string
	syntax.Walk(file, func(node syntax.Node) bool {
		if call, ok := node.(*syntax.CallExpr); ok && len(call.Args) > 0 {
			args := make([]string, len(call.Args))
			for i, w := range call.Args {
				args[i] = literal(w)
			}
			out = append(out, args)
		}
		return true
	})
	return out
}

func literal(w *syntax.Word) string {
	var b strings.Builder
	for _, part := range w.Parts {
		switch p := part.(type) {
		case *syntax.Lit:
			b.WriteString(unescape(p.Value))
		case *syntax.SglQuoted:
			b.WriteString(p.Value)
		case *syntax.DblQuoted:
			for _, q := range p.Parts {
				lit, ok := q.(*syntax.Lit)
				if !ok {
					return ""
				}
				b.WriteString(lit.Value)
			}
		default:
			return ""
		}
	}
	return b.String()
}

func unescape(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); i++ {
		if s[i] == '\\' && i+1 < len(s) {
			i++
		}
		b.WriteByte(s[i])
	}
	return b.String()
}

// wrappers run the command after their own options. The value lists the
// options that take a separate argument, so that argument is not mistaken
// for the command.
var wrappers = map[string][]string{
	"builtin": nil,
	"command": nil,
	"doas":    {"-u", "-C"},
	"env":     {"-u", "-C", "--unset", "--chdir"},
	"exec":    {"-a"},
	"nice":    {"-n"},
	"nohup":   nil,
	"rtk":     nil,
	"sudo":    {"-u", "-g", "-C", "-D", "-h", "-p", "-r", "-t", "-U"},
	"time":    {"-f", "-o"},
	"timeout": {"-k", "-s"},
	// verify-gate run [--] <command> (modules/git/verify-gate.sh), which the
	// check skill puts in front of every check where the commit gate is on
	"verify-gate": nil,
	"xargs":       {"-a", "-d", "-E", "-I", "-L", "-n", "-P", "-s"},
}

var shells = map[string]bool{"bash": true, "dash": true, "ksh": true, "sh": true, "zsh": true}

func checkCall(args []string) string {
	for len(args) > 0 {
		name := filepath.Base(args[0])
		switch {
		case name == "git":
			return checkGit(args[1:])
		case name == "rm":
			return checkRm(args[1:])
		case name == "eval":
			return checkCommand(strings.Join(args[1:], " "))
		case shells[name]:
			if script, ok := shellScript(args[1:]); ok {
				return checkCommand(script)
			}
			return ""
		case name == "env":
			if cmd, ok := envSplitString(args[1:]); ok {
				return checkCommand(cmd)
			}
		}
		withArg, ok := wrappers[name]
		if !ok {
			return ""
		}
		args = skipOptions(args[1:], withArg)
		switch name {
		case "env":
			for len(args) > 0 && strings.Contains(args[0], "=") {
				args = args[1:]
			}
		case "timeout":
			if len(args) > 0 {
				args = args[1:] // the duration
			}
		case "rtk":
			if len(args) > 0 && args[0] == "proxy" {
				args = args[1:]
			}
		case "verify-gate":
			if len(args) == 0 || args[0] != "run" {
				return ""
			}
			args = skipOptions(args[1:], nil)
		}
	}
	return ""
}

func skipOptions(args, withArg []string) []string {
	for len(args) > 0 && strings.HasPrefix(args[0], "-") {
		takesArg := false
		for _, o := range withArg {
			if args[0] == o {
				takesArg = true
			}
		}
		if args[0] == "--" {
			return args[1:]
		}
		args = args[1:]
		if takesArg && len(args) > 0 {
			args = args[1:]
		}
	}
	return args
}

// shellScript finds the script of `sh -c <script>`, with -c alone or in a
// group such as -ec. As in bash, the script is the first word after the
// options, so -c may come before other options; -o and -O (or +o, +O, or in a
// group such as -eo) take the next word as a value, as do --rcfile and
// --init-file, and other long options take none.
func shellScript(args []string) (string, bool) {
	sawC := false
	for i := 0; i < len(args); i++ {
		a := args[i]
		switch {
		case a == "--" || a == "-":
			if sawC && i+1 < len(args) {
				return args[i+1], true
			}
			return "", false
		case a == "--rcfile" || a == "--init-file":
			i++
		case strings.HasPrefix(a, "--"):
		case len(a) > 1 && (a[0] == '-' || a[0] == '+'):
			sawC = sawC || (a[0] == '-' && strings.Contains(a, "c"))
			if strings.ContainsAny(a[1:], "oO") {
				i++
			}
		default:
			return a, sawC
		}
	}
	return "", false
}

// envSplitString finds the command of `env -S <string> [args]` (also -S<string>,
// --split-string=<string> and --split-string <string>): env splits the string
// into words and runs them followed by the remaining arguments.
func envSplitString(args []string) (string, bool) {
	for i := 0; i < len(args); i++ {
		a := args[i]
		var s string
		switch {
		case a == "-S" || a == "--split-string":
			if i+1 >= len(args) {
				return "", false
			}
			i++
			s = args[i]
		case strings.HasPrefix(a, "--split-string="):
			s = strings.TrimPrefix(a, "--split-string=")
		case strings.HasPrefix(a, "-S"):
			s = a[2:]
		case slices.Contains(wrappers["env"], a):
			i++
			continue
		case a == "--" || !strings.HasPrefix(a, "-"):
			return "", false
		default:
			continue
		}
		return strings.Join(append([]string{s}, args[i+1:]...), " "), true
	}
	return "", false
}

// gitGlobalWithArg are git's options before the subcommand that take the
// next word as their value.
var gitGlobalWithArg = []string{"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env", "--super-prefix"}

func checkGit(args []string) string {
	args = skipOptions(args, gitGlobalWithArg)
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
