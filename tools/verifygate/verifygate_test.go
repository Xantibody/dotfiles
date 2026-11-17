package verifygate

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

// hookEnv makes the test binary act as `rat verify-gate`, so git can run it
// as the commit-msg hook of the repositories the tests make.
const hookEnv = "RAT_VERIFY_GATE_TEST_HOOK"

func TestMain(m *testing.M) {
	if os.Getenv(hookEnv) == "1" {
		os.Exit(asRat(os.Args[1:]))
	}
	os.Exit(m.Run())
}

// asRat runs `rat verify-gate <args>` the way rat's main does.
func asRat(args []string) int {
	return cli.Main(cli.Root(Command()), append([]string{"verify-gate"}, args...), os.Stdin, os.Stdout, os.Stderr)
}

// fresh makes a repository with one commit, with this test binary as the
// commit-msg hook in a global git config of its own, and moves into it.
// mode is the verify.gate value, "" for unset.
func fresh(t *testing.T, mode string) string {
	t.Helper()
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("GIT_CONFIG_NOSYSTEM", "1")
	t.Setenv("GIT_CONFIG_GLOBAL", filepath.Join(home, "gitconfig"))
	self, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	for _, kv := range [][2]string{
		{"user.name", "test"},
		{"user.email", "test@example.com"},
		{"init.defaultBranch", "main"},
		{"hook.verify-gate.event", "commit-msg"},
		{"hook.verify-gate.command", fmt.Sprintf("%s=1 '%s' commit-msg", hookEnv, self)},
	} {
		gitT(t, "config", "--global", kv[0], kv[1])
	}
	repo := filepath.Join(home, "repo")
	if err := os.Mkdir(repo, 0o755); err != nil {
		t.Fatal(err)
	}
	t.Chdir(repo)
	gitT(t, "init", "-q")
	write(t, "base", "base")
	gitT(t, "add", "base")
	gitT(t, "commit", "-q", "-m", "base")
	if mode != "" {
		gitT(t, "config", "verify.gate", mode)
	}
	return repo
}

func gitT(t *testing.T, args ...string) string {
	t.Helper()
	out, err := exec.Command("git", args...).CombinedOutput()
	if err != nil {
		t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
	}
	return strings.TrimSuffix(string(out), "\n")
}

func write(t *testing.T, name, content string) {
	t.Helper()
	if err := os.WriteFile(name, []byte(content+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
}

// gate runs `rat verify-gate <args>` in this process, in the current directory.
func gate(t *testing.T, args ...string) error {
	t.Helper()
	cmd := Command()
	cmd.SetArgs(args)
	cmd.SetIn(strings.NewReader(""))
	cmd.SetOut(&bytes.Buffer{})
	cmd.SetErr(&bytes.Buffer{})
	return cmd.Execute()
}

func pass(t *testing.T, args ...string) {
	t.Helper()
	if err := gate(t, append([]string{"run", "--"}, args...)...); err != nil {
		t.Fatalf("verify-gate run -- %s: %v", strings.Join(args, " "), err)
	}
}

func expectTrailers(t *testing.T, want string) {
	t.Helper()
	got := gitT(t, "log", "-1", "--format=%(trailers:key=Verified-by,valueonly,separator=%x2C)")
	if got != want {
		t.Errorf("Verified-by trailers = %q, want %q", got, want)
	}
}

func TestGate(t *testing.T) {
	for _, tc := range []struct {
		name  string
		mode  string
		steps func(t *testing.T)
	}{
		{"gate unset adds nothing", "", func(t *testing.T) {
			pass(t, "true")
			write(t, "a", "a")
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "gate unset")
			expectTrailers(t, "")
		}},
		{"off adds nothing", "off", func(t *testing.T) {
			pass(t, "true")
			write(t, "a", "a")
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "off")
			expectTrailers(t, "")
		}},
		{"no verification records none", "observe", func(t *testing.T) {
			write(t, "a", "a")
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "no run")
			expectTrailers(t, "none")
		}},
		{"passing commands on the committed tree are recorded", "observe", func(t *testing.T) {
			write(t, "a", "a")
			pass(t, "true")
			pass(t, "echo", "ok")
			pass(t, "true") // recorded once
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "verified")
			expectTrailers(t, "true,echo ok")
		}},
		{"a run in a subdir names the dir", "observe", func(t *testing.T) {
			if err := os.Mkdir("sub", 0o755); err != nil {
				t.Fatal(err)
			}
			write(t, "sub/a", "a")
			repo, _ := os.Getwd()
			t.Chdir("sub")
			pass(t, "true")
			t.Chdir(repo)
			gitT(t, "add", "sub")
			gitT(t, "commit", "-q", "-m", "from a subdir")
			expectTrailers(t, "true (in sub)")
		}},
		{"a failing command is not recorded", "observe", func(t *testing.T) {
			write(t, "a", "a")
			if err := gate(t, "run", "--", "false"); err == nil {
				t.Error("run -- false succeeded, want its exit code")
			}
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "failed")
			expectTrailers(t, "none")
		}},
		{"a change after the run records none", "observe", func(t *testing.T) {
			write(t, "a", "a")
			pass(t, "true")
			write(t, "a", "changed")
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "changed after the run")
			expectTrailers(t, "none")
		}},
		{"committing part of the verified tree records none", "observe", func(t *testing.T) {
			write(t, "a", "a")
			write(t, "b", "b")
			pass(t, "true")
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "part of the tree")
			expectTrailers(t, "none")
		}},
		{"commit -a is matched against the tree it commits", "observe", func(t *testing.T) {
			write(t, "a", "a")
			gitT(t, "add", "a")
			pass(t, "true")
			write(t, "base", "base\nmore")
			pass(t, "echo", "after-edit")
			gitT(t, "commit", "-q", "-a", "-m", "commit -a")
			expectTrailers(t, "echo after-edit")
		}},
		{"amend replaces the trailer", "observe", func(t *testing.T) {
			write(t, "a", "a")
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "first")
			pass(t, "true")
			gitT(t, "commit", "-q", "--amend", "--no-edit")
			expectTrailers(t, "true")
			gitT(t, "commit", "-q", "--amend", "-m", gitT(t, "log", "-1", "--format=%B"))
			expectTrailers(t, "true") // with the trailer in the message, still one
		}},
		{"the repo's own commit-msg hook still runs", "observe", func(t *testing.T) {
			hook := "#!/bin/sh\necho ran >\"$(git rev-parse --git-dir)/traditional\"\n"
			if err := os.WriteFile(".git/hooks/commit-msg", []byte(hook), 0o755); err != nil {
				t.Fatal(err)
			}
			write(t, "a", "a")
			gitT(t, "add", "a")
			gitT(t, "commit", "-q", "-m", "with a repo hook")
			if _, err := os.Stat(".git/traditional"); err != nil {
				t.Errorf("the repo's commit-msg hook did not run: %v", err)
			}
			expectTrailers(t, "none")
		}},
		{"an empty message still aborts the commit", "observe", func(t *testing.T) {
			write(t, "a", "a")
			gitT(t, "add", "a")
			commit := exec.Command("git", "commit", "-q")
			commit.Env = append(os.Environ(), "GIT_EDITOR=true")
			if err := commit.Run(); err == nil {
				t.Errorf("commit with an empty message went through: %q", gitT(t, "log", "-1", "--format=%B"))
			}
		}},
		{"enforce is refused until it exists", "enforce", func(t *testing.T) {
			write(t, "a", "a")
			gitT(t, "add", "a")
			out, err := exec.Command("git", "commit", "-q", "-m", "enforce").CombinedOutput()
			if err == nil {
				t.Error("commit under enforce went through, want it refused")
			}
			if !strings.Contains(string(out), "verify-gate: verify.gate=enforce is not implemented") {
				t.Errorf("output = %q, want the not implemented message", out)
			}
		}},
		{"an unknown mode says what to set", "strict", func(t *testing.T) {
			write(t, "a", "a")
			gitT(t, "add", "a")
			out, err := exec.Command("git", "commit", "-q", "-m", "strict").CombinedOutput()
			if err == nil || !strings.Contains(string(out), "unknown verify.gate value 'strict'") {
				t.Errorf("commit = %v, %q, want refused with the unknown value message", err, out)
			}
		}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			fresh(t, tc.mode)
			tc.steps(t)
		})
	}
}

