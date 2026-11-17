package deny

import (
	"bytes"
	"encoding/json"
	"strings"
	"testing"
)

func TestCheckDenies(t *testing.T) {
	for _, cmd := range []string{
		"git push",
		"git push origin main",
		"git -C /nonexistent push",
		"git -C dir -c user.name=x push --force",
		"git --git-dir=.git --work-tree . push",
		"git --no-pager push",
		"/usr/bin/git push",
		"rtk git push",
		"rtk proxy git push",
		"env GIT_TRACE=1 git push",
		"FOO=1 git push",
		"command git push",
		"sudo -u me git push",
		"timeout 30 git push",
		"git commit -m x && git push",
		"true; git push",
		"echo $(git push)",
		"(cd sub && git push)",
		"bash -c 'git push'",
		"sh -ec \"git -C x push\"",
		"eval git push",
		"bash --norc -c 'git push'",
		"bash -o pipefail -c 'git push'",
		"bash -O extglob -c 'rm -rf x'",
		"bash -eo pipefail -c 'git push'",
		"bash -c -o pipefail 'git push'",
		"bash --rcfile x -c 'git push'",
		"env -S 'git push'",
		"env -S'git push'",
		"env --split-string='git push'",
		"env -S git push",
		"verify-gate run -- git push",
		"verify-gate run rm -rf dir",
		"rm -rf dir",
		"rm -fr dir",
		"rm -Rf dir",
		"rm -r -f dir",
		"rm -f -r dir",
		"rm -rfv dir",
		"rm --recursive --force dir",
		"rm -r --force dir",
		"/bin/rm -fr dir",
		"rtk rm -fr dir",
		"find . -name x | xargs rm -rf",
		"xargs -I {} rm -fr {}",
		"nice -n 10 rm -rf dir",
		"git -C /nonexistent push; rm -fr x",
		"git -C x 'push'",
		"rm \"-fr\" dir",
		"env FOO=$x git push",
		"\"$HOME/bin/git\" push",
	} {
		if checkCommand(cmd) == "" {
			t.Errorf("checkCommand(%q) allowed, want denied", cmd)
		}
	}
}

func TestCheckAllows(t *testing.T) {
	for _, cmd := range []string{
		"",
		"git status",
		"git -C dir log --oneline",
		"git commit -m 'do not git push yet'",
		"git log --grep push",
		"git -c push.default=simple status",
		"echo git push",
		"echo 'rm -rf /'",
		"rm file",
		"rm -f file",
		"rm -r dir",
		"rm -- -rf",
		"grep -r -f patterns .",
		"gh pr view",
		"git $sub",
		"rtk git status",
		"bash -o pipefail script.sh",
		"bash --norc -c 'git status'",
		"env -S 'git status'",
		"env -u PATH git status",
		"verify-gate run -- nix fmt",
		"verify-gate commit-msg .git/COMMIT_EDITMSG",
	} {
		if reason := checkCommand(cmd); reason != "" {
			t.Errorf("checkCommand(%q) denied with %q, want allowed", cmd, reason)
		}
	}
}

// A command the parser rejects still gets checked, split on the shell's
// separators, so broken quoting is not a way around the hook.
func TestCheckFallsBackOnParseError(t *testing.T) {
	for _, cmd := range []string{
		"git -C x push 'unterminated",
		"echo ok; rm -fr dir 'unterminated",
		"FOO=1 git push 'unterminated",
	} {
		if checkCommand(cmd) == "" {
			t.Errorf("checkCommand(%q) allowed, want denied", cmd)
		}
	}
}

func TestRunWritesDenyDecision(t *testing.T) {
	in := strings.NewReader(`{"tool_name":"Bash","tool_input":{"command":"git -C /nonexistent push"}}`)
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
	if h.HookEventName != "PreToolUse" || h.PermissionDecision != "deny" || h.PermissionDecisionReason == "" {
		t.Errorf("got %+v, want a PreToolUse deny with a reason", h)
	}
}

func TestRunStaysSilentWhenAllowed(t *testing.T) {
	in := strings.NewReader(`{"tool_name":"Bash","tool_input":{"command":"git status"}}`)
	var out bytes.Buffer
	if err := run(in, &out); err != nil {
		t.Fatal(err)
	}
	if out.Len() != 0 {
		t.Errorf("output %q, want none", out.String())
	}
}

func TestRunRejectsBadInput(t *testing.T) {
	if err := run(strings.NewReader("not json"), &bytes.Buffer{}); err == nil {
		t.Error("run accepted input that is not JSON")
	}
}
