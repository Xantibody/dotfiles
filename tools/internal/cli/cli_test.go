package cli

import (
	"errors"
	"fmt"
	"strings"
	"testing"
)

func TestExit(t *testing.T) {
	for _, tc := range []struct {
		name   string
		err    error
		code   int
		stderr string
	}{
		{"nil", nil, 0, ""},
		{"coded with a message", &ExitError{Code: 3, Msg: "tool: broke"}, 3, "tool: broke\n"},
		{"silent coded", &ExitError{Code: 2}, 2, ""},
		{"wrapped coded", fmt.Errorf("outer: %w", &ExitError{Code: 4}), 4, "outer: \n"},
		{"plain", errors.New("broke"), 1, "Error: broke\n"},
		{"Code(0)", Code(0), 0, ""},
		{"Code(5)", Code(5), 5, ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var stderr strings.Builder
			if code := Exit(tc.err, &stderr); code != tc.code || stderr.String() != tc.stderr {
				t.Errorf("Exit = %d with stderr %q, want %d with %q", code, stderr.String(), tc.code, tc.stderr)
			}
		})
	}
}
