// Package shot captures one terminal screen with vhs from flags instead of a
// hand-written tape. Each trap that makes vhs fail without an error is a rule
// in tape() below, and each rule has a test:
//
//   - a path in the tape is quoted, since an unquoted absolute path is a
//     parse error;
//   - the hidden setup ends with `clear`, since Hide stops recording, not
//     drawing, and the setup would otherwise be in the screenshot;
//   - the tape never ends on Screenshot, since the PNG is then sometimes not
//     written (https://github.com/charmbracelet/vhs/issues/540);
//   - Output is a .gif, since an Output ending in .png is a frame directory
//     that the Screenshot of the same name collides with.
//
// The tape waits for what the screen shows (Wait+Screen) instead of a fixed
// Sleep, so a slow start fails with a timeout rather than capturing the
// screen before the config loaded. After running vhs it checks the version
// (0.12.0 exits 0 and writes nothing) and that a PNG was written.
//
//	rat shot --out /abs/dir/after.png --command <cmd> --wait <regex> \
//	  [--setup <cmd>]... [--ready <regex>] [--width 1200] [--height 600] \
//	  [--font-size 18] [--wait-timeout 15s] [--vhs vhs] [--tape-only]
//
// The tape is kept next to the PNG (after.tape), with the recording beside
// it (after.gif). stdout carries the PNG path, or the tape with --tape-only;
// vhs's own output goes to stderr.
package shot

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// minVersion is the oldest vhs that writes the files it reports; 0.12.0
// exits 0 without writing any (https://github.com/charmbracelet/vhs/issues/787).
var minVersion = [3]int{0, 12, 1}

// runTimeout bounds one vhs run, which starts a headless browser.
const runTimeout = 300 * time.Second

// pngMagic is the signature every PNG file starts with.
var pngMagic = []byte("\x89PNG\r\n\x1a\n")

// shot is one screenshot: the hidden setup, the visible command, and what the
// screen shows when each is done.
type shot struct {
	out         string   // absolute path of the PNG
	setup       []string // typed while hidden, each followed by Enter
	ready       string   // regex the screen matches once the setup is done
	command     string   // typed while shown, followed by Enter
	wait        string   // regex the screen matches once the command is done
	width       int
	height      int
	fontSize    int
	waitTimeout time.Duration
}

func (s shot) base() string { return strings.TrimSuffix(s.out, ".png") }

func (s shot) tapePath() string { return s.base() + ".tape" }

func (s shot) gifPath() string { return s.base() + ".gif" }

// tape returns the vhs tape for s, or an error naming the flag to fix.
func (s shot) tape() (string, error) {
	if !filepath.IsAbs(s.out) || filepath.Ext(s.out) != ".png" {
		return "", fmt.Errorf("--out %q: want an absolute path ending in .png", s.out)
	}
	if s.command == "" {
		return "", errors.New("--command is required: what the reviewer should see happen")
	}
	if s.wait == "" {
		return "", errors.New("--wait is required: a regex the screen matches once --command has drawn its result")
	}
	if len(s.setup) > 0 && s.ready == "" {
		return "", errors.New("--ready is required with --setup: a regex the screen matches once the setup is done, often the prompt")
	}
	if s.ready != "" && len(s.setup) == 0 {
		return "", errors.New("--ready without --setup waits for nothing; drop it or add the --setup it waits for")
	}
	if s.width <= 0 || s.height <= 0 || s.fontSize <= 0 {
		return "", fmt.Errorf("--width %d, --height %d, --font-size %d: each must be positive", s.width, s.height, s.fontSize)
	}
	if s.waitTimeout <= 0 {
		return "", fmt.Errorf("--wait-timeout %s: must be positive", s.waitTimeout)
	}

	var b strings.Builder
	line := func(format string, args ...any) { fmt.Fprintf(&b, format+"\n", args...) }
	quoted := func(flagName, v string) (string, error) {
		q, err := quote(v)
		if err != nil {
			return "", fmt.Errorf("%s: %w", flagName, err)
		}
		return q, nil
	}
	waitFor := func(flagName, re string) error {
		w, err := waitScreen(re)
		if err != nil {
			return fmt.Errorf("%s: %w", flagName, err)
		}
		line("%s", w)
		return nil
	}

	gif, err := quoted("--out", s.gifPath())
	if err != nil {
		return "", err
	}
	png, err := quoted("--out", s.out)
	if err != nil {
		return "", err
	}
	line("Output %s", gif)
	line(`Set Shell "bash"`)
	line("Set Width %d", s.width)
	line("Set Height %d", s.height)
	line("Set FontSize %d", s.fontSize)
	line("Set WaitTimeout %dms", s.waitTimeout.Milliseconds())
	if len(s.setup) > 0 {
		line("Hide")
		for _, c := range s.setup {
			q, err := quoted("--setup", c)
			if err != nil {
				return "", err
			}
			line("Type %s", q)
			line("Enter")
		}
		if err := waitFor("--ready", s.ready); err != nil {
			return "", err
		}
		line(`Type "clear"`)
		line("Enter")
		line("Show")
	}
	cmd, err := quoted("--command", s.command)
	if err != nil {
		return "", err
	}
	line("Type %s", cmd)
	line("Enter")
	if err := waitFor("--wait", s.wait); err != nil {
		return "", err
	}
	line("Screenshot %s", png)
	// HACK(https://github.com/charmbracelet/vhs/issues/540): drop this Sleep once a tape ending on Screenshot always writes the PNG.
	line("Sleep 500ms")
	return b.String(), nil
}