// run hands back the command's exit code and leaves stdout to it.
func TestRunPassesTheCommand(t *testing.T) {
	fresh(t, "observe")
	var out, errs strings.Builder
	code := cli.Main(cli.Root(Command()), []string{"verify-gate", "run", "sh", "-c", "echo hi; exit 3"}, strings.NewReader(""), &out, &errs)
	if code != 3 || out.String() != "hi\n" || errs.Len() > 0 {
		t.Errorf("exit %d, stdout %q, stderr %q; want 3, the command's stdout and nothing else", code, out.String(), errs.String())
	}
}

// A command killed by a signal exits 128 + the signal, as a shell reports it,
// and is not recorded.
func TestRunReportsAKilledCommandAsAShellDoes(t *testing.T) {
	fresh(t, "observe")
	var out, errs strings.Builder
	code := cli.Main(cli.Root(Command()), []string{"verify-gate", "run", "--", "sh", "-c", "kill -TERM $$"}, strings.NewReader(""), &out, &errs)
	if code != 143 || errs.Len() > 0 {
		t.Errorf("exit %d, stderr %q; want 143 and nothing recorded", code, errs.String())
	}
}

func TestRunOutsideARepositoryRecordsNothing(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("GIT_CEILING_DIRECTORIES", filepath.Dir(dir))
	t.Chdir(dir)
	if err := gate(t, "run", "true"); err != nil {
		t.Errorf("run true outside a repository = %v, want nil", err)
	}
}

func TestUsage(t *testing.T) {
	for _, args := range [][]string{{"bogus"}, {"run"}, {"run", "--"}, {"commit-msg"}, {"commit-msg", "a", "b"}} {
		var stdout, stderr strings.Builder
		code := cli.Main(cli.Root(Command()), append([]string{"verify-gate"}, args...), strings.NewReader(""), &stdout, &stderr)
		if code != 2 || stdout.Len() > 0 || !strings.Contains(stderr.String(), "Usage:\n  rat verify-gate") {
			t.Errorf("verify-gate %q: exit %d, stdout %q, stderr %q; want 2 with the usage on stderr", args, code, stdout.String(), stderr.String())
		}
	}
}

// verify-gate alone lists its subcommands.
func TestHelp(t *testing.T) {
	var stdout, stderr strings.Builder
	if code := cli.Main(cli.Root(Command()), []string{"verify-gate"}, strings.NewReader(""), &stdout, &stderr); code != 0 || !strings.Contains(stdout.String(), "commit-msg") {
		t.Errorf("exit %d, stdout %q, stderr %q; want 0 and the help", code, stdout.String(), stderr.String())
	}
}
