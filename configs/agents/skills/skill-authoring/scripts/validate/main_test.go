package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// offlineSpec is the spec the validator uses with -offline.
func offlineSpec() spec { return loadSpec(true) }

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
	problems, warnings := validateSkill(dir, offlineSpec())
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
			problems, _ := validateSkill(dir, offlineSpec())
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
	problems, _ := validateSkill(filepath.Join(root, "wrong"), offlineSpec())
	if !hasMatch(problems, `"right" but the directory is "wrong"`) {
		t.Fatalf("got %v", problems)
	}
}

func TestReferenceToMissingSkill(t *testing.T) {
	t.Setenv("HOME", t.TempDir())
	root := t.TempDir()
	writeSkill(t, root, "there", "", "body\n")
	dir := writeSkill(t, root, "caller", "", "Load the `there` skill, then the `gone` skill, then the `plugin:skill` skill.\n")
	problems, _ := validateSkill(dir, offlineSpec())
	if len(problems) != 1 || !strings.Contains(problems[0], "`gone` skill") {
		t.Fatalf("want one problem for `gone`, got %v", problems)
	}
}
