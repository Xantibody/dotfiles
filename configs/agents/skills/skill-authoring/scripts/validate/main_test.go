package main

import (
	"archive/tar"
	"bytes"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// offlineSpec is the spec the validator uses with -offline.
func offlineSpec() spec { return loadSpec(true, io.Discard) }

// writeSkill makes dir/<name>/SKILL.md with the given extra frontmatter lines
// and body, and returns the skill directory.
func writeSkill(t *testing.T, dir, name, extra, body string) string {
	t.Helper()
	skill := filepath.Join(dir, name)
	if err := os.MkdirAll(skill, 0o755); err != nil {
		t.Fatal(err)
	}
	fm := "---\nname: " + name + "\ndescription: Does " + name + ".\n" + extra + "---\n"
	if err := os.WriteFile(filepath.Join(skill, "SKILL.md"), []byte(fm+body), 0o644); err != nil {
		t.Fatal(err)
	}
	return skill
}

func hasMatch(xs []string, sub string) bool {
	for _, x := range xs {
		if strings.Contains(x, sub) {
			return true
		}
	}
	return false
}

func TestValidSkillHasNoProblems(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	dir := writeSkill(t, t.TempDir(), "plain", "", "# Plain\n\nNothing to see.\n")
	problems, warnings, _ := validateSkill(dir, offlineSpec(), nil)
	if len(problems) > 0 || len(warnings) > 0 {
		t.Fatalf("problems %v, warnings %v", problems, warnings)
	}
}

func TestFrontmatterProblems(t *testing.T) {
	for _, tc := range []struct {
		name, extra, want string
	}{
		{"unknown field", "colour: red\n", `unknown frontmatter field "colour"`},
		{"nobody can invoke", "disable-model-invocation: true\nuser-invocable: false\n", "leave nobody able to invoke"},
		{"listing cap", "when_to_use: " + strings.Repeat("x", fallbackListingCap) + "\n", "the listing truncates"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("HOME", t.TempDir())
			dir := writeSkill(t, t.TempDir(), "s", tc.extra, "body\n")
			problems, _, _ := validateSkill(dir, offlineSpec(), nil)
			if !hasMatch(problems, tc.want) {
				t.Fatalf("want a problem containing %q, got %v", tc.want, problems)
			}
		})
	}
}

func TestNameMustMatchDirectory(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	root := t.TempDir()
	dir := writeSkill(t, root, "right", "", "body\n")
	if err := os.Rename(dir, filepath.Join(root, "wrong")); err != nil {
		t.Fatal(err)
	}
	problems, _, _ := validateSkill(filepath.Join(root, "wrong"), offlineSpec(), nil)
	if !hasMatch(problems, `"right" but the directory is "wrong"`) {
		t.Fatalf("got %v", problems)
	}
}

func TestReferenceToMissingSkill(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	root := t.TempDir()
	writeSkill(t, root, "there", "", "body\n")
	dir := writeSkill(t, root, "caller", "", "Load the `there` skill, then the `gone` skill, then the `plugin:skill` skill.\n")
	problems, _, _ := validateSkill(dir, offlineSpec(), nil)
	if len(problems) != 1 || !strings.Contains(problems[0], "`gone` skill") {
		t.Fatalf("want one problem for `gone`, got %v", problems)
	}
}

func TestLoadingHiddenSkill(t *testing.T) {
	for _, tc := range []struct {
		name, body string
		fails      bool
	}{
		{"load the x skill", "Load the `secret` skill for this.\n", true},
		{"use x", "Use `secret` for architecture questions.\n", true},
		{"via the x skill", "Report via the `secret` skill.\n", true},
		{"hand over to", "Then hand over to `secret`.\n", true},
		{"pointing at it", "That is the `secret` skill's question; see the `secret` skill.\n", false},
		{"handing the user the command", "Hand the user `/secret` to type.\n", false},
		{"listed skill", "Load the `open` skill.\n", false},
		{"not a skill", "Use `git` to read history.\n", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("HOME", t.TempDir())
			root := t.TempDir()
			writeSkill(t, root, "secret", "disable-model-invocation: true\n", "body\n")
			writeSkill(t, root, "open", "", "body\n")
			dir := writeSkill(t, root, "caller", "", tc.body)
			problems, _, _ := validateSkill(dir, offlineSpec(), nil)
			if got := hasMatch(problems, "disable-model-invocation"); got != tc.fails {
				t.Fatalf("fails = %v, want %v: %v", got, tc.fails, problems)
			}
		})
	}
}

