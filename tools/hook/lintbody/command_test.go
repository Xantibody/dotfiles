package lintbody

import (
	"strings"
	"testing"

	"github.com/Xantibody/dotfiles/tools/hook"
	"github.com/Xantibody/dotfiles/tools/internal/cli"
)

// execute runs `rat hook lint-body` with stdin and returns the code rat
// exits with and the two streams.
func execute(t *testing.T, stdin string) (code int, stdout, stderr string) {
	t.Helper()
	var out, errs strings.Builder
	code = cli.Main(cli.Root(hook.Command(Command())), []string{"hook", "lint-body"}, strings.NewReader(stdin), &out, &errs)
	return code, out.String(), errs.String()
}

// A body with findings makes rat exit 2, with nothing on stdout and no
// usage on stderr: the block is the hook's answer, not a usage mistake.
func TestCommandExitsTwoOnFindings(t *testing.T) {
	cwd := setup(t)
	code, out, errs := execute(t, `{"cwd":"`+cwd+`","tool_input":{"command":"gh pr create --body-file ng.md"}}`)
	if code != 2 || out != "" || strings.Contains(errs, "Usage:") {
		t.Errorf("exit %d, stdout %q, stderr %q; want 2, nothing on stdout and no usage", code, out, errs)
	}
}

func TestCommandPassesSilently(t *testing.T) {
	cwd := setup(t)
	if code, out, errs := execute(t, `{"cwd":"`+cwd+`","tool_input":{"command":"gh pr create --body-file ok.md"}}`); code != 0 || out != "" || errs != "" {
		t.Errorf("exit %d, stdout %q, stderr %q; want 0 and nothing", code, out, errs)
	}
}
