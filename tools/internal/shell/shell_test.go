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
		{"rat verify-gate run -- nix fmt", [][]string{{"nix", "fmt"}}},
		{"rat verify-gate run nix fmt", [][]string{{"nix", "fmt"}}},
		{"rat verify-gate commit-msg f", [][]string{{"rat", "verify-gate", "commit-msg", "f"}}},
		{"rat hook deny", [][]string{{"rat", "hook", "deny"}}},
		{"bash -eo pipefail -c 'git push; ls'", [][]string{{"git", "push"}, {"ls"}}},
		{"bash script.sh git push", [][]string{{"bash", "script.sh", "git", "push"}}},
		{"bash -c -- 'git push'", [][]string{{"git", "push"}}},
		{"bash -c - 'git push'", [][]string{{"git", "push"}}},
		{"bash -- script.sh", [][]string{{"bash", "--", "script.sh"}}},
		{"bash -x script.sh", [][]string{{"bash", "-x", "script.sh"}}},
		{"bash -x", [][]string{{"bash", "-x"}}},
		{"bash --rcfile rc -c 'git push'", [][]string{{"git", "push"}}},
		{"env -S", nil}, // env refuses -S without a string and runs nothing
		{"env -i -S 'git push'", [][]string{{"git", "push"}}},
		{"env --split-string 'git push' -f", [][]string{{"git", "push", "-f"}}},
		{"env --split-string='git push'", [][]string{{"git", "push"}}},
		{"env -u HOME -S 'git push'", [][]string{{"git", "push"}}},
		{"env -- -S git push", [][]string{{"-S", "git", "push"}}},
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

func TestLongValueOptions(t *testing.T) {
	for _, cmd := range []string{
		"sudo --user root git push",
		"sudo --chdir /tmp --close-from 3 git push",
		"timeout --signal KILL --kill-after 5 10 git push",
		"nice --adjustment 5 git push",
		"/usr/bin/time --format %e --output t git push", // a bare time is the shell keyword
		"xargs --max-args 1 --delimiter , git push",
	} {
		if diff := cmp.Diff([][]string{{"git", "push"}}, Commands(cmd)); diff != "" {
			t.Errorf("Commands(%q) mismatch (-want +got):\n%s", cmd, diff)
		}
	}
}

// An option whose argument is optional takes it only after =, so the word
// after it is the command.
func TestOptionalValueOptions(t *testing.T) {
	if diff := cmp.Diff([][]string{{"git", "push"}}, Commands("xargs --replace git push")); diff != "" {
		t.Errorf("mismatch (-want +got):\n%s", diff)
	}
}

func TestCallsWrapped(t *testing.T) {
	for _, tc := range []struct {
		cmd  string
		want []Call
	}{
		{"gh pr view", []Call{{Args: []string{"gh", "pr", "view"}}}},
		{"FOO=1 gh pr view", []Call{{Args: []string{"gh", "pr", "view"}}}},
		{"rtk gh pr view", []Call{{Args: []string{"gh", "pr", "view"}, Wrapped: true}}},
		{"timeout 30 ionice -c3 gh pr view", []Call{{Args: []string{"ionice", "-c3", "gh", "pr", "view"}, Wrapped: true}}},
		{"bash script.sh gh", []Call{{Args: []string{"bash", "script.sh", "gh"}, Wrapped: true}}},
		{"bash -c 'gh pr view'", []Call{{Args: []string{"gh", "pr", "view"}}}},
		{"rat hook deny", []Call{{Args: []string{"rat", "hook", "deny"}}}},
		{"echo gh", []Call{{Args: []string{"echo", "gh"}}}},
	} {
		if diff := cmp.Diff(tc.want, Calls(tc.cmd)); diff != "" {
			t.Errorf("Calls(%q) mismatch (-want +got):\n%s", tc.cmd, diff)
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
