package main

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// sh runs git in dir with an identity, so the tests do not depend on the
// machine's global config.
func sh(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	cmd.Env = append(os.Environ(),
		"GIT_AUTHOR_NAME=t", "GIT_AUTHOR_EMAIL=t@example.com",
		"GIT_COMMITTER_NAME=t", "GIT_COMMITTER_EMAIL=t@example.com",
		"GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_SYSTEM=/dev/null",
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
	}
	return strings.TrimSpace(string(out))
}

func writeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

// realTemp is t.TempDir with symlinks resolved; git prints resolved paths,
// and on macOS the temp dir sits behind /var -> /private/var.
func realTemp(t *testing.T) string {
	t.Helper()
	dir, err := filepath.EvalSymlinks(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	return dir
}

// newRepo makes a repository with one commit on main under home.
func newRepo(t *testing.T, home, rel string) string {
	t.Helper()
	dir := filepath.Join(home, rel)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	sh(t, dir, "init", "-q", "-b", "main")
	writeFile(t, filepath.Join(dir, "README"), "hello\n")
	sh(t, dir, "add", ".")
	sh(t, dir, "commit", "-q", "-m", "init")
	return dir
}

type fixture struct {
	t    *testing.T
	home string
	env  *env
	out  *bytes.Buffer
	err  *bytes.Buffer
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	home := realTemp(t)
	out, errb := &bytes.Buffer{}, &bytes.Buffer{}
	return &fixture{t: t, home: home, out: out, err: errb, env: &env{
		home:   home,
		cwd:    home,
		root:   filepath.Join(home, ".local", "share", "eda"),
		state:  filepath.Join(home, ".local", "state", "eda"),
		gh:     "",
		now:    time.Now,
		stdin:  strings.NewReader(""),
		stdout: out,
		stderr: errb,
	}}
}

// run executes one command from dir and returns stdout, failing the test on
// a non-zero exit.
func (f *fixture) run(dir string, args ...string) string {
	f.t.Helper()
	out, code := f.try(dir, args...)
	if code != 0 {
		f.t.Fatalf("eda %s: exit %d\n%s", strings.Join(args, " "), code, f.err.String())
	}
	return out
}

func (f *fixture) try(dir string, args ...string) (string, int) {
	f.t.Helper()
	f.out.Reset()
	f.err.Reset()
	f.env.cwd = dir
	code := run(args, f.env)
	return strings.TrimSpace(f.out.String()), code
}

// later moves the clock forward, leaving real file and commit times behind.
func (f *fixture) later(d time.Duration) {
	f.env.now = func() time.Time { return time.Now().Add(d) }
}

// fakeGh installs a gh that answers every call with the given JSON.
func (f *fixture) fakeGh(json string) {
	f.t.Helper()
	path := filepath.Join(f.home, "fake-gh")
	writeFile(f.t, path, "#!/bin/sh\ncat <<'EOF'\n"+json+"\nEOF\n")
	if err := os.Chmod(path, 0o755); err != nil {
		f.t.Fatal(err)
	}
	f.env.gh = path
}

func exists(path string) bool {
	_, err := os.Lstat(path)
	return err == nil
}
