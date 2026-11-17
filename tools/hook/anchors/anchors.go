// Package anchors is `rat hook anchors`, a PreToolUse hook for Claude Code's
// Edit, MultiEdit, Write and NotebookEdit tools. It turns "read a file's
// anchors before editing it" from an instruction into a mechanism:
//
//   - the anchor comments in the edited file's directory come back as
//     additionalContext;
//   - an edit that leaves fewer anchor lines than it found returns
//     permissionDecision "ask", so the user confirms the removal;
//   - a line the edit adds with a HACK that has no issue URL, or with a
//     TODO / FIXME, comes back as a warning in additionalContext, without
//     stopping the edit.
//
// When none of these applies it writes nothing.
//
// AIDEV-NOTE: a HACK without an issue URL or a bare TODO is warned about, not refused with exit 2: the hook runs in every repository, and work in one with other conventions, or a shared one, would stop
// AIDEV-NOTE: the directory is read here rather than by calling rg --max-depth 1 as the shell hook did: rat needs no ripgrep at run time and lists in name order; rg's depth 1, hidden-file and binary skips are kept, .gitignore is not read
package anchors

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"unicode"
)

// The anchor markers are assembled so that this file does not show up in
// the anchor listing of its own directory.
var (
	hackOpen = "HACK" + "("
	noteTag  = "AIDEV" + "-NOTE"
	anchorRe = regexp.MustCompile(`HACK\(|AIDEV` + `-`)
	hackRe   = regexp.MustCompile(`HACK\(`)
	urlRe    = regexp.MustCompile(`^https?://`)
	todoRe   = regexp.MustCompile(`\b(TODO|FIXME)\b`)
)

// maxListed caps the listing, as head -40 did.
const maxListed = 40

type output struct {
	HookEventName            string `json:"hookEventName"`
	PermissionDecision       string `json:"permissionDecision,omitempty"`
	PermissionDecisionReason string `json:"permissionDecisionReason,omitempty"`
	AdditionalContext        string `json:"additionalContext,omitempty"`
}

// pair is one replacement an edit makes: old text out, new text in.
type pair struct{ old, new string }

func run(stdin io.Reader, stdout io.Writer) error {
	var in struct {
		ToolInput map[string]json.RawMessage `json:"tool_input"`
	}
	if err := json.NewDecoder(stdin).Decode(&in); err != nil {
		return fmt.Errorf("read hook input: %w", err)
	}
	t := in.ToolInput
	file := str(t["file_path"])
	if file == "" {
		file = str(t["notebook_path"])
	}
	if file == "" {
		return nil
	}
	dir := dirname(file)

	var found []string
	if _, err := os.Stat(file); err == nil {
		found = listAnchors(dir)
	}

	pairs, err := editPairs(t, file)
	if err != nil {
		return err
	}
	lost := 0
	var nourl, todo []string
	for _, p := range pairs {
		lost += countAnchors(p.old) - countAnchors(p.new)
		for _, line := range addedLines(p) {
			if missingURL(line) {
				nourl = append(nourl, line)
			}
			if todoRe.MatchString(line) {
				todo = append(todo, line)
			}
		}
	}

	var ctx []string
	if len(found) > 0 {
		ctx = append(ctx, "Anchors in "+dir+" (read before editing; update the one above code you change):\n"+
			strings.Join(found, "\n"))
	}
	if len(nourl)+len(todo) > 0 {
		warn := []string{"Comment warnings (not blocking):"}
		for _, l := range nourl {
			warn = append(warn, "- "+hackOpen+" without an issue URL: "+l+"\n  Write "+hackOpen+
				"<issue URL>): <what to remove once the issue is fixed>, or "+noteTag+
				": <the constraint or the rejected alternative> for a constraint from outside the code or an alternative tried and dropped; a workaround a type, lint rule or another API could remove is removed instead.")
		}
		for _, l := range todo {
			warn = append(warn, "- TODO/FIXME added: "+l+
				"\n  A bare TODO is not an anchor. Track it in an issue and write "+hackOpen+
				"<issue URL>), or, for a constraint from outside the code, "+noteTag+".")
		}
		ctx = append(ctx, strings.Join(warn, "\n"))
	}

	out := output{HookEventName: "PreToolUse", AdditionalContext: strings.Join(ctx, "\n\n")}
	if lost > 0 {
		out.PermissionDecision = "ask"
		out.PermissionDecisionReason = fmt.Sprintf(
			"This edit removes %d anchor line(s) (%s / %s). Anchors are not deleted unasked, except a HACK that leaves with the workaround it explains.",
			lost, hackOpen, noteTag)
	}
	if out.PermissionDecision == "" && out.AdditionalContext == "" {
		return nil
	}
	enc := json.NewEncoder(stdout)
	enc.SetEscapeHTML(false)
	return enc.Encode(map[string]output{"hookSpecificOutput": out})
}