// quote returns v as a vhs string. vhs strings have no escapes, so the
// delimiter is whichever of ", ' and ` does not occur in v.
func quote(v string) (string, error) {
	if strings.ContainsAny(v, "\r\n") {
		return "", fmt.Errorf("%q spans lines; a tape string is one line", v)
	}
	for _, d := range []string{`"`, `'`, "`"} {
		if !strings.Contains(v, d) {
			return d + v + d, nil
		}
	}
	return "", fmt.Errorf("%q contains \", ' and `; a tape string cannot hold all three", v)
}

// waitScreen returns a Wait+Screen line for re. vhs matches re with Go's
// regexp against the whole screen, each line padded with spaces to the
// terminal width, and ends the regex at the first /.
func waitScreen(re string) (string, error) {
	if strings.Contains(re, "/") {
		return "", fmt.Errorf("regex %q contains /, which ends a vhs regex; write it as \\x2f", re)
	}
	if strings.ContainsAny(re, "\r\n") {
		return "", fmt.Errorf("regex %q spans lines; use \\n", re)
	}
	if _, err := regexp.Compile(re); err != nil {
		return "", fmt.Errorf("regex %q: %w", re, err)
	}
	return "Wait+Screen /" + re + "/", nil
}

var versionRe = regexp.MustCompile(`(\d+)\.(\d+)\.(\d+)`)

// checkVersion reads `vhs --version` output and fails below minVersion.
func checkVersion(output string) error {
	m := versionRe.FindStringSubmatch(output)
	if m == nil {
		return fmt.Errorf("cannot read a version from vhs --version: %q", strings.TrimSpace(output))
	}
	var got [3]int
	for i := range got {
		got[i], _ = strconv.Atoi(m[i+1])
	}
	for i := range got {
		if got[i] != minVersion[i] {
			if got[i] > minVersion[i] {
				return nil
			}
			return fmt.Errorf("vhs %s.%s.%s is older than %d.%d.%d (0.12.0 exits 0 and writes nothing); pass --vhs a newer one, e.g. from `nix build github:NixOS/nixpkgs/nixpkgs-unstable#vhs`",
				m[1], m[2], m[3], minVersion[0], minVersion[1], minVersion[2])
		}
	}
	return nil
}

// checkPNG fails unless path holds a PNG, because vhs can exit 0 without
// writing it.
func checkPNG(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("vhs exited 0 but wrote no screenshot: %w", err)
	}
	defer f.Close()
	head := make([]byte, len(pngMagic))
	if _, err := io.ReadFull(f, head); err != nil || !bytes.Equal(head, pngMagic) {
		return fmt.Errorf("vhs exited 0 but %s is not a PNG", path)
	}
	return nil
}

// Options are the flags of `rat shot`.
type Options struct {
	Out         string
	Setup       []string
	Ready       string
	Command     string
	Wait        string
	Width       int
	Height      int
	FontSize    int
	WaitTimeout time.Duration
	VHS         string
	TapeOnly    bool
}

// Run captures the shot opts describes and returns the exit code: 0 when
// the PNG was written, 1 when vhs or a check failed, 2 on a usage error.
func Run(opts Options, args []string, stdout, stderr io.Writer) int {
	if len(args) > 0 {
		fmt.Fprintf(stderr, "shot: unexpected argument %q; the command goes in --command\n", args[0])
		return 2
	}
	s := shot{
		setup:       opts.Setup,
		ready:       opts.Ready,
		command:     opts.Command,
		wait:        opts.Wait,
		width:       opts.Width,
		height:      opts.Height,
		fontSize:    opts.FontSize,
		waitTimeout: opts.WaitTimeout,
	}
	if opts.Out != "" {
		abs, err := filepath.Abs(opts.Out)
		if err != nil {
			fmt.Fprintf(stderr, "shot: --out: %v\n", err)
			return 2
		}
		s.out = abs
	}
	tape, err := s.tape()
	if err != nil {
		fmt.Fprintf(stderr, "shot: %v\n", err)
		return 2
	}
	if opts.TapeOnly {
		fmt.Fprint(stdout, tape)
		return 0
	}

	version, err := exec.Command(opts.VHS, "--version").Output()
	if err != nil {
		fmt.Fprintf(stderr, "shot: %s --version: %v\n", opts.VHS, err)
		return 1
	}
	if err := checkVersion(string(version)); err != nil {
		fmt.Fprintf(stderr, "shot: %v\n", err)
		return 1
	}

	if err := os.MkdirAll(filepath.Dir(s.out), 0o755); err != nil {
		fmt.Fprintf(stderr, "shot: %v\n", err)
		return 1
	}
	if err := os.WriteFile(s.tapePath(), []byte(tape), 0o644); err != nil {
		fmt.Fprintf(stderr, "shot: %v\n", err)
		return 1
	}
	// A PNG left from an earlier run would pass checkPNG for a run that wrote nothing.
	if err := os.Remove(s.out); err != nil && !errors.Is(err, os.ErrNotExist) {
		fmt.Fprintf(stderr, "shot: %v\n", err)
		return 1
	}

	ctx, cancel := context.WithTimeout(context.Background(), runTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, opts.VHS, s.tapePath())
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(stderr, "shot: vhs %s: %v\n", s.tapePath(), err)
		return 1
	}
	if err := checkPNG(s.out); err != nil {
		fmt.Fprintf(stderr, "shot: %v\n", err)
		return 1
	}
	fmt.Fprintln(stdout, s.out)
	return 0
}
