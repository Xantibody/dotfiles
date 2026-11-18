package main

import (
	"path/filepath"
	"strings"
	"testing"
)

func merged(t *testing.T, f *fixture, repo, branch string) string {
	t.Helper()
	path := f.run(repo, "new", branch)
	commit(t, path, strings.ReplaceAll(branch, "/", "-"))
	sh(t, repo, "merge", "-q", "--ff-only", branch)
	return path
}

func TestSweepRemovesFinishedWorktreesInEveryRepository(t *testing.T) {
	f := newFixture(t)
	one := newRepo(t, f.home, "one")
	two := newRepo(t, f.home, "two")
	doneOne := merged(t, f, one, "feat/a")
	doneTwo := merged(t, f, two, "fix/b")
	busy := f.run(two, "new", "feat/c")
	writeFile(t, filepath.Join(busy, "draft"), "half\n")

	out := f.run(f.home, "sweep")

	for _, gone := range []string{doneOne, doneTwo} {
		if exists(gone) {
			t.Fatalf("%s is finished and still there", gone)
		}
	}
	if !exists(busy) {
		t.Fatal("a worktree with uncommitted work was removed")
	}
	if strings.Contains(sh(t, one, "branch", "--list", "feat/a"), "feat/a") {
		t.Fatal("the branch of a removed worktree is still there")
	}
	if !strings.Contains(out, "removed") || !strings.Contains(out, "feat/c") {
		t.Fatalf("the report does not say what went and what stayed:\n%s", out)
	}
}

func TestSweepLeavesNoEmptyDirectoriesBehind(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "src/me/app")
	merged(t, f, repo, "feat/a")

	f.run(f.home, "sweep")

	if exists(filepath.Join(f.env.root, "src")) {
		t.Fatal("the emptied directories under the root were left behind")
	}
	if !exists(f.env.root) {
		t.Fatal("the root itself was removed")
	}
}

func TestSweepDryRunRemovesNothing(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := merged(t, f, repo, "feat/a")

	out := f.run(f.home, "sweep", "--dry-run")

	if !exists(path) {
		t.Fatal("dry run removed the worktree")
	}
	if !strings.Contains(out, "would remove") {
		t.Fatalf("out = %q", out)
	}
}

func TestSweepKeepsAWorktreeMadeAMomentAgo(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")

	f.run(f.home, "sweep")

	if !exists(path) {
		t.Fatal("a worktree an agent may be about to use was removed")
	}
}

func TestSweepAlsoRemovesFinishedWorktreesMadeWithoutEda(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	legacy := filepath.Join(f.home, "app@old")
	sh(t, repo, "worktree", "add", "-q", "-b", "old", legacy)
	commit(t, legacy, "old-work")
	sh(t, repo, "merge", "-q", "--ff-only", "old")
	f.run(repo, "status")

	f.run(f.home, "sweep")

	if exists(legacy) {
		t.Fatal("a merged worktree outside the root was kept")
	}
}

func TestRmRefusesUnfinishedWorkAndSaysWhatIsLeft(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	commit(t, path, "one")

	_, code := f.try(repo, "rm", "feat/a")

	if code == 0 || !exists(path) {
		t.Fatal("rm threw away an unmerged commit without --force")
	}
	if !strings.Contains(f.err.String(), "1 commit not in main") {
		t.Fatalf("the refusal does not say what is left: %q", f.err.String())
	}
}

func TestRmForceRemovesUnfinishedWork(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")
	writeFile(t, filepath.Join(path, "draft"), "half\n")

	f.run(f.home, "rm", path, "--force")

	if exists(path) {
		t.Fatal("--force did not remove the worktree")
	}
	if strings.Contains(sh(t, repo, "branch", "--list", "feat/a"), "feat/a") {
		t.Fatal("the branch is still there")
	}
}

func TestRmRemovesAnEmptyWorktreeWithoutWaitingADay(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")
	path := f.run(repo, "new", "feat/a")

	f.run(repo, "rm", "feat/a")

	if exists(path) {
		t.Fatal("an empty worktree asked for by name was kept")
	}
}

func TestRmOfAnUnknownTargetFails(t *testing.T) {
	f := newFixture(t)
	repo := newRepo(t, f.home, "app")

	if _, code := f.try(repo, "rm", "nope"); code == 0 {
		t.Fatal("rm of a branch with no worktree succeeded")
	}
}