// dirname returns the directory of p as dirname(1) does. filepath.Dir would
// clean the path, and the listing's header would no longer read as the
// path the tool call carried.
func dirname(p string) string {
	t := strings.TrimRight(p, "/")
	if t == "" {
		return "/"
	}
	i := strings.LastIndex(t, "/")
	if i < 0 {
		return "."
	}
	if d := strings.TrimRight(t[:i], "/"); d != "" {
		return d
	}
	return "/"
}

// str returns raw as a string, "" when it is absent, null or not a string.
func str(raw json.RawMessage) string {
	var s string
	if raw == nil || json.Unmarshal(raw, &s) != nil {
		return ""
	}
	return s
}

// editPairs returns the replacements the tool call makes. A Write replaces
// the whole file, so its old text is the file on disk. NotebookEdit carries
// no previous cell, so it has none and only gets the listing.
func editPairs(t map[string]json.RawMessage, file string) ([]pair, error) {
	if raw := bytes.TrimSpace(t["edits"]); len(raw) > 0 && raw[0] == '[' {
		var edits []map[string]json.RawMessage
		if err := json.Unmarshal(raw, &edits); err != nil {
			return nil, fmt.Errorf("read edits: %w", err)
		}
		pairs := make([]pair, 0, len(edits))
		for _, e := range edits {
			pairs = append(pairs, pair{str(e["old_string"]), str(e["new_string"])})
		}
		return pairs, nil
	}
	if _, ok := t["content"]; ok {
		before := ""
		if fi, err := os.Stat(file); err == nil && fi.Mode().IsRegular() {
			b, err := os.ReadFile(file)
			if err != nil {
				return nil, fmt.Errorf("read the file a Write replaces: %w", err)
			}
			before = string(b)
		}
		return []pair{{before, str(t["content"])}}, nil
	}
	if _, ok := t["new_string"]; ok {
		return []pair{{str(t["old_string"]), str(t["new_string"])}}, nil
	}
	return nil, nil
}

func countAnchors(s string) int {
	n := 0
	for _, line := range strings.Split(s, "\n") {
		if anchorRe.MatchString(line) {
			n++
		}
	}
	return n
}

// addedLines returns the lines of p.new that p.old does not have, with
// leading whitespace trimmed.
func addedLines(p pair) []string {
	old := map[string]bool{}
	for _, l := range strings.Split(p.old, "\n") {
		old[l] = true
	}
	var added []string
	for _, l := range strings.Split(p.new, "\n") {
		if !old[l] {
			added = append(added, strings.TrimLeftFunc(l, unicode.IsSpace))
		}
	}
	return added
}

// missingURL reports whether a HACK in line opens without an http(s) URL.
func missingURL(line string) bool {
	for _, loc := range hackRe.FindAllStringIndex(line, -1) {
		if !urlRe.MatchString(line[loc[1]:]) {
			return true
		}
	}
	return false
}

// listAnchors returns the anchor lines of the files directly in dir as
// "<name>:<line>:<text>", the way rg -n --no-heading --max-depth 1 printed
// them: subdirectories, hidden files, symlinks and binary files (a NUL byte)
// are skipped. Unreadable entries are skipped too, since the listing is a
// courtesy and must not stop the edit.
func listAnchors(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil
	}
	var found []string
	for _, e := range entries {
		name := e.Name()
		if strings.HasPrefix(name, ".") || !e.Type().IsRegular() {
			continue
		}
		data, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil || bytes.IndexByte(data, 0) >= 0 {
			continue
		}
		for i, line := range strings.Split(string(data), "\n") {
			if !anchorRe.MatchString(line) {
				continue
			}
			found = append(found, fmt.Sprintf("%s:%d:%s", name, i+1, line))
			if len(found) == maxListed {
				return found
			}
		}
	}
	return found
}
