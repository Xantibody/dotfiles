package shell

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestCommands(t *testing.T) {
	for _, tc := range []struct {
		cmd  string
		want [][]string
	}{
		{"", nil},
		{"git status", [][]string{{"git", "status"}}},
		{"git commit -m 'a b' && git push", [][]string{{"git", "commit", "-m", "a b"}, {"git", "push"}}},
		{"FOO=1 git push", [][]string{{"git", "push"}}},
		{"echo $(gh pr view)", [][]string{{"echo", "$(gh pr view)"}, {"gh", "pr", "view"}}},
		{"git $sub", [][]string{{"git", "$sub"}}},
		{`gh api "repos/$o/${r}/contents/x"`, [][]string{{"gh", "api", "repos/$o/${r}/contents/x"}}},
		{"env FOO=$x git push", [][]string{{"git", "push"}}},
		{"GH_TOKEN=t gh api x 'unterminated", [][]string{{"gh", "api", "x", "unterminated"}}},
		{"rtk proxy git push", [][]string{{"git", "push"}}},
		{"env -u PATH A=1 git push", [][]string{{"git", "push"}}},
		{"sudo -u me timeout 30 nice -n 10 git push", [][]string{{"git", "push"}}},
		{"verify-gate run -- nix fmt", [][]string{{"nix", "fmt"}}},
		{"verify-gate commit-msg f", [][]string{{"verify-gate", "commit-msg", "f"}}},
		{"bash -eo pipefail -c 'git push; ls'", [][]string{{"git", "push"}, {"ls"}}},
		{"bash script.sh git push", [][]string{{"bash", "script.sh", "git", "push"}}},
		{"eval git push", [][]string{{"git", "push"}}},
		{"env -S'git push' x", [][]string{{"git", "push", "x"}}},
		{"xargs -I {} rm {}", [][]string{{"rm", "{}"}}},
		{"rtk", nil},
		{"git push 'unterminated", [][]string{{"git", "push", "unterminated"}}},
	} {
		if diff := cmp.Diff(tc.want, Commands(tc.cmd)); diff != "" {
			t.Errorf("Commands(%q) mismatch (-want +got):\n%s", tc.cmd, diff)
		}
	}
}

func TestSkipOptions(t *testing.T) {
	for _, tc := range []struct {
		args, withArg, want []string
	}{
		{[]string{"-C", "dir", "push"}, []string{"-C"}, []string{"push"}},
		{[]string{"--no-pager", "push"}, nil, []string{"push"}},
		{[]string{"--", "-rf"}, nil, []string{"-rf"}},
		{[]string{"-C"}, []string{"-C"}, []string{}},
	} {
		if diff := cmp.Diff(tc.want, SkipOptions(tc.args, tc.withArg)); diff != "" {
			t.Errorf("SkipOptions(%q) mismatch (-want +got):\n%s", tc.args, diff)
		}
	}
}
