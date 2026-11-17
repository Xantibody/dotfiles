// Package checklist applies a repository's REVIEW.md to the current change
// and prints only the rows the change hits.
//
// REVIEW.md is read from the base (git show <base>:REVIEW.md), not from the
// working tree, so a branch that deletes or loosens a row is still checked
// against the row it removed; a row added on the branch applies once it
// reaches the base. The change is the union of the commits since the merge
// base (<base>...HEAD), the staged and unstaged edits, and untracked files,
// so it covers a feature branch and unpushed commits made straight onto the
// default branch alike.
//
// The table is the first one whose header names Trigger, Check and Incident.
// A Trigger cell holds one or more backticked patterns, any of which fires
// the row:
//
//   - `/regex/` matches an added or removed line of the diff (RE2 syntax;
//     write a | inside a table cell as \|);
//   - anything else is a path glob matched against the whole repo-relative
//     path: * and ? stay within one path segment, ** crosses them.
//
// Check says what to look at, and Incident names the commit whose body tells
// what broke; both are required, since a row nobody can trace back is a row
// nobody can prune.
//
//	rat checklist [--base origin/main]
//
// Without --base the base is origin/HEAD. stdout carries the rows hit, as a
// Markdown table with a Matched column, and nothing when no row is hit;
// notes go to stderr. A repository with no REVIEW.md on the base exits 0
// with a note, since the checklist is opt-in per repository.
package checklist

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"unicode/utf8"
)

// file is the checklist's name at the repository root.
const file = "REVIEW.md"

// pattern is one backticked entry of a Trigger cell.
type pattern struct {
	raw  string
	path *regexp.Regexp // a compiled glob; nil for a diff pattern
	diff *regexp.Regexp // nil for a path pattern
}

// row is one line of the checklist table.
type row struct {
	line     int // 1-based line in REVIEW.md
	trigger  string
	check    string
	incident string
	patterns []pattern
}

// change is what the working tree differs from the base by.
type change struct {
	files []string            // repo-relative, sorted, unique
	lines map[string][]string // added or removed lines per file, without the +/-
}

// hit is a row together with the files that fired it.
type hit struct {
	row     row
	matched []string
}

// Run applies the checklist from the directory to run git in and the --base
// flag, and returns the exit code: 0 when the rows were applied, 1 on a
// broken table or a missing base.
func Run(dir, base string, stdout, stderr io.Writer) int {
	if err := apply(dir, base, stdout, stderr); err != nil {
		fmt.Fprintf(stderr, "checklist: %v\n", err)
		return 1
	}
	return 0
}

func apply(dir, base string, stdout, stderr io.Writer) error {
	top, err := git(dir, "rev-parse", "--show-toplevel")
	if err != nil {
		return fmt.Errorf("not in a git repository: %w", err)
	}
	top = strings.TrimSpace(top)
	if base == "" {
		head, err := git(top, "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
		if err != nil {
			return errors.New("origin/HEAD is not set; run `git remote set-head origin --auto` or pass --base <ref>")
		}
		base = strings.TrimSpace(head)
	}
	if _, err := git(top, "rev-parse", "--verify", "--quiet", base+"^{commit}"); err != nil {
		return fmt.Errorf("--base %q is not a commit here; fetch it first (git fetch origin)", base)
	}

	text, onBase := "", true
	if _, err := git(top, "cat-file", "-e", base+":"+file); err != nil {
		onBase = false
	} else if text, err = git(top, "show", base+":"+file); err != nil {
		return err
	}
	local, err := os.ReadFile(filepath.Join(top, file))
	if (err == nil && string(local) != text) || (errors.Is(err, fs.ErrNotExist) && onBase) {
		fmt.Fprintf(stderr, "checklist: %s on this branch differs from %s; its rows apply once they reach %s\n", file, base, base)
	}
	if !onBase {
		fmt.Fprintf(stderr, "checklist: no %s on %s; nothing to apply\n", file, base)
		return nil
	}

	rows, err := parse(text)
	if err != nil {
		return fmt.Errorf("%s on %s: %w", file, base, err)
	}
	ch, err := collect(top, base, needsLines(rows))
	if err != nil {
		return err
	}
	hits := match(rows, ch)
	if len(hits) > 0 {
		io.WriteString(stdout, render(hits))
	}
	fmt.Fprintf(stderr, "checklist: %d of %d rows hit by %d changed files against %s\n", len(hits), len(rows), len(ch.files), base)
	return nil
}

// git runs git in dir and returns its stdout; the error carries its stderr.
func git(dir string, args ...string) (string, error) {
	cmd := exec.Command("git", append([]string{"-C", dir, "-c", "core.quotePath=false"}, args...)...)
	var out, errb bytes.Buffer
	cmd.Stdout, cmd.Stderr = &out, &errb
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(errb.String()))
	}
	return out.String(), nil
}

