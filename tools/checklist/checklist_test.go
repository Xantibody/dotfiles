package checklist

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

func TestGlob(t *testing.T) {
	cases := []struct {
		glob, path string
		want       bool
	}{
		{".github/workflows/darwin.yml", ".github/workflows/darwin.yml", true},
		{".github/workflows/darwin.yml", ".github/workflows/darwin.yaml", false},
		{"*.nix", "flake.nix", true},
		{"*.nix", "modules/flake.nix", false}, // the whole path, not the base name
		{"modules/*", "modules/a.nix", true},
		{"modules/*", "modules/hosts/a.nix", false},
		{"modules/**", "modules/hosts/a.nix", true},
		{"modules/**/*.nix", "modules/a.nix", true}, // **/ is zero or more directories
		{"modules/**/*.nix", "modules/hosts/x/a.nix", true},
		{"modules/**/*.nix", "modules/hosts/a.txt", false},
		{"a?c", "abc", true},
		{"a?c", "a/c", false},
		{"a.b", "axb", false}, // a dot is a dot
	}
	for _, c := range cases {
		if got := glob(c.glob).MatchString(c.path); got != c.want {
			t.Errorf("glob(%q) on %q = %v, want %v", c.glob, c.path, got, c.want)
		}
	}
}

func TestCellsSplitsOnUnescapedPipes(t *testing.T) {
	got := cells("| `/a\\|b/` | look | abc1234 |")
	want := []string{"`/a|b/`", "look", "abc1234"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("cells = %q, want %q", got, want)
	}
}

const checklist = `# Review

Some prose first, and an unrelated table:

| Name | Value |
| ---- | ----- |
| x    | y     |

| Trigger | Check | Incident |
| --- | --- | --- |
| ` + "`.github/workflows/darwin.yml`, `flake.lock`" + ` | The darwin build still runs | 49f2f2d |
| ` + "`/darwinConfigurations\\|eval-/`" + ` | Every host has an eval check | ba2d720 |

Prose after the table.
`

func TestParseReadsTheChecklistTable(t *testing.T) {
	rows, err := parse(checklist)
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 {
		t.Fatalf("got %d rows, want 2", len(rows))
	}
	if r := rows[0]; len(r.patterns) != 2 || r.patterns[0].path == nil || r.check != "The darwin build still runs" || r.incident != "49f2f2d" || r.line != 11 {
		t.Errorf("row 0 = %+v", r)
	}
	if p := rows[1].patterns[0]; p.diff == nil || !p.diff.MatchString("checks.eval-host") {
		t.Errorf("row 1 pattern = %+v, want a diff regex with the escaped pipe as alternation", p)
	}
}

func TestParseRejectsRowsNobodyCanActOn(t *testing.T) {
	head := "| Trigger | Check | Incident |\n| --- | --- | --- |\n"
	cases := map[string]struct{ text, want string }{
		"no table":        {"# Review\n\nnothing here\n", "no table with Trigger, Check and Incident"},
		"no incident":     {head + "| `a` | look |  |\n", "Incident is empty"},
		"no check":        {head + "| `a` |  | abc |\n", "Check is empty"},
		"no pattern":      {head + "| a | look | abc |\n", "Trigger has no `pattern`"},
		"bad regex":       {head + "| `/(/` | look | abc |\n", "diff pattern"},
		"absolute glob":   {head + "| `/etc/x` | look | abc |\n", "drop the leading /"},
		"columns by name": {"| Check | Incident | Trigger |\n| - | - | - |\n| look | abc |  |\n", "Trigger has no `pattern`"},
	}
	for name, c := range cases {
		_, err := parse(c.text)
		if err == nil || !strings.Contains(err.Error(), c.want) {
			t.Errorf("%s: err = %v, want it to contain %q", name, err, c.want)
		}
	}
}

