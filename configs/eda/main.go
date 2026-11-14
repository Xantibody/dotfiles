// eda keeps git worktrees for every repository in one directory, records why
// each was made, and says which ones are finished. It is driven by an agent,
// not typed by hand: no prompts, no fuzzy finder, no shell integration.
package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

const usage = `usage: eda <command>

  new <branch> [--purpose <text>] [--base <commit>]
      Create a branch and its worktree under the eda root; print the path.
  status [--json] [--no-pr] [--stale-days <n>]
      Judge every worktree of every known repository: done, active or stale.
`

// env is everything a command reads from the outside, so tests can replace it.
type env struct {
	home  string
	cwd   string
	root  string // every worktree eda creates lives below this
	state string // holds the list of repositories eda has seen
	gh    string // gh binary; empty turns pull-request lookups off
	now   func() time.Time

	stdin  io.Reader
	stdout io.Writer
	stderr io.Writer
}

func defaultEnv() (*env, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}
	cwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}
	root := os.Getenv("EDA_ROOT")
	if root == "" {
		root = filepath.Join(xdg("XDG_DATA_HOME", home, ".local", "share"), "eda")
	}
	gh := "gh"
	if v, ok := os.LookupEnv("EDA_GH"); ok {
		gh = v
	}
	return &env{
		home:   home,
		cwd:    cwd,
		root:   root,
		state:  filepath.Join(xdg("XDG_STATE_HOME", home, ".local", "state"), "eda"),
		gh:     gh,
		now:    time.Now,
		stdin:  os.Stdin,
		stdout: os.Stdout,
		stderr: os.Stderr,
	}, nil
}

func xdg(name, home string, fallback ...string) string {
	if v := os.Getenv(name); v != "" {
		return v
	}
	return filepath.Join(append([]string{home}, fallback...)...)
}

func main() {
	e, err := defaultEnv()
	if err != nil {
		fmt.Fprintln(os.Stderr, "eda:", err)
		os.Exit(1)
	}
	os.Exit(run(os.Args[1:], e))
}

func run(args []string, e *env) int {
	if len(args) == 0 {
		fmt.Fprint(e.stderr, usage)
		return 2
	}
	var err error
	switch args[0] {
	case "new":
		err = cmdNew(args[1:], e)
	case "status":
		err = cmdStatus(args[1:], e)
	case "help", "-h", "--help":
		fmt.Fprint(e.stdout, usage)
		return 0
	default:
		fmt.Fprintf(e.stderr, "eda: unknown command %q\n%s", args[0], usage)
		return 2
	}
	if err != nil {
		fmt.Fprintln(e.stderr, "eda:", err)
		return 1
	}
	return 0
}

func newFlags(name string, e *env) *flag.FlagSet {
	fs := flag.NewFlagSet("eda "+name, flag.ContinueOnError)
	fs.SetOutput(e.stderr)
	return fs
}

// parseArgs accepts flags before, between and after the positional
// arguments; the flag package alone stops at the first positional.
func parseArgs(fs *flag.FlagSet, args []string) ([]string, error) {
	var pos []string
	for {
		if err := fs.Parse(args); err != nil {
			return nil, err
		}
		if fs.NArg() == 0 {
			return pos, nil
		}
		pos = append(pos, fs.Arg(0))
		args = fs.Args()[1:]
	}
}

func cmdNew(args []string, e *env) error {
	fs := newFlags("new", e)
	purpose := fs.String("purpose", "", "why this worktree exists; status shows it")
	base := fs.String("base", "HEAD", "commit the branch starts from")
	pos, err := parseArgs(fs, args)
	if err != nil {
		return err
	}
	if len(pos) != 1 {
		return fmt.Errorf("new takes exactly one branch name")
	}
	path, err := create(e, e.cwd, pos[0], *base, meta{Purpose: *purpose})
	if err != nil {
		return err
	}
	fmt.Fprintln(e.stdout, path)
	return nil
}

func cmdStatus(args []string, e *env) error {
	fs := newFlags("status", e)
	asJSON := fs.Bool("json", false, "print JSON")
	opts := judgeFlags(fs)
	if _, err := parseArgs(fs, args); err != nil {
		return err
	}
	all, err := collect(e, *opts)
	if err != nil {
		return err
	}
	if *asJSON {
		return printJSON(e.stdout, all)
	}
	printText(e.stdout, all)
	return nil
}