// tableHeader finds the columns of the checklist table in a header row.
func tableHeader(cells []string) (trigger, check, incident int, ok bool) {
	trigger, check, incident = -1, -1, -1
	for i, c := range cells {
		switch strings.ToLower(c) {
		case "trigger":
			trigger = i
		case "check":
			check = i
		case "incident":
			incident = i
		}
	}
	return trigger, check, incident, trigger >= 0 && check >= 0 && incident >= 0
}

var separator = regexp.MustCompile(`^\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?$`)

var backticked = regexp.MustCompile("`([^`]+)`")

// parse reads the first table whose header names Trigger, Check and
// Incident, and fails on a row a reader could not act on.
func parse(text string) ([]row, error) {
	lines := strings.Split(text, "\n")
	for i := 0; i+1 < len(lines); i++ {
		head := strings.TrimSpace(lines[i])
		if !strings.HasPrefix(head, "|") || !separator.MatchString(strings.TrimSpace(lines[i+1])) {
			continue
		}
		tc, cc, ic, ok := tableHeader(cells(head))
		if !ok {
			continue
		}
		var rows []row
		for j := i + 2; j < len(lines); j++ {
			l := strings.TrimSpace(lines[j])
			if !strings.HasPrefix(l, "|") {
				break
			}
			r, err := parseRow(j+1, cells(l), tc, cc, ic)
			if err != nil {
				return nil, err
			}
			rows = append(rows, r)
		}
		return rows, nil
	}
	return nil, errors.New("no table with Trigger, Check and Incident columns")
}

func parseRow(line int, cs []string, tc, cc, ic int) (row, error) {
	cell := func(i int) string {
		if i < len(cs) {
			return cs[i]
		}
		return ""
	}
	r := row{line: line, trigger: cell(tc), check: cell(cc), incident: cell(ic)}
	if r.check == "" {
		return row{}, fmt.Errorf("line %d: Check is empty; say what to look at", line)
	}
	if r.incident == "" {
		return row{}, fmt.Errorf("line %d: Incident is empty; name the commit whose body tells what broke", line)
	}
	ms := backticked.FindAllStringSubmatch(r.trigger, -1)
	if len(ms) == 0 {
		return row{}, fmt.Errorf("line %d: Trigger has no `pattern`; write a path glob or a /regex/ in backticks", line)
	}
	for _, m := range ms {
		p, err := compile(m[1])
		if err != nil {
			return row{}, fmt.Errorf("line %d: %w", line, err)
		}
		r.patterns = append(r.patterns, p)
	}
	return r, nil
}

// cells splits a table row on the pipes that are not escaped as \|, and
// unescapes the rest.
func cells(line string) []string {
	line = strings.TrimSpace(line)
	line = strings.TrimPrefix(line, "|")
	if strings.HasSuffix(line, "|") && !strings.HasSuffix(line, `\|`) {
		line = line[:len(line)-1]
	}
	var out []string
	var cur strings.Builder
	for i := 0; i < len(line); i++ {
		switch {
		case line[i] == '\\' && i+1 < len(line) && line[i+1] == '|':
			cur.WriteByte('|')
			i++
		case line[i] == '|':
			out = append(out, strings.TrimSpace(cur.String()))
			cur.Reset()
		default:
			cur.WriteByte(line[i])
		}
	}
	return append(out, strings.TrimSpace(cur.String()))
}

// compile turns one Trigger entry into a pattern.
func compile(raw string) (pattern, error) {
	if len(raw) >= 2 && strings.HasPrefix(raw, "/") && strings.HasSuffix(raw, "/") {
		re, err := regexp.Compile(raw[1 : len(raw)-1])
		if err != nil {
			return pattern{}, fmt.Errorf("diff pattern `%s`: %w", raw, err)
		}
		return pattern{raw: raw, diff: re}, nil
	}
	if strings.HasPrefix(raw, "/") {
		return pattern{}, fmt.Errorf("glob `%s`: paths are repo-relative, drop the leading /, or close it with / for a diff regex", raw)
	}
	return pattern{raw: raw, path: glob(raw)}, nil
}

// glob compiles a path glob: * and ? within one segment, ** across them,
// and **/ for zero or more directories.
func glob(g string) *regexp.Regexp {
	var b strings.Builder
	b.WriteString("^")
	for i := 0; i < len(g); i++ {
		switch {
		case g[i] == '*' && i+1 < len(g) && g[i+1] == '*':
			i++
			if i+1 < len(g) && g[i+1] == '/' {
				i++
				b.WriteString("(?:.*/)?")
			} else {
				b.WriteString(".*")
			}
		case g[i] == '*':
			b.WriteString("[^/]*")
		case g[i] == '?':
			b.WriteString("[^/]")
		default:
			b.WriteString(regexp.QuoteMeta(g[i : i+1]))
		}
	}
	b.WriteString("$")
	return regexp.MustCompile(b.String())
}

