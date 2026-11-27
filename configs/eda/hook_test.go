package main

import (
	"path/filepath"
	"strings"
	"testing"
)

func (f *fixture) hook(event, input string) (string, int) {
	f.t.Helper()
	f.env.stdin = strings.NewReader(input)
	return f.try(f.home, event)
}

func TestHookCreatePrintsAPathUnderTheRootAsItsLastLine(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")

	out, code := f.hook("hook-create", `{"session_id": "s1", "transcript_path": "/t/s1.jsonl", "cwd": "`+repo+`", "name": "bold-oak-a3f2"}`)

	if code != 0 {
		t.Fatalf("exit %d: %s", code, f.err.String())
	}
	lines := strings.Split(out, "\n")
	path := lines[len(lines)-1]
	if want := filepath.Join(f.env.root, "app", "bold-oak-a3f2"); path != want {
		t.Fatalf("path = %q, want %q", path, want)
	}
	if w := verdictOf(t, f, "bold-oak-a3f2"); w.Session != "s1" || w.Transcript != "/t/s1.jsonl" {
		t.Fatalf("the session that made it was not recorded: %+v", w)
	}
}

func TestHookCreateWithoutANameFails(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")

	if _, code := f.hook("hook-create", `{"cwd": "`+repo+`"}`); code == 0 {
		t.Fatal("a worktree without a name was created")
	}
}

func TestHookRemoveDeletesAWorktreeWithNothingToLose(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "agent-1")

	_, code := f.hook("hook-remove", `{"worktree_path": "`+path+`"}`)

	if code != 0 || exists(path) {
		t.Fatalf("exit %d, still there: %v\n%s", code, exists(path), f.err.String())
	}
	if strings.Contains(sh(t, repo, "branch", "--list", "agent-1"), "agent-1") {
		t.Fatal("the branch outlived its worktree")
	}
}

func TestHookRemoveKeepsUnfinishedWork(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "agent-1")
	writeFile(t, filepath.Join(path, "draft"), "half\n")

	_, code := f.hook("hook-remove", `{"worktree_path": "`+path+`"}`)

	if code == 0 || !exists(path) {
		t.Fatal("the hook removed uncommitted work")
	}
}

func TestHookRemoveOfAPathAlreadyGoneSucceeds(t *testing.T) {
	f := newFixture(t)

	if _, code := f.hook("hook-remove", `{"worktree_path": "`+filepath.Join(f.home, "gone")+`"}`); code != 0 {
		t.Fatalf("exit %d: %s", code, f.err.String())
	}
}
