// validate checks SKILL.md frontmatter against the field list Claude Code
// documents today, so a skill is never rejected — or silently ignored — for a
// field that the spec added or removed after some validator froze its list.
//
//	go run main.go [-offline] <skill-dir>...
//
// The allowed fields come from the "Frontmatter reference" table on
// https://code.claude.com/docs/en/skills.md, fetched on every run. When the
// fetch fails the baked-in fallback is used and named as such; when the fetch
// succeeds and differs from the fallback, that difference is printed, because
// it means the spec moved and fallbackFields below needs updating.
//
// Only the standard library is used so that `go run` works without a module.
package main

import (
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

const docsURL = "https://code.claude.com/docs/en/skills.md"

// commandsURLs are the pages that list Claude Code's bundled skills and
// built-in commands. A user skill with the same directory name overrides
// the bundled one (the docs say so), which is allowed but easy to do by
// accident — `verify` is both a bundled skill that runs the app and, here,
// the lint/test/fmt skill. The validator warns rather than fails.
var commandsURLs = []string{
	"https://code.claude.com/docs/en/slash-commands.md",
	"https://code.claude.com/docs/en/commands.md",
}

// fallbackBundled is the set of bundled skill and built-in command names
// seen on commandsURLs as of fallbackDate. Update it when the validator
// reports a difference; the message lists the names to add or remove.
var fallbackBundled = []string{
	"agents", "artifacts", "auto-mode-setup", "chrome", "cost", "design-login",
	"desktop", "diff", "doctor", "exit", "fewer-permission-prompts", "focus",
	"heapdump", "help", "hooks", "ide", "init", "insights", "install-github-app",
	"install-slack-app", "keybindings", "list-agents", "login", "logout",
	"memory", "mobile", "passes", "permissions", "powerup", "privacy-settings",
	"radio", "rate-limit-options", "recap", "release-notes", "reload-skills",
	"remote-control", "remote-env", "rewind", "run", "run-skill-generator",
	"sandbox", "scroll-speed", "security-review", "setup-bedrock",
	"setup-vertex", "skill-doctor", "skills", "stats", "status", "statusline",
	"stickers", "stop", "tasks", "team-onboarding", "teleport",
	"terminal-setup", "theme", "upgrade", "usage", "usage-credits", "verify",
	"vim", "web-setup", "workflow-authoring", "workflows",
}

// fallbackFields is the Frontmatter reference table as of fallbackDate.
// Update both when the validator reports a difference from the live docs.
const fallbackDate = "2026-09-06"

var fallbackFields = []string{
	"name", "description", "when_to_use", "argument-hint", "arguments",
	"disable-model-invocation", "user-invocable", "allowed-tools",
	"disallowed-tools", "model", "effort", "context", "agent", "background",
	"hooks", "paths", "shell", "metadata", "license", "compatibility",
}

// fallbackListingCap is the combined description + when_to_use length at
// which the skill listing truncates, as documented on fallbackDate.
const fallbackListingCap = 1536

// compatibilityCap is the documented maximum length of `compatibility`.
const compatibilityCap = 500

// bodyLineWarn is skill-creator's guidance for when a body should grow a
// references/ layer instead of more lines.
const bodyLineWarn = 500

type spec struct {
	fields     map[string]bool
	listingCap int
	source     string // "docs" or "fallback (<date>)"
	bundled    map[string]bool
}

func main() {
	offline := flag.Bool("offline", false, "skip fetching the docs; use the baked-in field list")
	flag.Parse()
	dirs := flag.Args()
	if len(dirs) == 0 {
		fmt.Fprintln(os.Stderr, "usage: go run main.go [-offline] <skill-dir>...")
		os.Exit(2)
	}

	sp := loadSpec(*offline)
	fmt.Printf("field list: %s\n", sp.source)

	failed := false
	for _, dir := range dirs {
		problems, warnings := validateSkill(dir, sp)
		status := "OK"
		if len(problems) > 0 {
			status = "FAIL"
			failed = true
		}
		fmt.Printf("%s: %s\n", filepath.Clean(dir), status)
		for _, p := range problems {
			fmt.Printf("  error: %s\n", p)
		}
		for _, w := range warnings {
			fmt.Printf("  warn:  %s\n", w)
		}
	}
	if failed {
		os.Exit(1)
	}
}

// loadSpec fetches the live field list, falling back to the baked-in one and
// reporting any drift between them.
func loadSpec(offline bool) spec {
	fb := spec{fields: toSet(fallbackFields), listingCap: fallbackListingCap, source: "fallback (" + fallbackDate + ")", bundled: toSet(fallbackBundled)}
	if offline {
		return fb
	}
	live, capN, err := fetchDocs()
	if err != nil {
		fmt.Printf("warn:  could not fetch %s (%v); using %s\n", docsURL, err, fb.source)
		return fb
	}
	if capN == 0 {
		capN = fallbackListingCap
	}
	sp := spec{fields: toSet(live), listingCap: capN, source: "docs (" + docsURL + ")", bundled: fb.bundled}
	if names, err := fetchBundled(); err != nil {
		fmt.Printf("warn:  could not fetch the command pages (%v); using the fallback bundled-name list\n", err)
	} else {
		sp.bundled = toSet(names)
		if added, removed := diffSets(sp.bundled, fb.bundled); len(added) > 0 || len(removed) > 0 {
			fmt.Printf("warn:  bundled command names differ from fallback: added %v, removed %v — update fallbackBundled in main.go\n", added, removed)
		}
	}
	added, removed := diffSets(sp.fields, fb.fields)
	if len(added) > 0 || len(removed) > 0 {
		fmt.Printf("warn:  docs differ from fallback (%s): added %v, removed %v — update fallbackFields in %s\n",
			fallbackDate, added, removed, "main.go")
	}
	if capN != fallbackListingCap {
		fmt.Printf("warn:  docs listing cap is %d, fallback says %d — update fallbackListingCap\n", capN, fallbackListingCap)
	}
	return sp
}

var (
	headingRe = regexp.MustCompile(`(?im)^#{1,6}\s+Frontmatter reference\s*$`)
	rowRe     = regexp.MustCompile("(?m)^\\|\\s*`([^`]+)`\\s*\\|")
	capRe     = regexp.MustCompile(`truncated at ([\d,]+) characters`)
)

// fetchDocs returns the field names listed in the Frontmatter reference table
// and the documented listing cap (0 if the sentence was not found).
func fetchDocs() ([]string, int, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(docsURL)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, 0, fmt.Errorf("HTTP %d", resp.StatusCode)
	}
	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, 0, err
	}
	body := string(raw)

	loc := headingRe.FindStringIndex(body)
	if loc == nil {
		return nil, 0, fmt.Errorf("no 'Frontmatter reference' heading in page")
	}
	section := body[loc[1]:]
	// The table ends at the next heading of any level.
	if next := regexp.MustCompile(`(?m)^#{1,6}\s`).FindStringIndex(section); next != nil {
		section = section[:next[0]]
	}
	var fields []string
	for _, m := range rowRe.FindAllStringSubmatch(section, -1) {
		fields = append(fields, m[1])
	}
	if len(fields) == 0 {
		return nil, 0, fmt.Errorf("heading found but no table rows under it")
	}

	capN := 0
	if m := capRe.FindStringSubmatch(body); m != nil {
		capN, _ = strconv.Atoi(strings.ReplaceAll(m[1], ",", ""))
	}
	return fields, capN, nil
}