func needsLines(rows []row) bool {
	for _, r := range rows {
		for _, p := range r.patterns {
			if p.diff != nil {
				return true
			}
		}
	}
	return false
}

// collect gathers the change: the commits since the merge base with base,
// the staged and unstaged edits, and the untracked files.
func collect(top, base string, withLines bool) (change, error) {
	seen := map[string]bool{}
	ch := change{lines: map[string][]string{}}
	add := func(out string) {
		for _, f := range strings.Split(out, "\n") {
			if f != "" && !seen[f] {
				seen[f] = true
				ch.files = append(ch.files, f)
			}
		}
	}
	for _, args := range [][]string{
		{"diff", "--name-only", "--no-renames", base + "...HEAD"},
		{"diff", "--name-only", "--no-renames", "HEAD"},
	} {
		out, err := git(top, args...)
		if err != nil {
			return change{}, err
		}
		add(out)
	}
	untracked, err := git(top, "ls-files", "--others", "--exclude-standard", "--full-name")
	if err != nil {
		return change{}, err
	}
	add(untracked)
	sort.Strings(ch.files)
	if !withLines {
		return ch, nil
	}

	for _, rng := range []string{base + "...HEAD", "HEAD"} {
		out, err := git(top, "diff", "--no-color", "--no-ext-diff", "--no-renames", "-U0",
			"--src-prefix=a/", "--dst-prefix=b/", rng)
		if err != nil {
			return change{}, err
		}
		for f, ls := range diffLines(out) {
			ch.lines[f] = append(ch.lines[f], ls...)
		}
	}
	for _, f := range strings.Split(untracked, "\n") {
		if f == "" {
			continue
		}
		data, err := os.ReadFile(filepath.Join(top, f))
		if err != nil || bytes.IndexByte(data, 0) >= 0 || !utf8.Valid(data) {
			continue // unreadable or binary: only its path can match
		}
		ch.lines[f] = append(ch.lines[f], strings.Split(string(data), "\n")...)
	}
	return ch, nil
}

// diffLines returns the added and removed lines of a unified diff per file.
// Header lines (---, +++) are told apart from content by position, since an
// added line can itself start with "++".
func diffLines(diff string) map[string][]string {
	out := map[string][]string{}
	var cur, old string
	header := false
	for _, l := range strings.Split(diff, "\n") {
		switch {
		case strings.HasPrefix(l, "diff --git "):
			header, cur, old = true, "", ""
		case header && strings.HasPrefix(l, "--- "):
			old = strings.TrimPrefix(strings.TrimPrefix(l, "--- "), "a/")
		case header && strings.HasPrefix(l, "+++ "):
			cur = strings.TrimPrefix(strings.TrimPrefix(l, "+++ "), "b/")
			if cur == "/dev/null" {
				cur = old
			}
		case strings.HasPrefix(l, "@@"):
			header = false
		case !header && cur != "" && (strings.HasPrefix(l, "+") || strings.HasPrefix(l, "-")):
			out[cur] = append(out[cur], l[1:])
		}
	}
	return out
}

// match returns the rows the change fires, in table order, each with the
// files that fired it.
func match(rows []row, ch change) []hit {
	var hits []hit
	for _, r := range rows {
		var matched []string
		seen := map[string]bool{}
		for _, f := range ch.files {
			for _, p := range r.patterns {
				if seen[f] || !fires(p, f, ch.lines[f]) {
					continue
				}
				seen[f] = true
				matched = append(matched, f)
			}
		}
		if len(matched) > 0 {
			hits = append(hits, hit{row: r, matched: matched})
		}
	}
	return hits
}

func fires(p pattern, f string, lines []string) bool {
	if p.path != nil {
		return p.path.MatchString(f)
	}
	for _, l := range lines {
		if p.diff.MatchString(l) {
			return true
		}
	}
	return false
}

// render writes the hits as a Markdown table, re-escaping pipes.
func render(hits []hit) string {
	esc := func(s string) string { return strings.ReplaceAll(s, "|", `\|`) }
	var b strings.Builder
	b.WriteString("| Trigger | Check | Incident | Matched |\n")
	b.WriteString("| --- | --- | --- | --- |\n")
	for _, h := range hits {
		ms := make([]string, len(h.matched))
		for i, m := range h.matched {
			ms[i] = "`" + m + "`"
		}
		fmt.Fprintf(&b, "| %s | %s | %s | %s |\n",
			esc(h.row.trigger), esc(h.row.check), esc(h.row.incident), esc(strings.Join(ms, ", ")))
	}
	return b.String()
}
