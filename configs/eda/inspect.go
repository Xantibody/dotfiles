package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// grace is how long a worktree with nothing in it is left alone: it may be
// one an agent made a moment ago and has not written to yet.
const grace = 24 * time.Hour

type PR struct {
	Number int    `json:"number"`
	State  string `json:"state"`
	Head   string `json:"headRefOid"`
}

// Worktree is one worktree and the verdict on it.
type Worktree struct {
	Repo    string `json:"repo"`
	Path    string `json:"path"`
	Branch  string `json:"branch"`
	Head    string `json:"head"`
	Verdict string `json:"verdict"` // done, active or stale
	Reason  string `json:"reason"`

	Purpose    string `json:"purpose,omitempty"`
	Session    string `json:"session,omitempty"`
	Transcript string `json:"transcript,omitempty"`

	Dirty        int       `json:"dirty"`    // uncommitted and untracked paths
	Ahead        int       `json:"ahead"`    // commits the default branch does not have
	Unpushed     int       `json:"unpushed"` // of those, commits on no remote
	PR           *PR       `json:"pr,omitempty"`
	Created      time.Time `json:"created"`
	LastActivity time.Time `json:"last_activity"`
	LastSubject  string    `json:"last_subject"`

	// disposable means removing the worktree and its branch loses nothing.
	// done adds the grace period on top; rm and the remove hook ask only this.
	disposable bool
}

type judgeOpts struct {
	noPR      bool
	staleDays int
}

func judgeFlags(fs *flag.FlagSet) *judgeOpts {
	o := &judgeOpts{}
	fs.BoolVar(&o.noPR, "no-pr", false, "skip the pull-request lookup (no network)")
	fs.IntVar(&o.staleDays, "stale-days", 14, "days without activity before unfinished work is stale")
	return o
}

// collect inspects every worktree of every known repository except the main
// checkouts themselves.
func collect(e *env, o judgeOpts) ([]Worktree, error) {
	var all []Worktree
	for _, main := range e.repos() {
		entries, err := listWorktrees(main)
		if err != nil {
			continue
		}
		line := mainline(main, entries[0])
		for _, it := range entries[1:] {
			if it.bare {
				continue
			}
			if _, err := os.Stat(it.path); err != nil {
				continue // the directory is gone; sweep prunes the record
			}
			all = append(all, inspect(e, o, main, line, it))
		}
	}
	return all, nil
}

// mainline lists the refs that count as "merged": the remote's default
// branch and its local counterpart. A repository without a remote falls back
// to main or master, then to whatever the main checkout is on.
func mainline(main string, first entry) []string {
	var refs []string
	if remote, err := git(main, "symbolic-ref", "-q", "--short", "refs/remotes/origin/HEAD"); err == nil && remote != "" {
		refs = append(refs, remote)
		if local := strings.TrimPrefix(remote, "origin/"); refExists(main, "refs/heads/"+local) {
			refs = append(refs, local)
		}
		return refs
	}
	for _, name := range []string{"main", "master"} {
		if refExists(main, "refs/heads/"+name) {
			return []string{name}
		}
	}
	if first.branch != "" {
		return []string{first.branch}
	}
	return []string{first.head}
}

func inspect(e *env, o judgeOpts, main string, line []string, it entry) Worktree {
	m := readMeta(it.path)
	w := Worktree{
		Repo: main, Path: it.path, Branch: it.branch, Head: it.head,
		Purpose: m.Purpose, Session: m.Session, Transcript: m.Transcript,
		Created: m.CreatedAt, LastActivity: m.CreatedAt,
	}
	touch := func(t time.Time) {
		if t.After(w.LastActivity) {
			w.LastActivity = t
		}
	}

	if out, err := git(it.path, "status", "--porcelain"); err == nil && out != "" {
		for _, l := range strings.Split(out, "\n") {
			if len(l) < 4 {
				continue
			}
			w.Dirty++
			name := l[3:]
			if _, renamed, ok := strings.Cut(name, " -> "); ok {
				name = renamed
			}
			if info, err := os.Lstat(filepath.Join(it.path, name)); err == nil {
				touch(info.ModTime())
			}
		}
	}

	not := append([]string{"--not"}, line...)
	w.Ahead = count(it.path, append([]string{"rev-list", "--count", "HEAD"}, not...)...)
	if w.Ahead > 0 {
		w.Unpushed = count(it.path, append([]string{"rev-list", "--count", "HEAD", "--not", "--remotes"}, line...)...)
	}
	if out, err := git(it.path, "log", "-1", "--format=%ct%x09%s"); err == nil {
		stamp, subject, _ := strings.Cut(out, "\t")
		if sec, err := strconv.ParseInt(stamp, 10, 64); err == nil {
			w.LastSubject = subject
			if w.Ahead > 0 {
				touch(time.Unix(sec, 0))
			}
		}
	}
	if w.Ahead > 0 && w.Branch != "" && e.gh != "" && !o.noPR {
		w.PR = lookupPR(e, main, w.Branch)
	}

	judge(&w, m, line[len(line)-1], e.now(), time.Duration(o.staleDays)*24*time.Hour)
	return w
}

