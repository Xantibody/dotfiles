package validate

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestParseDocs(t *testing.T) {
	for _, tc := range []struct {
		name    string
		body    string
		fields  []string
		capN    int
		wantErr bool
	}{
		{
			name: "rows under the heading and the cap",
			body: "# Skills\n\nThe listing is truncated at 1,536 characters.\n\n" +
				"## Frontmatter reference\n\n| Field | Description |\n| --- | --- |\n" +
				"| `name` | the name |\n| `when_to_use` | when |\n",
			fields: []string{"name", "when_to_use"},
			capN:   1536,
		},
		{
			name:   "a following heading ends the table",
			body:   "### Frontmatter reference\n| `name` | x |\n\n## Examples\n| `not-a-field` | y |\n",
			fields: []string{"name"},
		},
		{
			name:    "heading missing",
			body:    "| `name` | x |\n",
			wantErr: true,
		},
		{
			name:    "heading with no rows",
			body:    "## Frontmatter reference\n\nSee below.\n\n## Next\n| `name` | x |\n",
			wantErr: true,
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			fields, capN, err := parseDocs(tc.body)
			if (err != nil) != tc.wantErr {
				t.Fatalf("parseDocs error = %v, want error %v", err, tc.wantErr)
			}
			if diff := cmp.Diff(tc.fields, fields); diff != "" {
				t.Errorf("fields (-want +got):\n%s", diff)
			}
			if capN != tc.capN {
				t.Errorf("cap = %d, want %d", capN, tc.capN)
			}
		})
	}
}

func TestParseBundled(t *testing.T) {
	got, err := parseBundled(
		"| Command | Purpose |\n| --- | --- |\n| `/verify` | runs the app |\n| `/help` | help |\n",
		"| `/verify` | again, on the other page |\n| `/run` | run |\nnot a row `/nope`\n",
	)
	if err != nil {
		t.Fatal(err)
	}
	if diff := cmp.Diff([]string{"help", "run", "verify"}, got); diff != "" {
		t.Errorf("names (-want +got):\n%s", diff)
	}
	if _, err := parseBundled("no table here"); err == nil {
		t.Error("parseBundled of pages without rows succeeded, want an error")
	}
}

// serveDocs points docsURL and commandsURLs at a local server answering
// every page with status and body.
func serveDocs(t *testing.T, status int, body string) {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(status)
		io.WriteString(w, body)
	}))
	t.Cleanup(srv.Close)
	oldDocs, oldCommands := docsURL, commandsURLs
	docsURL, commandsURLs = srv.URL+"/skills.md", []string{srv.URL + "/commands.md"}
	t.Cleanup(func() { docsURL, commandsURLs = oldDocs, oldCommands })
}

// Notes about the validator itself (the fetch failed, the fallback is stale)
// go to stderr; stdout carries the field list and the results only.
func TestSpecWarningsGoToStderr(t *testing.T) {
	for _, tc := range []struct {
		name, body string
		status     int
		stdout     string
		stderr     []string
	}{
		{
			name:   "docs moved",
			status: http.StatusOK,
			body: "The listing is truncated at 1,000 characters.\n## Frontmatter reference\n" +
				"| `name` | x |\n| `description` | y |\n## Commands\n| `/verify` | z |\n",
			stdout: "field list: docs (",
			stderr: []string{"docs differ from fallback", "bundled command names differ from fallback", "docs listing cap is 1000"},
		},
		{
			name:   "fetch failed",
			status: http.StatusInternalServerError,
			stdout: "field list: fallback (",
			stderr: []string{"could not fetch"},
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("HOME", t.TempDir())
			serveDocs(t, tc.status, tc.body)
			dir := writeSkill(t, t.TempDir(), "s", "", "body\n")
			var out, errOut strings.Builder
			run(t, []string{dir}, &out, &errOut)
			if !strings.Contains(out.String(), tc.stdout) {
				t.Errorf("stdout %q lacks %q", out.String(), tc.stdout)
			}
			for line := range strings.Lines(out.String()) {
				if strings.HasPrefix(line, "warn:") {
					t.Errorf("stdout has the validator's own warning %q", line)
				}
			}
			for _, want := range tc.stderr {
				if !strings.Contains(errOut.String(), want) {
					t.Errorf("stderr %q lacks %q", errOut.String(), want)
				}
			}
		})
	}
}

func TestDiffSets(t *testing.T) {
	onlyA, onlyB := diffSets(toSet([]string{"a", "c", "b"}), toSet([]string{"b", "d"}))
	if diff := cmp.Diff([]string{"a", "c"}, onlyA); diff != "" {
		t.Errorf("only in a (-want +got):\n%s", diff)
	}
	if diff := cmp.Diff([]string{"d"}, onlyB); diff != "" {
		t.Errorf("only in b (-want +got):\n%s", diff)
	}
	if onlyA, onlyB := diffSets(toSet([]string{"x"}), toSet([]string{"x"})); onlyA != nil || onlyB != nil {
		t.Errorf("equal sets differ: %v, %v", onlyA, onlyB)
	}
}
