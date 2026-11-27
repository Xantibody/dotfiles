package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

func git(dir string, args ...string) (string, error) {
	cmd := exec.Command("git", append([]string{"-C", dir}, args...)...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	if err != nil {
		msg := strings.TrimSpace(stderr.String())
		if msg == "" {
			msg = err.Error()
		}
		return "", fmt.Errorf("git %s: %s", strings.Join(args, " "), msg)
	}
	return strings.TrimRight(string(out), "\n"), nil
}

func refExists(dir, ref string) bool {
	_, err := git(dir, "rev-parse", "--verify", "-q", ref)
	return err == nil
}

// entry is one block of `git worktree list --porcelain`.
type entry struct {
	path   string
	head   string
	branch string // empty when detached
	bare   bool
}

func listWorktrees(dir string) ([]entry, error) {
	out, err := git(dir, "worktree", "list", "--porcelain")
	if err != nil {
		return nil, fmt.Errorf("%s is not inside a git repository", dir)
	}
	var all []entry
	for _, block := range strings.Split(out, "\n\n") {
		var it entry
		for _, line := range strings.Split(block, "\n") {
			key, value, _ := strings.Cut(line, " ")
			switch key {
			case "worktree":
				it.path = value
			case "HEAD":
				it.head = value
			case "branch":
				it.branch = strings.TrimPrefix(value, "refs/heads/")
			case "bare":
				it.bare = true
			}
		}
		if it.path != "" {
			all = append(all, it)
		}
	}
	return all, nil
}

// mainWorktree returns the checkout the repository's other worktrees hang off.
func mainWorktree(dir string) (string, error) {
	all, err := listWorktrees(dir)
	if err != nil {
		return "", err
	}
	if len(all) == 0 {
		return "", fmt.Errorf("%s has no worktrees", dir)
	}
	return all[0].path, nil
}

// meta is what eda remembers about a worktree. It lives in the worktree's
// administrative directory inside .git, so it never shows up as an untracked
// file and disappears with the worktree.
type meta struct {
	Purpose    string    `json:"purpose,omitempty"`
	Session    string    `json:"session,omitempty"`
	Transcript string    `json:"transcript,omitempty"`
	Base       string    `json:"base,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

func metaPath(worktree string) (string, error) {
	dir, err := git(worktree, "rev-parse", "--absolute-git-dir")
	if err != nil {
		return "", err
	}
	return filepath.Join(dir, "eda.json"), nil
}

func writeMeta(worktree string, m meta) error {
	path, err := metaPath(worktree)
	if err != nil {
		return err
	}
	data, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, append(data, '\n'), 0o644)
}

// readMeta returns the recorded meta, or for a worktree eda did not create,
// only the time its administrative directory was made.
func readMeta(worktree string) meta {
	var m meta
	path, err := metaPath(worktree)
	if err != nil {
		return m
	}
	if data, err := os.ReadFile(path); err == nil && json.Unmarshal(data, &m) == nil {
		return m
	}
	if info, err := os.Stat(filepath.Dir(path)); err == nil {
		m.CreatedAt = info.ModTime()
	}
	return m
}

// pathFor maps a repository and a branch to a directory under the root. The
// repository's own path is the key: it is unique on this machine and needs no
// remote to derive.
func (e *env) pathFor(main, branch string) (string, error) {
	if err := os.MkdirAll(e.root, 0o755); err != nil {
		return "", err
	}
	root, err := filepath.EvalSymlinks(e.root)
	if err != nil {
		return "", err
	}
	home := e.home
	if resolved, err := filepath.EvalSymlinks(home); err == nil {
		home = resolved
	}
	key := strings.TrimPrefix(main, string(filepath.Separator))
	if rel, err := filepath.Rel(home, main); err == nil && rel != "." && !strings.HasPrefix(rel, "..") {
		key = rel
	}
	return filepath.Join(root, key, filepath.FromSlash(branch)), nil
}

func create(e *env, dir, branch, base string, m meta) (string, error) {
	main, err := mainWorktree(dir)
	if err != nil {
		return "", err
	}
	if _, err := git(main, "check-ref-format", "--branch", branch); err != nil {
		return "", fmt.Errorf("%q is not a valid branch name", branch)
	}
	if refExists(main, "refs/heads/"+branch) {
		return "", fmt.Errorf("branch %s already exists; pick another name or look at `eda status`", branch)
	}
	path, err := e.pathFor(main, branch)
	if err != nil {
		return "", err
	}
	if _, err := os.Lstat(path); err == nil {
		return "", fmt.Errorf("%s already exists", path)
	}
	sha, err := git(dir, "rev-parse", "--verify", "-q", base+"^{commit}")
	if err != nil {
		return "", fmt.Errorf("base %q is not a commit", base)
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return "", err
	}
	if _, err := git(main, "worktree", "add", "-q", "-b", branch, path, sha); err != nil {
		return "", err
	}
	m.Base = sha
	m.CreatedAt = e.now()
	if err := writeMeta(path, m); err != nil {
		return "", err
	}
	if err := e.remember(main); err != nil {
		return "", err
	}
	return path, nil
}

func (e *env) registry() string { return filepath.Join(e.state, "repos") }

// remember adds a repository to the list status and sweep walk, so a
// worktree made outside the root is still found once its repository is known.
func (e *env) remember(main string) error {
	known := e.registered()
	for _, k := range known {
		if k == main {
			return nil
		}
	}
	if err := os.MkdirAll(e.state, 0o755); err != nil {
		return err
	}
	return os.WriteFile(e.registry(), []byte(strings.Join(append(known, main), "\n")+"\n"), 0o644)
}

func (e *env) registered() []string {
	data, err := os.ReadFile(e.registry())
	if err != nil {
		return nil
	}
	var out []string
	for _, line := range strings.Split(string(data), "\n") {
		if line != "" {
			out = append(out, line)
		}
	}
	return out
}

// repos returns every repository eda knows: the one it is run in, the ones
// it has seen before, and the owners of whatever sits under the root. The
// last source rebuilds the list when the registry is lost.
func (e *env) repos() []string {
	seen := map[string]bool{}
	add := func(dir string) {
		if main, err := mainWorktree(dir); err == nil {
			seen[main] = true
		}
	}
	if main, err := mainWorktree(e.cwd); err == nil {
		seen[main] = true
		_ = e.remember(main)
	}
	for _, dir := range e.registered() {
		add(dir)
	}
	_ = filepath.WalkDir(e.root, func(path string, d fs.DirEntry, err error) error {
		if err != nil || !d.IsDir() {
			return nil
		}
		if _, err := os.Lstat(filepath.Join(path, ".git")); err == nil {
			add(path)
			return filepath.SkipDir
		}
		return nil
	})
	out := make([]string, 0, len(seen))
	for dir := range seen {
		out = append(out, dir)
	}
	sort.Strings(out)
	return out
}