func count(dir string, args ...string) int {
	out, err := git(dir, args...)
	if err != nil {
		return 0
	}
	n, _ := strconv.Atoi(out)
	return n
}

// lookupPR asks GitHub for the newest pull request of the branch. A squash
// merge leaves the branch's commits outside the default branch, so only the
// pull request can say that the work landed. Any failure means "unknown".
func lookupPR(e *env, main, branch string) *PR {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, e.gh, "pr", "list", "--head", branch, "--state", "all",
		"--limit", "1", "--json", "number,state,headRefOid")
	cmd.Dir = main
	out, err := cmd.Output()
	if err != nil {
		return nil
	}
	var prs []PR
	if json.Unmarshal(out, &prs) != nil || len(prs) == 0 {
		return nil
	}
	return &prs[0]
}

func judge(w *Worktree, m meta, defaultBranch string, now time.Time, staleAfter time.Duration) {
	mergedPR := w.PR != nil && w.PR.State == "MERGED" && w.PR.Head == w.Head
	w.disposable = w.Dirty == 0 && (w.Ahead == 0 || mergedPR)

	if w.disposable {
		switch {
		case mergedPR:
			w.Verdict, w.Reason = "done", fmt.Sprintf("PR #%d merged", w.PR.Number)
		case m.Base != "" && m.Base != w.Head:
			w.Verdict, w.Reason = "done", "merged into "+defaultBranch
		case now.Sub(w.Created) >= grace:
			w.Verdict, w.Reason = "done", "nothing that is not in "+defaultBranch+", made "+ago(now.Sub(w.Created))+" ago"
		default:
			w.Verdict, w.Reason = "active", "made "+ago(now.Sub(w.Created))+" ago, nothing in it yet"
		}
		return
	}

	var left []string
	if w.Dirty > 0 {
		left = append(left, plural(w.Dirty, "uncommitted file"))
	}
	if w.Ahead > 0 {
		s := plural(w.Ahead, "commit") + " not in " + defaultBranch
		if w.Unpushed > 0 {
			s += fmt.Sprintf(" (%d on no remote)", w.Unpushed)
		}
		left = append(left, s)
	}
	idle := now.Sub(w.LastActivity)
	w.Verdict = "active"
	switch {
	case w.PR != nil && w.PR.State == "CLOSED":
		w.Verdict = "stale"
		left = append([]string{fmt.Sprintf("PR #%d closed without merging", w.PR.Number)}, left...)
	case w.PR != nil && w.PR.State == "MERGED":
		left = append([]string{fmt.Sprintf("PR #%d merged, but the worktree has moved on since", w.PR.Number)}, left...)
	case w.PR != nil && w.PR.State == "OPEN":
		left = append([]string{fmt.Sprintf("PR #%d open", w.PR.Number)}, left...)
	}
	if idle >= staleAfter {
		w.Verdict = "stale"
	}
	w.Reason = strings.Join(left, ", ") + ", untouched for " + ago(idle)
}

func plural(n int, noun string) string {
	if n == 1 {
		return "1 " + noun
	}
	return fmt.Sprintf("%d %ss", n, noun)
}

func ago(d time.Duration) string {
	switch {
	case d >= 48*time.Hour:
		return plural(int(d/(24*time.Hour)), "day")
	case d >= time.Hour:
		return plural(int(d/time.Hour), "hour")
	default:
		return plural(int(d/time.Minute), "minute")
	}
}

func printJSON(out io.Writer, all []Worktree) error {
	if all == nil {
		all = []Worktree{}
	}
	enc := json.NewEncoder(out)
	enc.SetIndent("", "  ")
	return enc.Encode(all)
}

func printText(out io.Writer, all []Worktree) {
	if len(all) == 0 {
		fmt.Fprintln(out, "no worktrees")
		return
	}
	repo := ""
	for _, w := range all {
		if w.Repo != repo {
			repo = w.Repo
			fmt.Fprintln(out, repo)
		}
		branch := w.Branch
		if branch == "" {
			branch = "(detached " + w.Head[:min(7, len(w.Head))] + ")"
		}
		fmt.Fprintf(out, "  %-6s  %s\n", w.Verdict, branch)
		fmt.Fprintf(out, "          reason:  %s\n", w.Reason)
		if w.Purpose != "" {
			fmt.Fprintf(out, "          purpose: %s\n", w.Purpose)
		}
		if w.LastSubject != "" && w.Ahead > 0 {
			fmt.Fprintf(out, "          last:    %s\n", w.LastSubject)
		}
		if w.Session != "" {
			fmt.Fprintf(out, "          session: %s\n", w.Session)
		}
		fmt.Fprintf(out, "          path:    %s\n", w.Path)
	}
}
