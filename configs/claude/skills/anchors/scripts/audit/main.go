// audit lists the anchor comments CLAUDE.md defines — HACK(<ref>) and
// AIDEV-NOTE — across the files git tracks, and asks gh whether each HACK's
// referenced issue is still open. A closed issue means the workaround under
// the anchor is a candidate for removal.
//
//	go run main.go [-offline] [<dir>]
//
// Exit status is 1 when any referenced issue is closed, so the script can sit
// in a check step. Only the standard library is used so that `go run` works
// without a module.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type anchor struct {
	path string
	line int
	kind string
	ref  string
	text string
}

type ref struct {
	owner, repo string
	number      string
	pull        bool
}

var (
	hackRe   = regexp.MustCompile(`\bHACK\(([^)]*)\):?\s*(.*)`)
	aidevRe  = regexp.MustCompile(`\b(AIDEV-(?:NOTE|TODO|QUESTION|ANSWER)):\s*(.*)`)
	urlRe    = regexp.MustCompile(`^https?://github\.com/([^/]+)/([^/]+)/(issues|pull)/(\d+)`)
	shortRe  = regexp.MustCompile(`^([^/#\s]+)/([^/#\s]+)#(\d+)$`)
	localRe  = regexp.MustCompile(`^#(\d+)$`)
	originRe = regexp.MustCompile(`github\.com[:/]([^/]+)/([^/.]+)`)
)

func main() {
	offline := flag.Bool("offline", false, "list anchors without asking gh for issue state")
	flag.Parse()
	dir := "."
	if flag.NArg() > 0 {
		dir = flag.Arg(0)
	}

	files, err := gitFiles(dir)
	if err != nil {
		fmt.Fprintln(os.Stderr, "audit:", err)
		os.Exit(2)
	}
	var anchors []anchor
	for _, f := range files {
		found, err := scan(dir, f)
		if err != nil {
			fmt.Fprintln(os.Stderr, "audit:", err)
			continue
		}
		anchors = append(anchors, found...)
	}
	if len(anchors) == 0 {
		fmt.Println("no anchors")
		return
	}

	origin := originRepo(dir)
	states := map[string]string{}
	if !*offline {
		for _, a := range anchors {
			if a.kind != "HACK" {
				continue
			}
			if _, done := states[a.ref]; done {
				continue
			}
			r, ok := parseRef(a.ref, origin)
			if !ok {
				states[a.ref] = "unchecked"
				continue
			}
			states[a.ref] = issueState(r)
		}
	}

	closed := 0
	for _, a := range anchors {
		state := "-"
		if a.kind == "HACK" {
			state = states[a.ref]
			if state == "" {
				state = "unchecked"
			}
			if state == "closed" {
				closed++
			}
		}
		fmt.Printf("%s:%d\t%s\t%s\t%s\t%s\n", a.path, a.line, a.kind, state, a.ref, a.text)
	}
	fmt.Printf("\n%d anchors, %d HACK referencing a closed issue\n", len(anchors), closed)
	if closed > 0 {
		os.Exit(1)
	}
}

// gitFiles returns the paths git tracks or would track under dir, so the
// repository's .gitignore decides what is scanned.
func gitFiles(dir string) ([]string, error) {
	cmd := exec.Command("git", "-C", dir, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git ls-files in %s: %w", dir, err)
	}
	var files []string
	for f := range bytes.SplitSeq(out, []byte{0}) {
		if len(f) > 0 {
			files = append(files, string(f))
		}
	}
	sort.Strings(files)
	return files, nil
}

func scan(dir, rel string) ([]anchor, error) {
	data, err := os.ReadFile(filepath.Join(dir, rel))
	if err != nil {
		return nil, err
	}
	if bytes.IndexByte(data[:min(len(data), 8000)], 0) >= 0 {
		return nil, nil // binary
	}
	var found []anchor
	i := 0
	for line := range strings.SplitSeq(string(data), "\n") {
		i++
		if m := hackRe.FindStringSubmatch(line); m != nil {
			a := anchor{rel, i, "HACK", strings.TrimSpace(m[1]), strings.TrimSpace(m[2])}
			if !isTemplate(a.ref) {
				found = append(found, a)
			}
			continue
		}
		if m := aidevRe.FindStringSubmatch(line); m != nil {
			a := anchor{rel, i, m[1], "", strings.TrimSpace(m[2])}
			if !isTemplate(a.text) {
				found = append(found, a)
			}
		}
	}
	return found, nil
}

// isTemplate recognises the documented form itself — `HACK(<issue URL>)`,
// `AIDEV-NOTE: <the decision>` — as quoted in CLAUDE.md and the skills, so
// the rule's own examples are not reported as anchors.
func isTemplate(s string) bool {
	return strings.HasPrefix(s, "<")
}

// parseRef accepts a GitHub issue or pull URL, owner/repo#N, or #N in the
// origin repository. Anything else is left unchecked rather than guessed.
func parseRef(s string, origin *ref) (ref, bool) {
	if m := urlRe.FindStringSubmatch(s); m != nil {
		return ref{owner: m[1], repo: m[2], number: m[4], pull: m[3] == "pull"}, true
	}
	if m := shortRe.FindStringSubmatch(s); m != nil {
		return ref{owner: m[1], repo: m[2], number: m[3]}, true
	}
	if m := localRe.FindStringSubmatch(s); m != nil && origin != nil {
		return ref{owner: origin.owner, repo: origin.repo, number: m[1]}, true
	}
	return ref{}, false
}

func originRepo(dir string) *ref {
	out, err := exec.Command("git", "-C", dir, "remote", "get-url", "origin").Output()
	if err != nil {
		return nil
	}
	m := originRe.FindStringSubmatch(strings.TrimSpace(string(out)))
	if m == nil {
		return nil
	}
	return &ref{owner: m[1], repo: m[2]}
}

// issueState asks gh; a pull URL is looked up as a pull request, and the
// issue endpoint is retried as a pull request because GitHub numbers them
// together. Any failure is "unchecked", never "open".
func issueState(r ref) string {
	order := []string{"issue", "pr"}
	if r.pull {
		order = []string{"pr", "issue"}
	}
	for _, sub := range order {
		out, err := exec.Command("gh", sub, "view", r.number, "-R", r.owner+"/"+r.repo, "--json", "state").Output()
		if err != nil {
			continue
		}
		var v struct{ State string }
		if json.Unmarshal(out, &v) != nil || v.State == "" {
			continue
		}
		if v.State == "OPEN" {
			return "open"
		}
		return "closed" // CLOSED or MERGED
	}
	return "unchecked"
}
