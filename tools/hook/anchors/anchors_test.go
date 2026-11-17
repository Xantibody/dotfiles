package anchors

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"
)

// The fixture's anchors are built from pieces: written whole, this file
// would show up in the anchor listing of its own directory.
var (
	note     = "AIDEV" + "-NOTE: keep the order"
	note2    = "AIDEV" + "-NOTE: keep the order, the loader reads it top down"
	hack     = "HACK" + "(https://example.com/1): drop after the fix"
	bareHack = "HACK" + "(later): drop the retry"
)

// fixture lays out the directories the table edits. The hook lists the
// anchors of the edited file's directory at depth 1, so sub/deep.sh stays
// out of anchored's listing.
func fixture(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	write(t, root, "anchored/a.sh", "set -e\n# "+note+"\n")
	write(t, root, "anchored/nb.ipynb", `{"cells": []}`+"\n")
	write(t, root, "anchored/sub/deep.sh", "# "+hack+"\n")
	write(t, root, "plain/b.sh", "echo plain\n")
	return root
}

func write(t *testing.T, root, name, content string) {
	t.Helper()
	path := filepath.Join(root, name)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

// hook runs the hook on {"tool_input": toolInput} and returns its output,
// nil when it wrote nothing.
func hook(t *testing.T, toolInput map[string]any) *output {
	t.Helper()
	in, err := json.Marshal(map[string]any{"tool_input": toolInput})
	if err != nil {
		t.Fatal(err)
	}
	var out bytes.Buffer
	if err := run(bytes.NewReader(in), &out); err != nil {
		t.Fatalf("run: %v", err)
	}
	if out.Len() == 0 {
		return nil
	}
	if !bytes.HasSuffix(out.Bytes(), []byte("\n")) || bytes.Count(out.Bytes(), []byte("\n")) != 1 {
		t.Errorf("output %q is not one line of JSON", out.String())
	}
	var got struct {
		HookSpecificOutput *output `json:"hookSpecificOutput"`
	}
	if err := json.Unmarshal(out.Bytes(), &got); err != nil {
		t.Fatalf("output %q is not JSON: %v", out.String(), err)
	}
	if got.HookSpecificOutput == nil {
		t.Fatalf("output %q has no hookSpecificOutput", out.String())
	}
	if got.HookSpecificOutput.HookEventName != "PreToolUse" {
		t.Errorf("hookEventName = %q, want PreToolUse", got.HookSpecificOutput.HookEventName)
	}
	return got.HookSpecificOutput
}

// expectation checks one row's output.
type expectation func(t *testing.T, root string, got *output)

// silent: the hook writes nothing.
func silent() expectation {
	return func(t *testing.T, _ string, got *output) {
		if got != nil {
			t.Errorf("got %+v, want no output", *got)
		}
	}
}

// listed: no decision, and the anchors of dir (relative to the fixture) as
// the whole context.
func listed(dir string, lines ...string) expectation {
	return func(t *testing.T, root string, got *output) {
		if got == nil {
			t.Fatal("got no output, want the anchor listing")
		}
		if got.PermissionDecision != "" {
			t.Errorf("permissionDecision = %q, want none", got.PermissionDecision)
		}
		want := "Anchors in " + filepath.Join(root, dir) +
			" (read before editing; update the one above code you change):\n" +
			strings.Join(lines, "\n")
		if diff := cmp.Diff(want, got.AdditionalContext); diff != "" {
			t.Errorf("additionalContext (-want +got):\n%s", diff)
		}
	}
}

// listedA is the listing an edit of anchored/a.sh gets.
func listedA() expectation { return listed("anchored", "a.sh:2:# "+note) }

// asks: an edit that removes lost anchor lines asks the user.
func asks(lost int) expectation {
	return func(t *testing.T, _ string, got *output) {
		if got == nil {
			t.Fatal("got no output, want an ask")
		}
		if got.PermissionDecision != "ask" {
			t.Errorf("permissionDecision = %q, want ask", got.PermissionDecision)
		}
		prefix := fmt.Sprintf("This edit removes %d anchor line", lost)
		if !strings.HasPrefix(got.PermissionDecisionReason, prefix) {
			t.Errorf("permissionDecisionReason = %q, want prefix %q", got.PermissionDecisionReason, prefix)
		}
	}
}

// warns: no decision, and a warning context holding every needle.
func warns(needles ...string) expectation {
	return func(t *testing.T, _ string, got *output) {
		if got == nil {
			t.Fatal("got no output, want a warning")
		}
		if got.PermissionDecision != "" {
			t.Errorf("permissionDecision = %q, want none", got.PermissionDecision)
		}
		if !strings.HasPrefix(got.AdditionalContext, "Comment warnings (not blocking):") {
			t.Errorf("additionalContext = %q, want the warning header first", got.AdditionalContext)
		}
		for _, n := range needles {
			if !strings.Contains(got.AdditionalContext, n) {
				t.Errorf("additionalContext = %q, want it to contain %q", got.AdditionalContext, n)
			}
		}
	}
}

func TestHook(t *testing.T) {
	a := func(root string) string { return filepath.Join(root, "anchored/a.sh") }
	b := func(root string) string { return filepath.Join(root, "plain/b.sh") }
	edit := func(path func(string) string, old, new string) func(string) map[string]any {
		return func(root string) map[string]any {
			return map[string]any{"file_path": path(root), "old_string": old, "new_string": new}
		}
	}
	for _, tc := range []struct {
		name  string
		input func(root string) map[string]any
		want  expectation
	}{
		{"no path in the input", func(string) map[string]any {
			return map[string]any{"command": "ls"}
		}, silent()},
		{"path that does not exist", func(root string) map[string]any {
			return map[string]any{"file_path": filepath.Join(root, "anchored/new.sh")}
		}, silent()},
		{"dir without anchors", func(root string) map[string]any {
			return map[string]any{"file_path": b(root)}
		}, silent()},
		{"Edit in a dir with an anchor", func(root string) map[string]any {
			return map[string]any{"file_path": a(root)}
		}, listedA()},
		{"NotebookEdit in a dir with an anchor", func(root string) map[string]any {
			return map[string]any{"notebook_path": filepath.Join(root, "anchored/nb.ipynb")}
		}, listedA()},
		{"anchor in a subdir stays out of the parent", func(root string) map[string]any {
			return map[string]any{"file_path": filepath.Join(root, "anchored/sub/deep.sh")}
		}, listed("anchored/sub", "deep.sh:1:# "+hack)},

		{"Edit that drops an anchor", edit(a, "set -e\n# "+note, "set -e"), asks(1)},
		{"Edit that rewrites an anchor keeps the count", edit(a, "# "+note, "# "+note2), listedA()},
		{"MultiEdit whose edits drop an anchor in total", func(root string) map[string]any {
			return map[string]any{"file_path": a(root), "edits": []map[string]any{
				{"old_string": "# " + note, "new_string": ""},
				{"old_string": "set -e", "new_string": "set -eu"},
			}}
		}, asks(1)},
		{"MultiEdit that moves an anchor keeps the count", func(root string) map[string]any {
			return map[string]any{"file_path": a(root), "edits": []map[string]any{
				{"old_string": "# " + note, "new_string": ""},
				{"old_string": "set -e", "new_string": "# " + note + "\nset -e"},
			}}
		}, listedA()},
		{"Write over a file is measured against the file on disk", func(root string) map[string]any {
			return map[string]any{"file_path": a(root), "content": "set -e\n"}
		}, asks(1)},
		{"Write that keeps the file's anchor", func(root string) map[string]any {
			return map[string]any{"file_path": a(root), "content": "set -eu\n# " + note + "\n"}
		}, listedA()},

		{"Edit that adds a HACK without an issue URL",
			edit(b, "echo plain", "# "+bareHack+"\necho plain"),
			warns("without an issue URL: # " + bareHack)},
		{"Edit that adds a HACK with an issue URL",
			edit(b, "echo plain", "# "+hack+"\necho plain"),
			silent()},
		{"Write of a new file with a TODO and a FIXME", func(root string) map[string]any {
			return map[string]any{
				"file_path": filepath.Join(root, "plain/new.sh"),
				"content":   "# TODO: split this\n# FIXME: quote the path\necho new\n",
			}
		}, warns("TODO/FIXME added: # TODO: split this", "TODO/FIXME added: # FIXME: quote the path")},
		{"Edit that keeps a TODO already there",
			edit(b, "# TODO: split this\necho plain", "# TODO: split this\necho done"),
			silent()},
	} {
		t.Run(tc.name, func(t *testing.T) {
			root := fixture(t)
			tc.want(t, root, hook(t, tc.input(root)))
		})
	}
}

// The listing is that of rg --max-depth 1 in the file's directory: files at
// depth 1 in name order, hidden files and binary files skipped, at most 40
// lines.
func TestListing(t *testing.T) {
	root := t.TempDir()
	var many strings.Builder
	for i := range 45 {
		fmt.Fprintf(&many, "# %s %d\n", note, i)
	}
	write(t, root, "z.sh", many.String())
	write(t, root, "m.sh", "  # "+hack+"\n")
	write(t, root, ".hidden.sh", "# "+note+"\n")
	write(t, root, "bin.dat", "# "+note+"\n\x00")

	got := hook(t, map[string]any{"file_path": filepath.Join(root, "m.sh")})
	if got == nil {
		t.Fatal("got no output, want the anchor listing")
	}
	lines := strings.Split(got.AdditionalContext, "\n")[1:]
	if len(lines) != 40 {
		t.Errorf("listing has %d lines, want 40", len(lines))
	}
	if diff := cmp.Diff([]string{"m.sh:1:  # " + hack, "z.sh:1:# " + note + " 0"}, lines[:2]); diff != "" {
		t.Errorf("first lines (-want +got):\n%s", diff)
	}
}

// The header names the directory as dirname(1) spells it from the input,
// without cleaning the path.
func TestListingKeepsTheDirSpelling(t *testing.T) {
	root := fixture(t)
	got := hook(t, map[string]any{"file_path": root + "//anchored/a.sh"})
	if got == nil {
		t.Fatal("got no output, want the anchor listing")
	}
	want := "Anchors in " + root + "//anchored ("
	if !strings.HasPrefix(got.AdditionalContext, want) {
		t.Errorf("additionalContext = %q, want prefix %q", got.AdditionalContext, want)
	}
}

func TestDirname(t *testing.T) {
	for in, want := range map[string]string{
		"a.sh":       ".",
		"/a.sh":      "/",
		"/x/a.sh":    "/x",
		"/x//y/a.sh": "/x//y",
		"/x/y//a.sh": "/x/y",
		"/x/y/":      "/x",
		"//":         "/",
	} {
		if got := dirname(in); got != want {
			t.Errorf("dirname(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestRunRejectsBadInput(t *testing.T) {
	if err := run(strings.NewReader("not json"), &bytes.Buffer{}); err == nil {
		t.Error("run accepted input that is not JSON")
	}
}

func TestCommandReadsStdin(t *testing.T) {
	root := fixture(t)
	in, _ := json.Marshal(map[string]any{"tool_input": map[string]any{"file_path": filepath.Join(root, "anchored/a.sh")}})
	var out bytes.Buffer
	cmd := Command()
	cmd.SetIn(bytes.NewReader(in))
	cmd.SetOut(&out)
	cmd.SetErr(&bytes.Buffer{})
	cmd.SetArgs(nil)
	if err := cmd.Execute(); err != nil {
		t.Fatalf("Execute: %v", err)
	}
	if !strings.Contains(out.String(), `"additionalContext":"Anchors in `) {
		t.Errorf("stdout = %q, want the anchor listing", out.String())
	}
}
