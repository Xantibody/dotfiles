package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestNewPutsTheWorktreeUnderTheRootNotNextToTheRepository(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "src/github.com/me/app")

	path := f.run(repo, "new", "feat/login", "--purpose", "try passkeys")

	want := filepath.Join(f.env.root, "src/github.com/me/app", "feat/login")
	if path != want {
		t.Fatalf("path = %q, want %q", path, want)
	}
	if got := sh(t, path, "branch", "--show-current"); got != "feat/login" {
		t.Fatalf("branch = %q, want feat/login", got)
	}
	siblings, err := os.ReadDir(filepath.Dir(repo))
	if err != nil {
		t.Fatal(err)
	}
	if len(siblings) != 1 {
		t.Fatalf("the repository's parent gained entries: %v", siblings)
	}
}

func TestNewStartsFromTheCurrentCommitByDefault(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	writeFile(t, filepath.Join(repo, "local"), "not pushed anywhere\n")
	sh(t, repo, "add", ".")
	sh(t, repo, "commit", "-q", "-m", "local only")

	path := f.run(repo, "new", "fix/a")

	if !exists(filepath.Join(path, "local")) {
		t.Fatal("the worktree does not contain the commit the session was on")
	}
}

func TestNewRefusesABranchThatAlreadyExists(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	f.run(repo, "new", "feat/a")

	_, code := f.try(repo, "new", "feat/a")

	if code == 0 {
		t.Fatal("a second worktree for the same branch was accepted")
	}
	if !strings.Contains(f.err.String(), "feat/a") {
		t.Fatalf("the error does not name the branch: %q", f.err.String())
	}
}

func TestNewOutsideARepositoryFails(t *testing.T) {
	f := newFixture(t)

	_, code := f.try(f.home, "new", "feat/a")

	if code == 0 {
		t.Fatal("new succeeded outside a repository")
	}
}
