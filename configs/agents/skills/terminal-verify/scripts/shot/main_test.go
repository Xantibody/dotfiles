package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

// valid returns a shot that passes every check, for a test to change one field.
func valid() shot {
	return shot{
		out:         "/tmp/pr body/after.png",
		setup:       []string{`fish -C 'source /tmp/pr body/config.fish'`},
		ready:       `❯ `,
		command:     `echo "done"`,
		wait:        `(?m)^done *$`,
		width:       1200,
		height:      600,
		fontSize:    18,
		waitTimeout: 15 * time.Second,
	}
}

func lines(t *testing.T, s shot) []string {
	t.Helper()
	tape, err := s.tape()
	if err != nil {
		t.Fatal(err)
	}
	return strings.Split(strings.TrimSuffix(tape, "\n"), "\n")
}

func index(ls []string, want string) int {
	for i, l := range ls {
		if l == want {
			return i
		}
	}
	return -1
}

func TestTapeAvoidsSilentFailures(t *testing.T) {
	for _, tc := range []struct {
		name  string
		check func(t *testing.T, ls []string)
	}{
		{"paths are quoted", func(t *testing.T, ls []string) {
			for _, want := range []string{`Output "/tmp/pr body/after.gif"`, `Screenshot "/tmp/pr body/after.png"`} {
				if index(ls, want) < 0 {
					t.Errorf("no line %q in\n%s", want, strings.Join(ls, "\n"))
				}
			}
		}},
		{"clear before Show", func(t *testing.T, ls []string) {
			hide, clear, show := index(ls, "Hide"), index(ls, `Type "clear"`), index(ls, "Show")
			if !(hide >= 0 && hide < clear && clear < show && ls[clear+1] == "Enter") {
				t.Errorf("want Hide < clear+Enter < Show, got Hide %d, clear %d, Show %d", hide, clear, show)
			}
		}},
		{"never ends on Screenshot", func(t *testing.T, ls []string) {
			last := ls[len(ls)-1]
			if strings.HasPrefix(last, "Screenshot") || !strings.HasPrefix(ls[len(ls)-2], "Screenshot") || last != "Sleep 500ms" {
				t.Errorf("want Screenshot then Sleep 500ms at the end, got %q, %q", ls[len(ls)-2], last)
			}
		}},
		{"Output is a gif", func(t *testing.T, ls []string) {
			if !strings.HasPrefix(ls[0], "Output ") || !strings.HasSuffix(ls[0], `.gif"`) {
				t.Errorf("want the first line to be a .gif Output, got %q", ls[0])
			}
		}},
		{"waits for the screen, not for a fixed time", func(t *testing.T, ls []string) {
			ready, clear := index(ls, "Wait+Screen /❯ /"), index(ls, `Type "clear"`)
			done, shot := index(ls, "Wait+Screen /(?m)^done *$/"), index(ls, `Screenshot "/tmp/pr body/after.png"`)
			if !(ready >= 0 && ready < clear) || !(done >= 0 && done == shot-1) {
				t.Errorf("want Wait+Screen before clear and right before Screenshot, got ready %d, clear %d, done %d, Screenshot %d", ready, clear, done, shot)
			}
			for _, l := range ls[:len(ls)-1] {
				if strings.HasPrefix(l, "Sleep") {
					t.Errorf("a Sleep other than the final one: %q", l)
				}
			}
			if index(ls, "Set WaitTimeout 15000ms") < 0 {
				t.Errorf("no WaitTimeout in\n%s", strings.Join(ls, "\n"))
			}
		}},
		{"command quoted around its own quotes", func(t *testing.T, ls []string) {
			if index(ls, `Type 'echo "done"'`) < 0 || index(ls, `Type "fish -C 'source /tmp/pr body/config.fish'"`) < 0 {
				t.Errorf("commands not quoted with a free delimiter:\n%s", strings.Join(ls, "\n"))
			}
		}},
	} {
		t.Run(tc.name, func(t *testing.T) { tc.check(t, lines(t, valid())) })
	}
}

func TestQuote(t *testing.T) {
	for _, tc := range []struct{ in, want string }{
		{`/tmp/a b`, `"/tmp/a b"`},
		{`say "hi"`, `'say "hi"'`},
		{`say "it's"`, "`say \"it's\"`"},
	} {
		if got, err := quote(tc.in); err != nil || got != tc.want {
			t.Errorf("quote(%q) = %q, %v; want %q", tc.in, got, err, tc.want)
		}
	}
}

func TestTapeWithoutSetupHasNoHiddenPart(t *testing.T) {
	s := valid()
	s.setup, s.ready = nil, ""
	ls := lines(t, s)
	for _, l := range []string{"Hide", "Show", `Type "clear"`} {
		if index(ls, l) >= 0 {
			t.Errorf("line %q without -setup", l)
		}
	}
}

