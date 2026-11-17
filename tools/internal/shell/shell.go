// Package shell lists the commands a Bash tool call would run, for the hooks
// that decide on a command by its name and arguments. It parses with
// mvdan.cc/sh, descends into nested commands ($(...), pipelines, subshells),
// strips wrappers such as env, sudo or rtk, and expands the script of
// sh -c, eval and env -S, so a rule written for `git push` also sees
// `rtk proxy git push` and `bash -c 'git push'`.
package shell

import (
	"path/filepath"
	"slices"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

// Commands lists every simple command in cmd as the words it runs, wrappers
// stripped and nested ones included. Quotes are removed; an expansion ($x,
// $(...)) is kept as written.
func Commands(cmd string) [][]string {
	var out [][]string
	for _, args := range calls(cmd) {
		out = append(out, unwrap(args)...)
	}
	return out
}

// calls lists every simple command in cmd as written, nested ones included.
func calls(cmd string) [][]string {
	file, err := syntax.NewParser().Parse(strings.NewReader(cmd), "")
	if err != nil {
		// AIDEV-NOTE: a parse error falls back to splitting on separators rather than allowing, so broken quoting cannot hide a command from a hook
		var out [][]string
		for _, seg := range strings.FieldsFunc(cmd, func(r rune) bool { return strings.ContainsRune(";&|()\n`", r) }) {
			if f := strings.Fields(seg); len(f) > 0 {
				for i := range f {
					f[i] = strings.Trim(f[i], `'"`)
				}
				// leading assignments, as the parser would have taken them
				for len(f) > 0 && strings.Contains(f[0], "=") {
					f = f[1:]
				}
				if len(f) > 0 {
					out = append(out, f)
				}
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

// literal is the word with its quotes removed. A part that is not a plain
// literal ($x, $(...)) keeps its source text, so a rule matching a path
// such as repos/$o/r/contents still sees it.
// AIDEV-NOTE: an expansion keeps its source rather than becoming "", which let env FOO=$x git push through and hid repos/$o/... from gh-guard
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
				if lit, ok := q.(*syntax.Lit); ok {
					b.WriteString(lit.Value)
				} else {
					source(&b, q)
				}
			}
		default:
			source(&b, part)
		}
	}
	return b.String()
}

func source(b *strings.Builder, node syntax.Node) {
	_ = syntax.NewPrinter().Print(b, node) // a strings.Builder does not fail
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
	// rat verify-gate run [--] <command> (tools/verifygate), which the check
	// skill puts in front of every check where the commit gate is on; rat's
	// other subcommands are commands of their own
	"rat":     nil,
	"rtk":     nil,
	"sudo":    {"-u", "-g", "-C", "-D", "-h", "-p", "-r", "-t", "-U"},
	"time":    {"-f", "-o"},
	"timeout": {"-k", "-s"},
	"xargs":   {"-a", "-d", "-E", "-I", "-L", "-n", "-P", "-s"},
}

var shells = map[string]bool{"bash": true, "dash": true, "ksh": true, "sh": true, "zsh": true}

// unwrap strips the wrappers in front of args and returns the command they
// run; eval, sh -c and env -S expand to the commands of their script. A shell
// running a script file, or rat with a subcommand other than verify-gate run,
// is returned as it is.
func unwrap(args []string) [][]string {
	for len(args) > 0 {
		name := filepath.Base(args[0])
		switch {
		case name == "eval":
			return Commands(strings.Join(args[1:], " "))
		case shells[name]:
			if script, ok := shellScript(args[1:]); ok {
				return Commands(script)
			}
			return [][]string{args}
		case name == "env":
			if cmd, ok := envSplitString(args[1:]); ok {
				return Commands(cmd)
			}
		}
		withArg, ok := wrappers[name]
		if !ok {
			return [][]string{args}
		}
		rest := SkipOptions(args[1:], withArg)
		switch name {
		case "env":
			for len(rest) > 0 && strings.Contains(rest[0], "=") {
				rest = rest[1:]
			}
		case "timeout":
			if len(rest) > 0 {
				rest = rest[1:] // the duration
			}
		case "rtk":
			if len(rest) > 0 && rest[0] == "proxy" {
				rest = rest[1:]
			}
		case "rat":
			if len(rest) < 2 || rest[0] != "verify-gate" || rest[1] != "run" {
				return [][]string{args}
			}
			rest = SkipOptions(rest[2:], nil)
		}
		args = rest
	}
	return nil
}

// SkipOptions drops the leading options of args and returns the rest. An
// option in withArg also drops the word after it, its value; "--" ends the
// options and is dropped.
func SkipOptions(args, withArg []string) []string {
	for len(args) > 0 && strings.HasPrefix(args[0], "-") {
		takesArg := slices.Contains(withArg, args[0])
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