// slashRe matches a command name in the first cell of a docs table row,
// e.g. "| `/verify` |" — the form both the built-in command and the bundled
// skill tables use.
var slashRe = regexp.MustCompile("(?m)^\\|\\s*`/([a-z0-9-]+)`")

// fetchBundled returns every command or bundled skill name the docs list,
// across all commandsURLs. One unreachable page fails the whole fetch so
// that a partial list never silently hides a collision.
func fetchBundled() ([]string, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	seen := map[string]bool{}
	var names []string
	for _, url := range commandsURLs {
		resp, err := client.Get(url)
		if err != nil {
			return nil, err
		}
		raw, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			return nil, err
		}
		if resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("%s: HTTP %d", url, resp.StatusCode)
		}
		for _, m := range slashRe.FindAllStringSubmatch(string(raw), -1) {
			if !seen[m[1]] {
				seen[m[1]] = true
				names = append(names, m[1])
			}
		}
	}
	if len(names) == 0 {
		return nil, fmt.Errorf("no `/name` table rows found")
	}
	sort.Strings(names)
	return names, nil
}

// frontmatter is a flat view of the YAML block: top-level key → raw value
// text (continuation lines joined). Nested maps such as `metadata:` keep
// their children inside the value; the validator never needs to look inside.
type frontmatter struct {
	order  []string
	values map[string]string
}

var keyRe = regexp.MustCompile(`^([A-Za-z][A-Za-z0-9_.-]*):\s*(.*)$`)

func parseFrontmatter(content string) (*frontmatter, string, error) {
	lines := strings.Split(content, "\n")
	if len(lines) == 0 || strings.TrimSpace(lines[0]) != "---" {
		return nil, "", fmt.Errorf("file does not start with a `---` frontmatter line")
	}
	end := -1
	for i := 1; i < len(lines); i++ {
		if strings.TrimSpace(lines[i]) == "---" {
			end = i
			break
		}
	}
	if end < 0 {
		return nil, "", fmt.Errorf("frontmatter is not closed by a second `---`")
	}
	fm := &frontmatter{values: map[string]string{}}
	current := ""
	for _, line := range lines[1:end] {
		if m := keyRe.FindStringSubmatch(line); m != nil {
			current = m[1]
			if _, dup := fm.values[current]; dup {
				return nil, "", fmt.Errorf("duplicate frontmatter key %q", current)
			}
			fm.order = append(fm.order, current)
			fm.values[current] = m[2]
			continue
		}
		if current == "" {
			if strings.TrimSpace(line) == "" {
				continue
			}
			return nil, "", fmt.Errorf("frontmatter line outside any key: %q", line)
		}
		fm.values[current] += "\n" + line
	}
	return fm, strings.Join(lines[end+1:], "\n"), nil
}