func TestTapeRejects(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*shot)
		want   string
	}{
		{"relative out", func(s *shot) { s.out = "after.png" }, "absolute path ending in .png"},
		{"out not a png", func(s *shot) { s.out = "/tmp/after.gif" }, "absolute path ending in .png"},
		{"no command", func(s *shot) { s.command = "" }, "-command is required"},
		{"no wait", func(s *shot) { s.wait = "" }, "-wait is required"},
		{"setup without ready", func(s *shot) { s.ready = "" }, "-ready is required"},
		{"ready without setup", func(s *shot) { s.setup = nil }, "-ready without -setup"},
		{"slash in regex", func(s *shot) { s.wait = "/tmp" }, `\x2f`},
		{"bad regex", func(s *shot) { s.ready = "(" }, "-ready: regex"},
		{"all three quotes", func(s *shot) { s.command = "echo \"a\" 'b' `c`" }, "-command:"},
		{"newline in command", func(s *shot) { s.command = "a\nb" }, "one line"},
		{"zero width", func(s *shot) { s.width = 0 }, "must be positive"},
		{"zero wait timeout", func(s *shot) { s.waitTimeout = 0 }, "-wait-timeout"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s := valid()
			tc.change(&s)
			if _, err := s.tape(); err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("want an error containing %q, got %v", tc.want, err)
			}
		})
	}
}

func TestCheckVersion(t *testing.T) {
	for _, tc := range []struct {
		output string
		ok     bool
	}{
		{"vhs version 0.12.1\n", true},
		{"vhs version v0.13.0 (abc1234)\n", true},
		{"vhs version 1.0.0\n", true},
		{"vhs version 0.12.0\n", false},
		{"vhs version 0.11.9\n", false},
		{"vhs version unknown (built from source)\n", false},
	} {
		t.Run(tc.output, func(t *testing.T) {
			if err := checkVersion(tc.output); (err == nil) != tc.ok {
				t.Fatalf("ok = %v, want %v: %v", err == nil, tc.ok, err)
			}
		})
	}
}

// fakeVHS writes an executable that answers --version with version and, given
// a tape, writes png (when non-empty) to the path on the tape's Screenshot line.
func fakeVHS(t *testing.T, version, png string) string {
	t.Helper()
	script := "#!/bin/sh\n" +
		"if [ \"$1\" = --version ]; then echo 'vhs version " + version + "'; exit 0; fi\n"
	if png != "" {
		script += "out=$(sed -n 's/^Screenshot \"\\(.*\\)\"$/\\1/p' \"$1\")\n" +
			"printf '" + png + "' > \"$out\"\n"
	}
	p := filepath.Join(t.TempDir(), "vhs")
	if err := os.WriteFile(p, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	return p
}

func TestRun(t *testing.T) {
	const realPNG = `\211PNG\r\n\032\n rest`
	for _, tc := range []struct {
		name, version, png string
		code               int
		stderr             string
	}{
		{"writes the png", "0.12.1", realPNG, 0, ""},
		{"exits 0 without a png", "0.12.1", "", 1, "wrote no screenshot"},
		{"writes something else", "0.12.1", "not a png", 1, "is not a PNG"},
		{"too old", "0.12.0", realPNG, 1, "older than 0.12.1"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			out := filepath.Join(t.TempDir(), "after.png")
			// A PNG from an earlier run must not pass for this one.
			if err := os.WriteFile(out, pngMagic, 0o644); err != nil {
				t.Fatal(err)
			}
			var stdout, stderr strings.Builder
			code := run([]string{"-vhs", fakeVHS(t, tc.version, tc.png), "-out", out, "-command", "true", "-wait", "x"}, &stdout, &stderr)
			if code != tc.code || !strings.Contains(stderr.String(), tc.stderr) {
				t.Fatalf("exit %d, stderr %q; want %d and %q", code, stderr.String(), tc.code, tc.stderr)
			}
			if code == 0 {
				if stdout.String() != out+"\n" {
					t.Errorf("stdout %q, want the PNG path", stdout.String())
				}
				if _, err := os.Stat(strings.TrimSuffix(out, ".png") + ".tape"); err != nil {
					t.Errorf("tape not kept beside the PNG: %v", err)
				}
			}
		})
	}
}

func TestRunTapeOnly(t *testing.T) {
	var stdout, stderr strings.Builder
	code := run([]string{"-tape-only", "-vhs", "/nonexistent", "-out", "/tmp/x/after.png", "-command", "ls", "-wait", "x"}, &stdout, &stderr)
	if code != 0 || !strings.HasPrefix(stdout.String(), `Output "/tmp/x/after.gif"`) {
		t.Fatalf("exit %d, stdout %q, stderr %q", code, stdout.String(), stderr.String())
	}
}

func TestRunUsageErrors(t *testing.T) {
	for _, args := range [][]string{
		{"-out", "/tmp/a.png", "-wait", "x"},
		{"-out", "/tmp/a.png", "-command", "ls", "-wait", "x", "extra"},
	} {
		var stdout, stderr strings.Builder
		if code := run(args, &stdout, &stderr); code != 2 || stdout.Len() > 0 {
			t.Errorf("%v: exit %d, stdout %q; want 2 and nothing on stdout", args, code, stdout.String())
		}
	}
}
