package main

import (
	"encoding/json"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// verdictOf runs status --json and returns the entry for branch.
func verdictOf(t *testing.T, f *fixture, branch string) Worktree {
	t.Helper()
	var all []Worktree
	if err := json.Unmarshal([]byte(f.run(f.home, "status", "--json")), &all); err != nil {
		t.Fatal(err)
	}
	for _, w := range all {
		if w.Branch == branch {
			return w
		}
	}
	t.Fatalf("status has no entry for %s: %+v", branch, all)
	return Worktree{}
}

func commit(t *testing.T, dir, name string) {
	t.Helper()
	writeFile(t, filepath.Join(dir, name), name+"\n")
	sh(t, dir, "add", ".")
	sh(t, dir, "commit", "-q", "-m", "add "+name)
}

func TestAFreshWorktreeIsActive(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	f.run(repo, "new", "feat/a", "--purpose", "try passkeys")

	w := verdictOf(t, f, "feat/a")

	if w.Verdict != "active" {
		t.Fatalf("verdict = %q (%s), want active", w.Verdict, w.Reason)
	}
	if w.Purpose != "try passkeys" {
		t.Fatalf("purpose = %q", w.Purpose)
	}
}

func TestAnUntouchedWorktreeIsDoneAfterADay(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	f.run(repo, "new", "feat/a")
	f.later(25 * time.Hour)

	if w := verdictOf(t, f, "feat/a"); w.Verdict != "done" {
		t.Fatalf("verdict = %q (%s), want done", w.Verdict, w.Reason)
	}
}

func TestUncommittedWorkIsNeverDone(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	writeFile(t, filepath.Join(path, "draft"), "half an idea\n")

	w := verdictOf(t, f, "feat/a")
	if w.Verdict != "active" || w.Dirty != 1 {
		t.Fatalf("verdict = %q dirty = %d, want active with 1", w.Verdict, w.Dirty)
	}

	f.later(30 * 24 * time.Hour)
	w = verdictOf(t, f, "feat/a")
	if w.Verdict != "stale" {
		t.Fatalf("verdict after a month = %q, want stale", w.Verdict)
	}
	if !strings.Contains(w.Reason, "1 uncommitted") {
		t.Fatalf("reason does not say what is left: %q", w.Reason)
	}
}

func TestUnmergedCommitsAreActiveThenStale(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	commit(t, path, "one")
	commit(t, path, "two")

	w := verdictOf(t, f, "feat/a")
	if w.Verdict != "active" || w.Ahead != 2 {
		t.Fatalf("verdict = %q ahead = %d, want active with 2", w.Verdict, w.Ahead)
	}

	f.later(30 * 24 * time.Hour)
	w = verdictOf(t, f, "feat/a")
	if w.Verdict != "stale" || !strings.Contains(w.Reason, "2 commits not in main") {
		t.Fatalf("verdict = %q reason = %q", w.Verdict, w.Reason)
	}
	if w.LastSubject != "add two" {
		t.Fatalf("last subject = %q", w.LastSubject)
	}
}

func TestMergedWorkIsDoneAtOnce(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	commit(t, path, "one")
	sh(t, repo, "merge", "-q", "--ff-only", "feat/a")

	if w := verdictOf(t, f, "feat/a"); w.Verdict != "done" {
		t.Fatalf("verdict = %q (%s), want done", w.Verdict, w.Reason)
	}
}

func TestASquashMergedPullRequestIsDone(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	commit(t, path, "one")
	head := sh(t, path, "rev-parse", "HEAD")
	f.fakeGh(`[{"number": 7, "state": "MERGED", "headRefOid": "` + head + `"}]`)

	w := verdictOf(t, f, "feat/a")

	if w.Verdict != "done" || !strings.Contains(w.Reason, "#7") {
		t.Fatalf("verdict = %q reason = %q, want done naming #7", w.Verdict, w.Reason)
	}
}

func TestCommitsAfterTheMergedPullRequestAreNotDone(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	commit(t, path, "one")
	merged := sh(t, path, "rev-parse", "HEAD")
	commit(t, path, "after the merge")
	f.fakeGh(`[{"number": 7, "state": "MERGED", "headRefOid": "` + merged + `"}]`)

	if w := verdictOf(t, f, "feat/a"); w.Verdict == "done" {
		t.Fatalf("a branch with a commit the PR never had was called done (%s)", w.Reason)
	}
}

func TestAClosedPullRequestIsStale(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	commit(t, path, "one")
	f.fakeGh(`[{"number": 9, "state": "CLOSED", "headRefOid": "x"}]`)

	w := verdictOf(t, f, "feat/a")

	if w.Verdict != "stale" || !strings.Contains(w.Reason, "#9 closed") {
		t.Fatalf("verdict = %q reason = %q", w.Verdict, w.Reason)
	}
}

func TestStatusCoversEveryRepositoryFromAnywhere(t *testing.T) {
	f := newFixture(t)
	one := newRepo(t, f.home, "one")
	two := newRepo(t, f.home, "two")
	f.run(one, "new", "feat/a")
	f.run(two, "new", "feat/b")

	out := f.run(f.home, "status")

	for _, want := range []string{one, two, "feat/a", "feat/b"} {
		if !strings.Contains(out, want) {
			t.Fatalf("status from outside any repository misses %q:\n%s", want, out)
		}
	}
}

func TestStatusSeesWorktreesMadeWithoutEda(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	legacy := filepath.Join(f.home, "app@old")
	sh(t, repo, "worktree", "add", "-q", "-b", "old", legacy)
	f.run(repo, "status") // running inside a repository is enough to learn it

	out := f.run(f.home, "status")

	if !strings.Contains(out, legacy) {
		t.Fatalf("a worktree outside the root is not listed:\n%s", out)
	}
}

func TestStatusWithNothingSaysSo(t *testing.T) {
	f := newFixture(t)

	if out := f.run(f.home, "status"); !strings.Contains(out, "no worktrees") {
		t.Fatalf("out = %q", out)
	}
}
