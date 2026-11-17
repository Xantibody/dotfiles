package ghguard

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func TestCheckAsks(t *testing.T) {
	for _, cmd := range []string{
		"gh api -X PUT repos/o/r/contents/README.md -f message=x -f content=eA==",
		"gh api --method PUT repos/o/r/contents/a/b",
		"gh api --method=DELETE repos/o/r/rulesets/12823463",
		"gh api -XPATCH /repos/o/r/rulesets/1",
		"gh api -X put repos/{owner}/{repo}/branches/main/protection --input p.json",
		"gh api repos/o/r/rulesets --input ruleset.json",
		"gh api repos/o/r/branches/main/protection/required_status_checks -F strict=true",
		"gh api orgs/o/rulesets -f name=x",
		"gh api repos/o/r/merges -f base=main -f head=feat",
		"gh api -X PATCH repos/o/r/git/refs/heads/main -f sha=abc",
		"gh api -X PUT repos/o/r/pulls/12/merge",
		"gh api -H 'Accept: application/vnd.github+json' -X DELETE repos/o/r/branches/main/protection",
		"gh api graphql -f query='mutation { createCommitOnBranch(input: {}) { commit { oid } } }'",
		"rtk gh api -X PUT repos/o/r/contents/x",
		"rtk proxy gh api -X PUT repos/o/r/contents/x",
		"rat verify-gate run -- gh api -X PUT repos/o/r/contents/x",
		"GH_TOKEN=t gh api -X PUT repos/o/r/contents/x",
		"env GH_HOST=github.com gh api -X PUT repos/o/r/contents/x",
		"/opt/homebrew/bin/gh api -X PUT repos/o/r/contents/x",
		"cd repo && gh api -X PUT repos/o/r/contents/x",
		"bash -c 'gh api -X PUT repos/o/r/contents/x'",
		"echo $(gh api -X DELETE repos/o/r/rulesets/1)",
		"gh pr merge --admin",
		"gh pr merge 12 --squash --admin",
		"gh pr merge --auto --squash",
		"rtk gh pr merge --auto",
		"git status; gh pr merge 3 --admin",
		// beyond the table gh-guard.sh had
		"gh api -X PUT \"repos/$o/$r/contents/x\"",
		"gh api -X PUT repos/o/r/contents/x 'unterminated",
		"gh pr merge --admin=true",
	} {
		if checkCommand(cmd) == "" {
			t.Errorf("checkCommand(%q) passed, want ask", cmd)
		}
	}
}

func TestCheckPasses(t *testing.T) {
	for _, cmd := range []string{
		"",
		"gh api repos/o/r/rulesets",
		"gh api repos/o/r/contents/README.md --jq .content",
		"gh api -X GET repos/o/r/branches/main/protection",
		"gh api --method GET repos/o/r/rulesets -f includes_parents=true",
		"gh api repos/o/r/pulls/12/merge",
		"gh api -X POST repos/o/r/issues -f title=x",
		"gh api -X PATCH repos/o/r -f description=x",
		"gh api graphql -f query='query { viewer { login } }'",
		"gh api graphql -f query='mutation { addComment(input: {}) { clientMutationId } }'",
		"gh pr merge 12 --squash",
		"gh pr view 12 --json mergeStateStatus",
		"gh ruleset list",
		"rtk gh api repos/o/r/contents/x",
		"git log --grep contents",
		"echo gh api -X PUT repos/o/r/contents/x",
		// beyond the table gh-guard.sh had
		"gh api -X HEAD repos/o/r/contents/x",
	} {
		if reason := checkCommand(cmd); reason != "" {
			t.Errorf("checkCommand(%q) asked with %q, want pass", cmd, reason)
		}
	}
}

// The reason names the method and endpoint, or the mutation, that matched,
// so the user sees what they are confirming.
func TestCheckReason(t *testing.T) {
	for cmd, want := range map[string]string{
		"gh api -X put repos/o/r/rulesets/1":                                 "gh api PUT repos/o/r/rulesets/1",
		"gh api -H 'Accept: x' repos/o/r/merges -f base=main":                "gh api POST repos/o/r/merges",
		"gh api graphql -f query='mutation { updateRefs(input: {}) { x } }'": "gh api graphql updateRefs",
		"gh pr merge 3 --squash --auto":                                      "gh pr merge --auto",
	} {
		if got := checkCommand(cmd); got != want {
			t.Errorf("checkCommand(%q) = %q, want %q", cmd, got, want)
		}
	}
}

func TestRunWritesAskDecision(t *testing.T) {
	in := strings.NewReader(`{"tool_name":"Bash","tool_input":{"command":"gh pr merge --admin"}}`)
	var out bytes.Buffer
	if err := run(in, &out); err != nil {
		t.Fatal(err)
	}
	var got struct {
		HookSpecificOutput struct {
			HookEventName            string `json:"hookEventName"`
			PermissionDecision       string `json:"permissionDecision"`
			PermissionDecisionReason string `json:"permissionDecisionReason"`
		} `json:"hookSpecificOutput"`
	}
	if err := json.Unmarshal(out.Bytes(), &got); err != nil {
		t.Fatalf("output %q is not JSON: %v", out.String(), err)
	}
	h := got.HookSpecificOutput
	if h.HookEventName != "PreToolUse" || h.PermissionDecision != "ask" || !strings.Contains(h.PermissionDecisionReason, "gh pr merge --admin") {
		t.Errorf("got %+v, want a PreToolUse ask naming gh pr merge --admin", h)
	}
}

func TestRunStaysSilentWhenPassing(t *testing.T) {
	for _, stdin := range []string{
		`{"tool_name":"Bash","tool_input":{"command":"gh pr view"}}`,
		`{"tool_name":"Bash","tool_input":{}}`,
	} {
		var out bytes.Buffer
		if err := run(strings.NewReader(stdin), &out); err != nil {
			t.Fatal(err)
		}
		if out.Len() != 0 {
			t.Errorf("run(%s) wrote %q, want none", stdin, out.String())
		}
	}
}

func TestRunRejectsBadInput(t *testing.T) {
	if err := run(strings.NewReader("not json"), &bytes.Buffer{}); err == nil {
		t.Error("run accepted input that is not JSON")
	}
}
