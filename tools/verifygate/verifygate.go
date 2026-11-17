// Package verifygate is the commit gate that records in each commit whether
// it was verified, as Verified-by trailers.
//
//	rat verify-gate run [--] <command>...  runs command and, when it passes, records it against the working tree's tree
//	rat verify-gate commit-msg <file>      git's commit-msg hook: the records of the committed tree become trailers
//
// A record is one line per command in <git-common-dir>/verify-gate/<tree>.
// The tree is a hash of the content, so changing a single byte after the run,
// or committing only part of the working tree, does not match and the trailer
// is "none". The mode is `git config verify.gate`: unset and off do nothing,
// observe records without stopping a commit.
//
// AIDEV-NOTE: enforce (refusing an unverified commit) waits until observe has shown the false positives; until then it fails as not implemented
package verifygate

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"syscall"
)

// exitError makes rat exit with code, printing msg to stderr when there is one.
type exitError struct {
	code int
	msg  string
}

func (e *exitError) Error() string { return e.msg }

func (e *exitError) ExitCode() int { return e.code }

func fail(format string, a ...any) error {
	return &exitError{code: 1, msg: "verify-gate: " + fmt.Sprintf(format, a...)}
}

// Run runs the command and, when it passes inside a git working tree, records
// it against the tree of the working tree as it stands after the run. A
// failing command's exit code is handed back with nothing recorded.
func Run(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		return fail("usage: rat verify-gate run [--] <command>...")
	}
	c := exec.Command(args[0], args[1:]...)
	c.Stdin, c.Stdout, c.Stderr = stdin, stdout, stderr
	if err := c.Run(); err != nil {
		var exit *exec.ExitError
		if errors.As(err, &exit) {
			return &exitError{code: exitCode(exit)}
		}
		return &exitError{code: 127, msg: "verify-gate: " + err.Error()}
	}
	if inside, err := git(nil, nil, "rev-parse", "--is-inside-work-tree"); err != nil || inside != "true" {
		return nil
	}

	label := strings.Join(args, " ")
	prefix, err := git(nil, nil, "rev-parse", "--show-prefix")
	if err != nil {
		return fail("%v", err)
	}
	if prefix != "" {
		label += " (in " + strings.TrimSuffix(prefix, "/") + ")"
	}
	// the command may rewrite files (a formatter), so the tree is taken after it
	tree, err := worktreeTree()
	if err != nil {
		return fail("%v", err)
	}
	file, err := recordFile(tree)
	if err != nil {
		return fail("%v", err)
	}
	if err := record(file, label); err != nil {
		return fail("%v", err)
	}
	fmt.Fprintf(stderr, "verify-gate: recorded '%s' for tree %s\n", label, tree)
	return nil
}

// exitCode is the code a shell would report: 128 + the signal for a command
// killed by one.
func exitCode(exit *exec.ExitError) int {
	if ws, ok := exit.Sys().(syscall.WaitStatus); ok && ws.Signaled() {
		return 128 + int(ws.Signal())
	}
	return exit.ExitCode()
}

// worktreeTree is the tree of the working tree itself, untracked files that
// are not ignored included. It is built in a temporary index, so the user's
// index is left alone.
func worktreeTree() (string, error) {
	tmp, err := os.MkdirTemp("", "verify-gate")
	if err != nil {
		return "", err
	}
	defer os.RemoveAll(tmp)
	index, err := git(nil, nil, "rev-parse", "--path-format=absolute", "--git-path", "index")
	if err != nil {
		return "", err
	}
	tmpIndex := filepath.Join(tmp, "index")
	if data, err := os.ReadFile(index); err == nil {
		if err := os.WriteFile(tmpIndex, data, 0o600); err != nil {
			return "", err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return "", err
	}
	env := []string{"GIT_INDEX_FILE=" + tmpIndex}
	if _, err := git(env, nil, "add", "-A"); err != nil {
		return "", err
	}
	return git(env, nil, "write-tree")
}

// recordFile is where the records of tree are kept, shared by every worktree
// of the repository.
func recordFile(tree string) (string, error) {
	common, err := git(nil, nil, "rev-parse", "--path-format=absolute", "--git-common-dir")
	if err != nil {
		return "", err
	}
	return filepath.Join(common, "verify-gate", tree), nil
}

// record appends label to file unless it is there already.
func record(file, label string) error {
	if err := os.MkdirAll(filepath.Dir(file), 0o755); err != nil {
		return err
	}
	if slices.Contains(readLines(file), label) {
		return nil
	}
	f, err := os.OpenFile(file, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	if _, err := fmt.Fprintln(f, label); err != nil {
		f.Close()
		return err
	}
	return f.Close()
}

// readLines lists the non-empty lines of file, none when it is missing.
func readLines(file string) []string {
	data, err := os.ReadFile(file)
	if err != nil {
		return nil
	}
	var lines []string
	for line := range strings.Lines(string(data)) {
		if line = strings.TrimSuffix(line, "\n"); line != "" {
			lines = append(lines, line)
		}
	}
	return lines
}

// CommitMsg is the commit-msg hook: it replaces the Verified-by trailers of
// the message in file with the records of the tree being committed, or
// "none" when there are none.
func CommitMsg(file string) error {
	mode, _ := git(nil, nil, "config", "--get", "verify.gate") // unset exits 1
	switch mode {
	case "", "off":
		return nil
	case "observe":
	case "enforce":
		return fail("verify.gate=enforce is not implemented yet; set it to observe or off")
	default:
		return fail("unknown verify.gate value '%s'; set it to observe or off", mode)
	}

	msg, err := os.ReadFile(file)
	if err != nil {
		return fail("%v", err)
	}
	// git aborts a commit with an empty message; a trailer would make it
	// non-empty and let through a commit meant to be aborted
	if body, err := git(nil, bytes.NewReader(msg), "stripspace", "--strip-comments"); err != nil {
		return fail("%v", err)
	} else if body == "" {
		return nil
	}

	// an amend still carries the previous trailers, so they are dropped and
	// written again for the tree committed now
	var kept strings.Builder
	for line := range strings.Lines(string(msg)) {
		if !strings.HasPrefix(line, "Verified-by: ") {
			kept.WriteString(line)
		}
	}
	if err := os.WriteFile(file, []byte(kept.String()), 0o644); err != nil {
		return fail("%v", err)
	}

	// inside the hook git passes GIT_INDEX_FILE, so write-tree returns the
	// tree being committed, for `commit -a` and a commit of paths too
	tree, err := git(nil, nil, "write-tree")
	if err != nil {
		return fail("%v", err)
	}
	records, err := recordFile(tree)
	if err != nil {
		return fail("%v", err)
	}
	labels := readLines(records)
	if len(labels) == 0 {
		labels = []string{"none"}
	}
	args := []string{"interpret-trailers", "--in-place"}
	for _, label := range labels {
		args = append(args, "--trailer", "Verified-by: "+label)
	}
	if _, err := git(nil, nil, append(args, file)...); err != nil {
		return fail("%v", err)
	}
	return nil
}

// git runs git with env added to the environment and returns its stdout
// without the final newline; an error carries git's stderr.
func git(env []string, stdin io.Reader, args ...string) (string, error) {
	c := exec.Command("git", args...)
	if env != nil {
		c.Env = append(os.Environ(), env...)
	}
	c.Stdin = stdin
	var stderr bytes.Buffer
	c.Stderr = &stderr
	out, err := c.Output()
	if err != nil {
		return "", fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(stderr.String()))
	}
	return strings.TrimSuffix(string(out), "\n"), nil
}
