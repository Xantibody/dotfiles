package hotspots

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"
)

// folded writes text to a .folded file and returns its path.
func folded(t *testing.T, text string) string {
	t.Helper()
	p := filepath.Join(t.TempDir(), "run.folded")
	if err := os.WriteFile(p, []byte(text), 0o644); err != nil {
		t.Fatal(err)
	}
	return p
}

// run executes `rat hotspots` with args and returns the code rat exits with
// and the two streams.
func run(args ...string) (code int, stdout, stderr string) {
	var o, e strings.Builder
	cmd := Command()
	cmd.SetArgs(args)
	cmd.SetOut(&o)
	cmd.SetErr(&e)
	if err := cmd.Execute(); err != nil {
		var coded interface{ ExitCode() int }
		if !errors.As(err, &coded) {
			return -1, o.String(), e.String() + err.Error()
		}
		code = coded.ExitCode()
	}
	return code, o.String(), e.String()
}

func TestRanks(t *testing.T) {
	for _, tc := range []struct {
		name, folded string
		args         []string
		want         string
	}{
		{
			name:   "self is the leaf, total the frame and its children",
			folded: "main;a;b 3\nmain;a 1\nmain;c 6\n",
			want: "samples: 10\n\n" +
				"self (where the CPU is):\n" +
				"  60.0%  c\n" +
				"  30.0%  b\n" +
				"  10.0%  a\n\n" +
				"total (frame plus its children):\n" +
				" 100.0%  main\n" +
				"  60.0%  c\n" +
				"  40.0%  a\n" +
				"  30.0%  b\n",
		},
		{
			name:   "recursion counts a frame once in total",
			folded: "main;f;f;f 2\n",
			want: "samples: 2\n\n" +
				"self (where the CPU is):\n" +
				" 100.0%  f\n\n" +
				"total (frame plus its children):\n" +
				" 100.0%  f\n" +
				" 100.0%  main\n",
		},
		{
			name:   "-n caps each table and ties go by name",
			folded: "main;y 1\nmain;x 1\n",
			args:   []string{"-n", "1"},
			want: "samples: 2\n\n" +
				"self (where the CPU is):\n" +
				"  50.0%  x\n\n" +
				"total (frame plus its children):\n" +
				" 100.0%  main\n",
		},
		{
			name:   "lines without a count are skipped",
			folded: "\nnot a stack\nmain;a 1.5\nmain;b x\n  main;a 0.5  \n",
			want: "samples: 2\n\n" +
				"self (where the CPU is):\n" +
				" 100.0%  a\n\n" +
				"total (frame plus its children):\n" +
				" 100.0%  a\n" +
				" 100.0%  main\n",
		},
	} {
		t.Run(tc.name, func(t *testing.T) {
			code, out, errs := run(append(tc.args, folded(t, tc.folded))...)
			if code != 0 {
				t.Fatalf("exit %d, stderr %q", code, errs)
			}
			if diff := cmp.Diff(tc.want, out); diff != "" {
				t.Errorf("stdout (-want +got):\n%s", diff)
			}
		})
	}
}

func TestDefaultsToFifteenFrames(t *testing.T) {
	var b strings.Builder
	for i := range 20 {
		b.WriteString("main;f" + string(rune('a'+i)) + " 1\n")
	}
	_, out, _ := run(folded(t, b.String()))
	// samples line, blank, two headings, a blank between the tables
	if got := strings.Count(out, "\n"); got != 2*15+5 {
		t.Errorf("%d lines, want 15 frames per table:\n%s", got, out)
	}
}

func TestFails(t *testing.T) {
	for _, tc := range []struct {
		name   string
		args   func(t *testing.T) []string
		code   int
		stderr string
	}{
		{"no file", func(*testing.T) []string { return nil }, 2, "usage: rat hotspots"},
		{"two files", func(*testing.T) []string { return []string{"a", "b"} }, 2, "usage: rat hotspots"},
		{"bad -n", func(*testing.T) []string { return []string{"-n", "many", "a"} }, 2, "usage: rat hotspots"},
		{"missing file", func(t *testing.T) []string { return []string{filepath.Join(t.TempDir(), "none.folded")} }, 1, "no such file"},
		{"no stacks", func(t *testing.T) []string { return []string{folded(t, "nothing here\n")} }, 1, "no folded stacks found"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			code, out, errs := run(tc.args(t)...)
			if code != tc.code || out != "" || !strings.Contains(errs, tc.stderr) {
				t.Errorf("exit %d, stdout %q, stderr %q; want %d, nothing and %q", code, out, errs, tc.code, tc.stderr)
			}
		})
	}
}
