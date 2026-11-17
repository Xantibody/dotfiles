// Package lintbody is `rat hook lint-body`, a PreToolUse hook for Claude
// Code's Bash tool. It runs `lint-body` from PATH on the file that
// gh pr / issue create, edit or comment gets through --body-file, and while
// findings remain it blocks the command with exit code 2, the findings on
// stderr for Claude. A body passed with --body cannot be linted, so that is
// blocked too.
//
// The hook is registered by the frontmatter of the pull-request and issue
// skills, not settings.json: it is active only in a session that invoked one
// of them, and other Bash calls do not carry it.
//
// AIDEV-NOTE: each Bash call is its own process, so --body-file must be a literal path; a variable or substitution is refused rather than guessed at
// AIDEV-NOTE: the command is parsed with mvdan.cc/sh rather than grepped, so gh written in a heredoc or an echo (a report quoting gh) does not lint twice, and a wrapper (rtk gh) does not hide it
package lintbody

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/Xantibody/dotfiles/tools/internal/pretooluse"
	"github.com/Xantibody/dotfiles/tools/internal/shell"
)

func run(stdin io.Reader) error {
	in, err := pretooluse.Read(stdin)
	if err != nil {
		return err
	}
	return check(in.Command, in.Cwd)
}

// check returns a *pretooluse.BlockError for the first gh call in cmd whose
// body cannot be linted or has findings, nil when there is none.
func check(cmd, cwd string) error {
	for _, args := range shell.Commands(cmd) {
		if !postsBody(args) {
			continue
		}
		if err := checkBody(args[3:], cwd); err != nil {
			return err
		}
	}
	return nil
}

// postsBody reports whether args is gh pr / issue create, edit or comment.
func postsBody(args []string) bool {
	if len(args) < 3 || filepath.Base(args[0]) != "gh" {
		return false
	}
	switch args[1] {
	case "pr", "issue":
	default:
		return false
	}
	switch args[2] {
	case "create", "edit", "comment":
		return true
	}
	return false
}

func checkBody(args []string, cwd string) error {
	path, found := "", false
	for i, a := range args {
		if a == "--body" || a == "-b" || strings.HasPrefix(a, "--body=") || strings.HasPrefix(a, "-b=") {
			return pretooluse.Block("本文は --body ではなく --body-file で渡す。lint-body にかけられないので止めた")
		}
		if found {
			continue
		}
		switch {
		case a == "--body-file" && i+1 < len(args):
			path, found = args[i+1], true
		case strings.HasPrefix(a, "--body-file="):
			path, found = strings.TrimPrefix(a, "--body-file="), true
		}
	}
	if !found {
		return nil
	}

	if strings.ContainsAny(path, "$(") {
		return pretooluse.Block("--body-file は変数や置換ではなくリテラルなパスで渡す。hook はこの Bash 呼び出しの外の値を見られない: " + path)
	}
	if !strings.HasPrefix(path, "/") {
		// joined as the shell hook did, so the message shows the path unchanged
		path = cwd + "/" + path
	}
	if fi, err := os.Stat(path); err != nil || !fi.Mode().IsRegular() {
		return pretooluse.Block("--body-file が見つからない: " + path)
	}

	out, err := exec.Command("lint-body", path).CombinedOutput()
	var exit *exec.ExitError
	switch {
	case err == nil:
		return nil
	case !errors.As(err, &exit):
		// AIDEV-NOTE: a lint-body that cannot run blocks rather than passes, so a missing tool never lets an unlinted body through
		return pretooluse.Block(fmt.Sprintf("lint-body を実行できない。本文を lint できないので止めた: %v", err))
	}
	return pretooluse.Block("本文に textlint / osekkai の指摘が残っている。直してから再実行する (fix 可能なものは lint-body --fix " +
		path + ")\n" + strings.TrimRight(string(out), "\n"))
}