// scalar returns a single-line string value with surrounding quotes removed.
func (fm *frontmatter) scalar(key string) string {
	v := strings.TrimSpace(fm.values[key])
	if len(v) >= 2 && (v[0] == '"' && v[len(v)-1] == '"' || v[0] == '\'' && v[len(v)-1] == '\'') {
		v = v[1 : len(v)-1]
	}
	return v
}

// skillRefRe matches the way this repo's skills compose: "load the `x` skill",
// "via the `x` skill", "the `x` skill's". Plugin skills carry a colon.
var skillRefRe = regexp.MustCompile("`([a-z0-9][a-z0-9:-]*)` skill")

func validateSkill(dir string, sp spec) (problems, warnings []string) {
	path := filepath.Join(dir, "SKILL.md")
	raw, err := os.ReadFile(path)
	if err != nil {
		return []string{err.Error()}, nil
	}
	fm, body, err := parseFrontmatter(string(raw))
	if err != nil {
		return []string{err.Error()}, nil
	}

	for _, k := range fm.order {
		if !sp.fields[k] {
			problems = append(problems, fmt.Sprintf("unknown frontmatter field %q (allowed per %s: %s)", k, sp.source, joinSorted(sp.fields)))
		}
	}

	base := filepath.Base(mustAbs(dir))
	name := fm.scalar("name")
	switch {
	case name == "":
		problems = append(problems, "missing `name` (house rule: every skill names itself after its directory)")
	case name != base:
		problems = append(problems, fmt.Sprintf("`name` is %q but the directory is %q; /%s would not match the path", name, base, name))
	}
	if sp.bundled[base] {
		warnings = append(warnings, fmt.Sprintf("/%s is also a bundled skill or built-in command; this skill overrides it by name (its aliases still run the bundled one)", base))
	}
	desc := fm.scalar("description")
	if desc == "" {
		problems = append(problems, "missing `description`; without it Claude never triggers the skill on its own")
	}
	listing := len([]rune(desc)) + len([]rune(fm.scalar("when_to_use")))
	if listing > sp.listingCap {
		problems = append(problems, fmt.Sprintf("description + when_to_use is %d characters; the listing truncates at %d", listing, sp.listingCap))
	}
	if c := fm.scalar("compatibility"); len([]rune(c)) > compatibilityCap {
		problems = append(problems, fmt.Sprintf("compatibility is %d characters; the spec allows %d", len([]rune(c)), compatibilityCap))
	}
	if fm.scalar("disable-model-invocation") == "true" && fm.scalar("user-invocable") == "false" {
		problems = append(problems, "disable-model-invocation: true and user-invocable: false together leave nobody able to invoke the skill")
	}
	if fm.scalar("background") != "" && fm.scalar("context") != "fork" {
		warnings = append(warnings, "`background` only applies with `context: fork`")
	}
	if fm.scalar("agent") != "" && fm.scalar("context") != "fork" {
		warnings = append(warnings, "`agent` only applies with `context: fork`")
	}

	parent := filepath.Dir(mustAbs(dir))
	seen := map[string]bool{}
	for _, m := range skillRefRe.FindAllStringSubmatch(body, -1) {
		ref := m[1]
		if seen[ref] || ref == name || strings.Contains(ref, ":") {
			continue
		}
		seen[ref] = true
		if _, err := os.Stat(filepath.Join(parent, ref, "SKILL.md")); err != nil {
			problems = append(problems, fmt.Sprintf("body refers to the `%s` skill but %s has no such skill", ref, parent))
		}
	}

	if n := strings.Count(body, "\n"); n > bodyLineWarn {
		warnings = append(warnings, fmt.Sprintf("body is %d lines; past %d skill-creator suggests moving detail into references/", n, bodyLineWarn))
	}
	for _, junk := range []string{"README.md", "CHANGELOG.md", "INSTALLATION_GUIDE.md"} {
		if _, err := os.Stat(filepath.Join(dir, junk)); err == nil {
			warnings = append(warnings, junk+" inside a skill directory is for humans; skills are read by the model")
		}
	}
	return problems, warnings
}

func mustAbs(p string) string {
	a, err := filepath.Abs(p)
	if err != nil {
		return p
	}
	return a
}

func toSet(xs []string) map[string]bool {
	s := make(map[string]bool, len(xs))
	for _, x := range xs {
		s[x] = true
	}
	return s
}

func diffSets(a, b map[string]bool) (onlyA, onlyB []string) {
	for k := range a {
		if !b[k] {
			onlyA = append(onlyA, k)
		}
	}
	for k := range b {
		if !a[k] {
			onlyB = append(onlyB, k)
		}
	}
	sort.Strings(onlyA)
	sort.Strings(onlyB)
	return
}

func joinSorted(s map[string]bool) string {
	keys := make([]string, 0, len(s))
	for k := range s {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return strings.Join(keys, ", ")
}
