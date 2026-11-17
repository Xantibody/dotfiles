package lintbody

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/Xantibody/dotfiles/tools/internal/pretooluse"
)

// fakeLintBody stands in for lint-body: it reports a finding, with the path
// it was given, when the file has a line containing NG. Only shell builtins,
// so PATH can hold nothing but the fake.
const fakeLintBody = `#!/bin/sh
while IFS= read -r l || [ -n "$l" ]; do
  case $l in *NG*) echo "$1: NG found"; exit 1 ;; esac
done < "$1"
`

// setup puts the fake lint-body alone on PATH and returns a cwd holding
// ok.md and ng.md.
func setup(t *testing.T) string {
	t.Helper()
	bin := t.TempDir()
	if err := os.WriteFile(filepath.Join(bin, "lint-body"), []byte(fakeLintBody), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", bin)
	cwd := t.TempDir()
	for name, body := range map[string]string{"ok.md": "fine\n", "ng.md": "an NG line\n"} {
		if err := os.WriteFile(filepath.Join(cwd, name), []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return cwd
}

const useBodyFile = "本文は --body ではなく --body-file で渡す。lint-body にかけられないので止めた"

func findings(path string) string {
	return "本文に textlint / osekkai の指摘が残っている。直してから再実行する (fix 可能なものは lint-body --fix " +
		path + ")\n" + path + ": NG found"
}

func TestCheck(t *testing.T) {
	cwd := setup(t)
	ng := cwd + "/ng.md"
	for _, tc := range []struct {
		cmd  string
		want string // the block message, "" to pass
	}{
		{"", ""},
		{"git status", ""},
		{"gh pr view 12", ""},
		{"gh pr list --body x", ""},
		{"gh pr create --fill", ""},
		{"gh pr create --title t --body-file ok.md", ""},
		{"gh pr create --body-file " + cwd + "/ok.md", ""},
		{"gh pr create --body-file ng.md", findings(ng)},
		{"gh pr create --body-file=ng.md", findings(ng)},
		{`gh pr create --body-file "ng.md"`, findings(ng)},
		{"gh pr create --body-file 'ng.md'", findings(ng)},
		{"gh pr create --body-file " + ng, findings(ng)},
		{"gh pr edit 3 --body-file ng.md", findings(ng)},
		{"gh pr comment 3 --body-file ng.md", findings(ng)},
		{"gh issue create --title t --body-file ng.md", findings(ng)},
		{"gh issue edit 3 --body-file ng.md", findings(ng)},
		{"gh issue comment 3 --body-file ng.md", findings(ng)},
		{"git push && gh pr create --body-file ng.md", findings(ng)},
		{"git status; gh pr create --body-file ng.md", findings(ng)},
		{"gh pr create --title t --body x", useBodyFile},
		{"gh pr create -b x", useBodyFile},
		{"gh pr create --body=x", useBodyFile},
		{"gh pr create -b=x", useBodyFile},
		{"gh pr create --body-file ok.md --body x", useBodyFile},
		{"gh issue comment 3 --body 'some text'", useBodyFile},
		{"gh pr create --body-file $f",
			"--body-file は変数や置換ではなくリテラルなパスで渡す。hook はこの Bash 呼び出しの外の値を見られない: $f"},
		{`gh pr create --body-file "$(pwd)/ng.md"`,
			"--body-file は変数や置換ではなくリテラルなパスで渡す。hook はこの Bash 呼び出しの外の値を見られない: $(pwd)/ng.md"},
		{"gh pr create --body-file missing.md", "--body-file が見つからない: " + cwd + "/missing.md"},
		{"gh pr create --body-file " + cwd, "--body-file が見つからない: " + cwd},
		// a heredoc or an echo that only mentions gh is not a gh call
		{"cat > notes.md <<'EOF'\ngh pr create --body x\nEOF", ""},
		{"cat > notes.md <<-EOF\n\tgh pr create --body-file missing.md\n\tEOF\ngit status", ""},
		{`echo "gh pr create --body x"`, ""},
		{"echo run gh pr create --body-file ng.md", ""},
		// beyond the table the shell hook had: a wrapper in front of gh
		{"rtk gh pr create --body-file ng.md", findings(ng)},
		{"bash -c 'gh issue create --body x'", useBodyFile},
	} {
		got := ""
		if err := check(tc.cmd, cwd); err != nil {
			var block *pretooluse.BlockError
			if !errors.As(err, &block) {
				t.Errorf("check(%q) = %v, want a block or nil", tc.cmd, err)
				continue
			}
			got = block.Message
		}
		if diff := cmp.Diff(tc.want, got); diff != "" {
			t.Errorf("check(%q) block message (-want +got):\n%s", tc.cmd, diff)
		}
	}
}

func TestCheckBlocksWithoutLintBody(t *testing.T) {
	cwd := setup(t)
	t.Setenv("PATH", t.TempDir())
	err := check("gh pr create --body-file ok.md", cwd)
	var block *pretooluse.BlockError
	if !errors.As(err, &block) || !strings.Contains(block.Message, "lint-body") {
		t.Errorf("check without lint-body on PATH = %v, want a block naming lint-body", err)
	}
}

func TestRun(t *testing.T) {
	cwd := setup(t)
	in := `{"cwd":"` + cwd + `","tool_name":"Bash","tool_input":{"command":"gh pr create --body-file ng.md"}}`
	if diff := cmp.Diff(&pretooluse.BlockError{Message: findings(cwd + "/ng.md")}, run(strings.NewReader(in))); diff != "" {
		t.Errorf("run (-want +got):\n%s", diff)
	}
	if err := run(strings.NewReader(`{"tool_name":"Bash","tool_input":{}}`)); err != nil {
		t.Errorf("run without a command = %v, want nil", err)
	}
}

func TestRunRejectsBadInput(t *testing.T) {
	err := run(strings.NewReader("not json"))
	var block *pretooluse.BlockError
	if err == nil || errors.As(err, &block) {
		t.Errorf("run(not json) = %v, want an error that does not block", err)
	}
}