func TestDiffLinesTellsHeadersFromContent(t *testing.T) {
	diff := `diff --git a/x.txt b/x.txt
--- a/x.txt
+++ b/x.txt
@@ -1 +1 @@
-old
+++ added line that looks like a header
diff --git a/gone.txt b/gone.txt
deleted file mode 100644
--- a/gone.txt
+++ /dev/null
@@ -1 +0,0 @@
-removed
diff --git a/bin.png b/bin.png
Binary files a/bin.png and b/bin.png differ
`
	got := diffLines(diff)
	want := map[string][]string{
		"x.txt":    {"old", "++ added line that looks like a header"},
		"gone.txt": {"removed"},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("diffLines = %q, want %q", got, want)
	}
}

func TestMatchFiresOnPathsAndDiffLines(t *testing.T) {
	rows, err := parse(checklist)
	if err != nil {
		t.Fatal(err)
	}
	cases := map[string]struct {
		ch   change
		want map[string][]string // incident -> matched files
	}{
		"nothing": {change{files: []string{"README.md"}}, map[string][]string{}},
		"path": {
			change{files: []string{".github/workflows/darwin.yml", "flake.lock", "README.md"}},
			map[string][]string{"49f2f2d": {".github/workflows/darwin.yml", "flake.lock"}},
		},
		"diff line": {
			change{files: []string{"modules/flake/checks.nix"}, lines: map[string][]string{
				"modules/flake/checks.nix": {"  checks.eval-foo = x;"},
			}},
			map[string][]string{"ba2d720": {"modules/flake/checks.nix"}},
		},
	}
	for name, c := range cases {
		got := map[string][]string{}
		for _, h := range match(rows, c.ch) {
			got[h.row.incident] = h.matched
		}
		if !reflect.DeepEqual(got, c.want) {
			t.Errorf("%s: hits = %v, want %v", name, got, c.want)
		}
	}
}

// repo makes a git repository with REVIEW.md (when text is not empty) and
// a.txt committed on main, then checks out a branch "work".
func repo(t *testing.T, text string) string {
	t.Helper()
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git not on PATH")
	}
	t.Setenv("GIT_CONFIG_GLOBAL", os.DevNull)
	t.Setenv("GIT_CONFIG_NOSYSTEM", "1")
	t.Setenv("GIT_AUTHOR_NAME", "t")
	t.Setenv("GIT_AUTHOR_EMAIL", "t@example.com")
	t.Setenv("GIT_COMMITTER_NAME", "t")
	t.Setenv("GIT_COMMITTER_EMAIL", "t@example.com")
	dir := t.TempDir()
	write(t, dir, "a.txt", "a\n")
	if text != "" {
		write(t, dir, file, text)
	}
	gitT(t, dir, "init", "-q", "-b", "main")
	gitT(t, dir, "add", "-A")
	gitT(t, dir, "commit", "-q", "-m", "base")
	gitT(t, dir, "switch", "-q", "-c", "work")
	return dir
}

func write(t *testing.T, dir, name, text string) {
	t.Helper()
	p := filepath.Join(dir, name)
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
}

func gitT(t *testing.T, dir string, args ...string) {
	t.Helper()
	if out, err := exec.Command("git", append([]string{"-C", dir}, args...)...).CombinedOutput(); err != nil {
		t.Fatalf("git %v: %v\n%s", args, err, out)
	}
}

// runT executes `rat checklist` with args against the repository at dir and
// returns the code rat exits with and the two streams.
func runT(dir string, args ...string) (code int, stdout, stderr string) {
	var o, e bytes.Buffer
	cmd := command(dir)
	cmd.SetArgs(args)
	cmd.SetOut(&o)
	cmd.SetErr(&e)
	code = cli.Exit(cmd.Execute(), &e)
	return code, o.String(), e.String()
}

