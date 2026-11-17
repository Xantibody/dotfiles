// Package ghguard is `rat hook gh-guard`, a PreToolUse hook for Claude Code's
// Bash tool: it returns permissionDecision "ask" for a gh api call that
// writes rulesets, branch protection, contents, merges or refs, and for
// gh pr merge --admin or --auto, so the user confirms once. Anything else
// passes with no output.
//
// The agent runs with the user's admin token, so gh api -X PUT
// .../contents/<path> writes to main without the git push that rat hook deny
// refuses, and a ruleset's bypass applies to it. A write the user started
// (the branch-protection skill, say) goes through after one confirmation.
//
// AIDEV-NOTE: a mid-pattern ask rule such as `Bash(gh api * rulesets*)` was rejected: whether it matches depends on argument order and where -X sits
// AIDEV-NOTE: leans to asking too often over missing one (a dynamic method counts as a write); rat hook deny stays deny-only and never asks
package ghguard

import (
	"io"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/Xantibody/dotfiles/tools/internal/pretooluse"
	"github.com/Xantibody/dotfiles/tools/internal/shell"
)

// endpointRe matches the REST endpoints whose writes need a confirmation,
// after repos/<o>/<r>/ or orgs/<o>/.
var endpointRe = regexp.MustCompile(`(^|/)(rulesets|protection|contents|merges|git/refs|pulls/[^/]+/merge)(/|\?|$)`)

// mutationRe matches the graphql mutations that do the same.
var mutationRe = func() *regexp.Regexp {
	re := regexp.MustCompile(`createCommitOnBranch|(create|update|delete)Ref|updateRefs|BranchProtectionRule|Ruleset|mergePullRequest|enablePullRequestAutoMerge`)
	re.Longest() // updateRefs, not updateRef, as bash's =~ reported it
	return re
}()

func run(stdin io.Reader, stdout io.Writer) error {
	cmd, err := pretooluse.Command(stdin)
	if err != nil {
		return err
	}
	reason := checkCommand(cmd)
	if reason == "" {
		return nil
	}
	return pretooluse.Decide(stdout, "ask",
		"rat hook gh-guard: "+reason+" changes repository protection or writes to a branch without a push. Ask the user to confirm.")
}

// checkCommand returns the gh call in cmd that needs a confirmation, or ""
// when there is none.
func checkCommand(cmd string) string {
	for _, args := range shell.Commands(cmd) {
		if reason := checkGh(args); reason != "" {
			return reason
		}
	}
	return ""
}

func checkGh(args []string) string {
	if filepath.Base(args[0]) != "gh" || len(args) < 2 {
		return ""
	}
	switch args[1] {
	case "api":
		if len(args) > 2 && args[2] == "graphql" {
			query := strings.Join(args, " ")
			if m := mutationRe.FindString(query); m != "" && strings.Contains(query, "mutation") {
				return "gh api graphql " + m
			}
			return ""
		}
		return checkAPI(args[2:])
	case "pr":
		if len(args) < 3 || args[2] != "merge" {
			return ""
		}
		for _, a := range args[3:] {
			if name, _, _ := strings.Cut(a, "="); name == "--admin" || name == "--auto" {
				return "gh pr merge " + name
			}
		}
	}
	return ""
}

// checkAPI reads the method from the arguments of gh api and returns the
// call when it writes to a guarded endpoint. With no -X or --method, a body
// (-f, -F, --input) makes it a POST, as gh does.
func checkAPI(args []string) string {
	method, body, endpoint := "", false, ""
	for i := 0; i < len(args); i++ {
		a := args[i]
		switch {
		case a == "-X" || a == "--method":
			i++
			if i < len(args) {
				method = args[i]
			}
		case strings.HasPrefix(a, "-X"):
			method = a[2:]
		case strings.HasPrefix(a, "--method="):
			method = strings.TrimPrefix(a, "--method=")
		case a == "-f" || a == "-F" || a == "--field" || a == "--raw-field" || a == "--input":
			body = true
			i++
		case strings.HasPrefix(a, "-f") || strings.HasPrefix(a, "-F") ||
			strings.HasPrefix(a, "--field=") || strings.HasPrefix(a, "--raw-field=") || strings.HasPrefix(a, "--input="):
			body = true
		case a == "-H" || a == "--header" || a == "-q" || a == "--jq" || a == "-t" || a == "--template" ||
			a == "--hostname" || a == "--cache" || a == "-p" || a == "--preview":
			i++
		case strings.HasPrefix(a, "-"):
		case endpoint == "" && endpointRe.MatchString(a):
			endpoint = a
		}
	}
	if method == "" {
		method = "GET"
		if body {
			method = "POST"
		}
	}
	method = strings.ToUpper(method)
	if method == "GET" || method == "HEAD" || endpoint == "" {
		return ""
	}
	return "gh api " + method + " " + endpoint
}