func TestKnownSkillResolvesReferences(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	elsewhere := t.TempDir()
	outside := writeSkill(t, elsewhere, "outside", "", "body\n")
	hiddenOutside := writeSkill(t, elsewhere, "hidden-outside", "disable-model-invocation: true\n", "body\n")
	dir := writeSkill(t, t.TempDir(), "caller", "", "Load the `outside` skill. Then load the `hidden-outside` skill.\n")
	known := map[string]string{"outside": outside, "hidden-outside": hiddenOutside}
	problems, _, _ := validateSkill(dir, offlineSpec(), known)
	if len(problems) != 1 || !strings.Contains(problems[0], "`hidden-outside`") {
		t.Fatalf("want one problem for the hidden known skill, got %v", problems)
	}
}

// makeRepo returns a directory that looks like the repository root (it holds
// flake.nix) with the given files created empty.
func makeRepo(t *testing.T, files ...string) string {
	t.Helper()
	root := t.TempDir()
	for _, f := range append([]string{"flake.nix"}, files...) {
		p := filepath.Join(root, f)
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, nil, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func TestBodyPathThatDoesNotExist(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	root := makeRepo(t, "modules/real.nix")
	body := "See `modules/real.nix`, `modules/gone.nix`, `configs/<name>/` and `scripts/x.go`.\n"
	dir := writeSkill(t, filepath.Join(root, "configs/agents/skills"), "s", "", body)
	problems, warnings, _ := validateSkill(dir, offlineSpec(), nil)
	if len(problems) > 0 || len(warnings) != 1 || !strings.Contains(warnings[0], "`modules/gone.nix`") {
		t.Fatalf("want one warning for modules/gone.nix, got problems %v, warnings %v", problems, warnings)
	}
}

func TestBodyPathOutsideAnyRepository(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	dir := writeSkill(t, t.TempDir(), "s", "", "See `modules/gone.nix`.\n")
	_, warnings, _ := validateSkill(dir, offlineSpec(), nil)
	if len(warnings) > 0 {
		t.Fatalf("a skill outside a repository has no paths to check, got %v", warnings)
	}
}

func writeEvals(t *testing.T, dir string, prompts ...string) {
	t.Helper()
	var evals []string
	for i, p := range prompts {
		evals = append(evals, `{"id": `+string(rune('0'+i))+`, "prompt": `+quote(p)+`}`)
	}
	if err := os.MkdirAll(filepath.Join(dir, "evals"), 0o755); err != nil {
		t.Fatal(err)
	}
	content := `{"skill_name": "s", "evals": [` + strings.Join(evals, ",") + `]}`
	if err := os.WriteFile(filepath.Join(dir, "evals", "evals.json"), []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}

func quote(s string) string {
	r := strings.NewReplacer(`\`, `\\`, `"`, `\"`, "\n", `\n`)
	return `"` + r.Replace(s) + `"`
}

func TestEvalPromptPaths(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	root := makeRepo(t, "overlays/real.nix", "modules/ai/agents.nix")
	dir := writeSkill(t, filepath.Join(root, "configs/agents/skills"), "s", "", "body\n")
	writeEvals(t, dir,
		"modules/darwin/以下のモジュールについて、docs/modules/darwin.mdを作成して",
		"Read `overlays/real.nix` and modules/ai/agents.nix, then https://github.com/x/modules/gone.",
		"Working directory: /elsewhere. Read modules/gone.nix there.",
	)
	problems, warnings, _ := validateSkill(dir, offlineSpec(), nil)
	if len(problems) > 0 || len(warnings) != 1 || !strings.Contains(warnings[0], "modules/darwin/") {
		t.Fatalf("want one warning for modules/darwin/, got problems %v, warnings %v", problems, warnings)
	}
}

func TestEvalPromptCommitHashes(t *testing.T) {
	git, err := exec.LookPath("git")
	if err != nil {
		t.Skip("git not on PATH")
	}
	t.Setenv("HOME", t.TempDir())
	root := makeRepo(t)
	for _, args := range [][]string{
		{"init", "-q"},
		{"add", "flake.nix"},
		{"-c", "user.name=t", "-c", "user.email=t@example.com", "-c", "commit.gpgsign=false", "commit", "-q", "-m", "init"},
	} {
		cmd := exec.Command(git, append([]string{"-C", root}, args...)...)
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v\n%s", args, err, out)
		}
	}
	out, err := exec.Command(git, "-C", root, "rev-parse", "--short=7", "HEAD").Output()
	if err != nil {
		t.Fatal(err)
	}
	real := strings.TrimSpace(string(out))
	dir := writeSkill(t, filepath.Join(root, "configs/agents/skills"), "s", "", "body\n")
	writeEvals(t, dir, "Read the range `"+real+"^..abc1234` and decide; ignore deadbeef and 1234567.")
	problems, warnings, notes := validateSkill(dir, offlineSpec(), nil)
	if len(problems) > 0 || len(notes) > 0 || len(warnings) != 1 || !strings.Contains(warnings[0], "abc1234") {
		t.Fatalf("want one warning for abc1234, got problems %v, warnings %v, notes %v", problems, warnings, notes)
	}
}

func TestEvalPromptCommitHashesWithoutHistory(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	root := makeRepo(t)
	dir := writeSkill(t, filepath.Join(root, "configs/agents/skills"), "s", "", "body\n")
	writeEvals(t, dir, "Read the range abc1234^..def5678.")
	_, warnings, notes := validateSkill(dir, offlineSpec(), nil)
	if len(warnings) > 0 || !hasMatch(notes, "not checked") {
		t.Fatalf("want a note that hashes were not checked, got warnings %v, notes %v", warnings, notes)
	}
}

func writeReadme(t *testing.T, content string) string {
	t.Helper()
	p := filepath.Join(t.TempDir(), "README.md")
	if err := os.WriteFile(p, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	return p
}

const readmeFixture = "# skills\n\n```mermaid\nflowchart TD\n" +
	"  a[\"alpha<br/>does a\"]\n" +
	"  b[\"beta\"]\n" +
	"  sc[\"skill-creator (plugin)<br/>drafts\"]\n" +
	"  user([\"the user types /name\"])\n" +
	"  tool[/\"lint-body<br/>a command\"/]\n" +
	"  subgraph shot [\"screens\"]\n    o[\"outside<br/>known\"]\n  end\n" +
	"  a --> b\n```\n\n" +
	"Skills nothing loads:\n\n- `gamma` — called directly\n"

func TestReadmeMatchesSkills(t *testing.T) {
	path := writeReadme(t, readmeFixture)
	problems := checkReadme(path, []string{"alpha", "beta", "gamma"}, map[string]string{"outside": "/x"})
	if len(problems) > 0 {
		t.Fatalf("got %v", problems)
	}
}

func TestReadmeDrift(t *testing.T) {
	path := writeReadme(t, readmeFixture)
	problems := checkReadme(path, []string{"alpha", "gamma", "delta"}, nil)
	for _, want := range []string{"`delta`", "`beta`", "`outside`"} {
		if !hasMatch(problems, want) {
			t.Errorf("want a problem naming %s, got %v", want, problems)
		}
	}
	if len(problems) != 3 {
		t.Fatalf("want 3 problems, got %v", problems)
	}
}

func TestRunStrictFailsOnWarnings(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	root := makeRepo(t)
	dir := writeSkill(t, filepath.Join(root, "configs/agents/skills"), "s", "", "See `modules/gone.nix`.\n")
	var out strings.Builder
	if code := run([]string{"-offline", dir}, &out); code != 0 {
		t.Fatalf("a warning alone exits %d, want 0:\n%s", code, out.String())
	}
	out.Reset()
	if code := run([]string{"-offline", "-strict", dir}, &out); code != 1 {
		t.Fatalf("-strict exits %d on a warning, want 1:\n%s", code, out.String())
	}
}

// archiveSkills extracts configs/agents/skills at rev from the repository
// this test runs in and returns the extracted skills directory. It skips
// when there is no history to read: the nix sandbox builds from a store path
// without .git, and a shallow clone may lack rev.
func archiveSkills(t *testing.T, rev string) string {
	t.Helper()
	git, err := exec.LookPath("git")
	if err != nil {
		t.Skip("git not on PATH")
	}
	top, err := exec.Command(git, "rev-parse", "--show-toplevel").Output()
	if err != nil {
		t.Skip("not inside a git checkout")
	}
	repo := strings.TrimSpace(string(top))
	if exec.Command(git, "-C", repo, "cat-file", "-e", rev+"^{commit}").Run() != nil {
		t.Skipf("commit %s not in this clone", rev)
	}
	archive, err := exec.Command(git, "-C", repo, "archive", rev, "configs/agents/skills").Output()
	if err != nil {
		t.Fatalf("git archive %s: %v", rev, err)
	}
	dest := t.TempDir()
	tr := tar.NewReader(bytes.NewReader(archive))
	for {
		h, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		p := filepath.Join(dest, h.Name)
		switch h.Typeflag {
		case tar.TypeDir:
			err = os.MkdirAll(p, 0o755)
		case tar.TypeReg:
			var data []byte
			if data, err = io.ReadAll(tr); err == nil {
				err = os.WriteFile(p, data, 0o644)
			}
		}
		if err != nil {
			t.Fatal(err)
		}
	}
	return filepath.Join(dest, "configs/agents/skills")
}

// problemsAt validates every skill in dir, with the skills that flake inputs
// ship (checks.skills passes them with -known) stubbed in.
func problemsAt(t *testing.T, dir string) []string {
	t.Helper()
	stubs := t.TempDir()
	known := map[string]string{}
	for _, name := range []string{"osekkai", "ha"} {
		known[name] = writeSkill(t, stubs, name, "", "body\n")
	}
	skills, err := filepath.Glob(filepath.Join(dir, "*", "SKILL.md"))
	if err != nil {
		t.Fatal(err)
	}
	var all []string
	for _, s := range skills {
		problems, _, _ := validateSkill(filepath.Dir(s), offlineSpec(), known)
		for _, p := range problems {
			all = append(all, filepath.Base(filepath.Dir(s))+": "+p)
		}
	}
	return all
}

// The two kinds of broken skill reference that happened twice each: a body
// that still loads a skill the commit hid, and one that names a skill the
// commit renamed. Each check must fire on the commit that caused the
// incident and stay quiet on HEAD, so it neither misses the incident nor
// fails a clean tree.
func TestSkillReferenceIncidents(t *testing.T) {
	for _, tc := range []struct {
		name, incident, class, want string
	}{
		{"a589d72 hid design, implement still loaded it", "a589d72", "so the model cannot load it", "implement: body loads the `design` skill"},
		{"761b40d renamed history-review, skill-authoring still named it", "761b40d", "body refers to the", "skill-authoring: body refers to the `history-review` skill"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("HOME", t.TempDir())
			if got := problemsAt(t, archiveSkills(t, tc.incident)); !hasMatch(got, tc.want) {
				t.Errorf("at %s want a problem %q, got %v", tc.incident, tc.want, got)
			}
			var atHead []string
			for _, p := range problemsAt(t, archiveSkills(t, "HEAD")) {
				if strings.Contains(p, tc.class) {
					atHead = append(atHead, p)
				}
			}
			if len(atHead) > 0 {
				t.Errorf("at HEAD want no %q problem, got %v", tc.class, atHead)
			}
		})
	}
}

func TestRunReadmeAndKnown(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	skills := t.TempDir()
	alpha := writeSkill(t, skills, "alpha", "", "Load the `outside` skill.\n")
	outside := writeSkill(t, t.TempDir(), "outside", "", "body\n")
	readme := writeReadme(t, "```mermaid\nflowchart TD\n  a[\"alpha\"]\n  o[\"outside\"]\n```\n")
	var out strings.Builder
	if code := run([]string{"-offline", "-readme", readme, "-known", outside, alpha}, &out); code != 0 {
		t.Fatalf("exit %d:\n%s", code, out.String())
	}
	out.Reset()
	if code := run([]string{"-offline", "-readme", readme, alpha}, &out); code != 1 {
		t.Fatalf("without -known the reference and the README node are unknown; exit %d:\n%s", code, out.String())
	}
}