func TestRunPrintsTheRowsACommittedChangeHits(t *testing.T) {
	dir := repo(t, checklist)
	write(t, dir, ".github/workflows/darwin.yml", "on: push\n")
	gitT(t, dir, "add", "-A")
	gitT(t, dir, "commit", "-q", "-m", "touch darwin")

	code, out, errs := runT(dir, "--base", "main")
	if code != 0 {
		t.Fatalf("exit %d: %s", code, errs)
	}
	if !strings.Contains(out, "| The darwin build still runs | 49f2f2d | `.github/workflows/darwin.yml` |") {
		t.Errorf("stdout lacks the darwin row:\n%s", out)
	}
	if strings.Contains(out, "ba2d720") {
		t.Errorf("stdout has a row the change did not hit:\n%s", out)
	}
	if !strings.Contains(errs, "1 of 2 rows") {
		t.Errorf("stderr lacks the summary: %s", errs)
	}
}

func TestRunSeesStagedUnstagedAndUntrackedChanges(t *testing.T) {
	dir := repo(t, checklist)
	write(t, dir, "a.txt", "checks.eval-new\n") // unstaged edit, hit by the regex
	write(t, dir, "flake.lock", "{}\n")         // untracked, hit by the glob

	code, out, errs := runT(dir, "--base", "main")
	if code != 0 {
		t.Fatalf("exit %d: %s", code, errs)
	}
	for _, want := range []string{"49f2f2d | `flake.lock`", "ba2d720 | `a.txt`"} {
		if !strings.Contains(out, want) {
			t.Errorf("stdout lacks %q:\n%s", want, out)
		}
	}
}

func TestRunReadsTheChecklistFromTheBase(t *testing.T) {
	dir := repo(t, checklist)
	// The branch drops the darwin row and touches what it guards.
	write(t, dir, file, strings.Replace(checklist, "The darwin build still runs", "", 1))
	write(t, dir, ".github/workflows/darwin.yml", "on: push\n")

	code, out, errs := runT(dir, "--base", "main")
	if code != 0 {
		t.Fatalf("exit %d: %s", code, errs)
	}
	if !strings.Contains(out, "The darwin build still runs") {
		t.Errorf("the base's row did not apply:\n%s", out)
	}
	if !strings.Contains(errs, "differs from main") {
		t.Errorf("stderr does not say the branch's REVIEW.md differs: %s", errs)
	}
}

func TestRunWithoutAChecklistOnTheBaseIsANote(t *testing.T) {
	dir := repo(t, "")
	write(t, dir, file, checklist) // added on the branch only

	code, out, errs := runT(dir, "--base", "main")
	if code != 0 || out != "" {
		t.Fatalf("exit %d, stdout %q; want 0 and nothing", code, out)
	}
	if !strings.Contains(errs, "no REVIEW.md on main") || !strings.Contains(errs, "differs from main") {
		t.Errorf("stderr = %s", errs)
	}
}

func TestRunFailsLoudlyOnAMissingBase(t *testing.T) {
	dir := repo(t, checklist)
	if code, _, errs := runT(dir); code != 1 || !strings.Contains(errs, "origin/HEAD is not set") {
		t.Errorf("no --base: exit %d, stderr %s", code, errs)
	}
	if code, _, errs := runT(dir, "--base", "nope"); code != 1 || !strings.Contains(errs, `--base "nope" is not a commit`) {
		t.Errorf("bad --base: exit %d, stderr %s", code, errs)
	}
}

func TestRunUsageErrors(t *testing.T) {
	dir := repo(t, checklist)
	for _, args := range [][]string{
		{"--base", "main", "extra"},
		{"-base", "main"}, // the go-run spelling
		{"--bsae", "main"},
	} {
		if code, out, _ := runT(dir, args...); code != 2 || out != "" {
			t.Errorf("%v: exit %d, stdout %q; want 2 and nothing on stdout", args, code, out)
		}
	}
}

func TestRunFailsOnABrokenChecklist(t *testing.T) {
	dir := repo(t, "| Trigger | Check | Incident |\n| - | - | - |\n| `a.txt` | look |  |\n")
	if code, _, errs := runT(dir, "--base", "main"); code != 1 || !strings.Contains(errs, "Incident is empty") {
		t.Errorf("exit %d, stderr %s", code, errs)
	}
}
