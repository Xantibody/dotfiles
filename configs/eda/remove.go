package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// remove deletes a worktree and its branch. Without force git itself refuses
// a worktree with modified or untracked files, a second check after ours.
func remove(e *env, w Worktree, force bool) error {
	args := []string{"worktree", "remove"}
	if force {
		args = append(args, "--force")
	}
	if _, err := git(w.Repo, append(args, w.Path)...); err != nil {
		return err
	}
	if w.Branch != "" {
		if _, err := git(w.Repo, "branch", "-D", w.Branch); err != nil {
			return err
		}
	}
	e.tidy(filepath.Dir(w.Path))
	return nil
}

// tidy removes the directories a removal emptied, up to but not including
// the root. Outside the root it touches nothing.
func (e *env) tidy(dir string) {
	root, err := filepath.EvalSymlinks(e.root)
	if err != nil {
		return
	}
	for dir != root && strings.HasPrefix(dir, root+string(filepath.Separator)) {
		if os.Remove(dir) != nil { // not empty
			return
		}
		dir = filepath.Dir(dir)
	}
}

func cmdSweep(args []string, e *env) error {
	fs := newFlags("sweep", e)
	dry := fs.Bool("dry-run", false, "say what would be removed and remove nothing")
	opts := judgeFlags(fs)
	if _, err := parseArgs(fs, args); err != nil {
		return err
	}
	if !*dry {
		for _, main := range e.repos() {
			_, _ = git(main, "worktree", "prune") // records of directories deleted by hand
		}
	}
	all, err := collect(e, *opts)
	if err != nil {
		return err
	}
	var kept []Worktree
	removed, failed := 0, 0
	for _, w := range all {
		if w.Verdict != "done" {
			kept = append(kept, w)
			continue
		}
		verb := "removed"
		if *dry {
			verb = "would remove"
		} else if err := remove(e, w, false); err != nil {
			fmt.Fprintf(e.stderr, "eda: %s: %v\n", w.Path, err)
			failed++
			kept = append(kept, w)
			continue
		}
		removed++
		fmt.Fprintf(e.stdout, "%s  %s  (%s)\n          %s\n", verb, name(w), w.Reason, w.Path)
	}
	if removed == 0 {
		fmt.Fprintln(e.stdout, "nothing to remove")
	}
	if len(kept) > 0 {
		fmt.Fprintln(e.stdout, "\nkept:")
		printText(e.stdout, kept)
	}
	if failed > 0 {
		return fmt.Errorf("%d finished worktrees could not be removed", failed)
	}
	return nil
}

func name(w Worktree) string {
	if w.Branch != "" {
		return w.Branch
	}
	return "(detached)"
}

func cmdRm(args []string, e *env) error {
	fs := newFlags("rm", e)
	force := fs.Bool("force", false, "remove even if uncommitted or unmerged work is lost")
	opts := judgeFlags(fs)
	pos, err := parseArgs(fs, args)
	if err != nil {
		return err
	}
	if len(pos) != 1 {
		return fmt.Errorf("rm takes exactly one branch name or worktree path")
	}
	w, err := find(e, *opts, pos[0])
	if err != nil {
		return err
	}
	if !w.disposable && !*force {
		return fmt.Errorf("%s still has %s; finish it, or pass --force to throw that away", name(*w), w.Reason)
	}
	if err := remove(e, *w, *force); err != nil {
		return err
	}
	fmt.Fprintf(e.stdout, "removed  %s\n          %s\n", name(*w), w.Path)
	return nil
}

// find resolves a worktree path, or a branch name. A branch name means the
// repository eda is run in; outside one it must be unique across all of them.
func find(e *env, o judgeOpts, target string) (*Worktree, error) {
	all, err := collect(e, o)
	if err != nil {
		return nil, err
	}
	path := target
	if resolved, err := filepath.EvalSymlinks(target); err == nil {
		path, _ = filepath.Abs(resolved)
	}
	here, _ := mainWorktree(e.cwd)
	var byBranch []*Worktree
	for i := range all {
		w := &all[i]
		if w.Path == path {
			return w, nil
		}
		if w.Branch == target {
			if w.Repo == here {
				return w, nil
			}
			byBranch = append(byBranch, w)
		}
	}
	switch len(byBranch) {
	case 1:
		return byBranch[0], nil
	case 0:
		return nil, fmt.Errorf("no worktree for %q; `eda status` lists them", target)
	default:
		return nil, fmt.Errorf("%q names a worktree in %d repositories; pass its path", target, len(byBranch))
	}
}

// hookInput is the JSON Claude Code writes to a WorktreeCreate or
// WorktreeRemove hook's stdin.
type hookInput struct {
	SessionID    string `json:"session_id"`
	Transcript   string `json:"transcript_path"`
	Cwd          string `json:"cwd"`
	Name         string `json:"name"`
	WorktreePath string `json:"worktree_path"`
}

func readHook(e *env) (hookInput, error) {
	var in hookInput
	if err := json.NewDecoder(e.stdin).Decode(&in); err != nil {
		return in, fmt.Errorf("hook input is not JSON: %v", err)
	}
	return in, nil
}

// cmdHookCreate serves Claude Code's WorktreeCreate hook, which replaces its
// own `git worktree add`. Claude Code reads the last line of stdout as the
// path, so nothing else is printed there.
func cmdHookCreate(e *env) error {
	in, err := readHook(e)
	if err != nil {
		return err
	}
	if in.Name == "" {
		return fmt.Errorf("hook input has no name")
	}
	dir := in.Cwd
	if dir == "" {
		dir = e.cwd
	}
	path, err := create(e, dir, in.Name, "HEAD", meta{Session: in.SessionID, Transcript: in.Transcript})
	if err != nil {
		return err
	}
	fmt.Fprintln(e.stdout, path)
	return nil
}

// cmdHookRemove serves WorktreeRemove. Claude Code calls it without asking
// on some routes, so it is the last check: it removes only what loses
// nothing, and a non-zero exit with the directory still there tells Claude
// Code the worktree was kept.
func cmdHookRemove(e *env) error {
	in, err := readHook(e)
	if err != nil {
		return err
	}
	if in.WorktreePath == "" {
		return fmt.Errorf("hook input has no worktree_path")
	}
	if _, err := os.Stat(in.WorktreePath); err != nil {
		return nil // already gone
	}
	w, err := find(e, judgeOpts{staleDays: 14}, in.WorktreePath)
	if err != nil {
		return err
	}
	if !w.disposable {
		return fmt.Errorf("kept %s: %s; `eda rm --force %s` throws it away", w.Path, w.Reason, w.Path)
	}
	return remove(e, *w, false)
}
