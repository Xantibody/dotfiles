package main

import (
	"errors"
	"reflect"
	"strings"
	"testing"
)

// recorder is a fake translator: it upper-cases each line and keeps every
// input it was called with.
type recorder struct{ calls []string }

func (r *recorder) translate(text string) (string, error) {
	r.calls = append(r.calls, text)
	return strings.ToUpper(text), nil
}

func TestTranslateLinesOfNothingCallsNoTranslator(t *testing.T) {
	var r recorder
	got, err := translateLines(nil, 10, r.translate)
	if err != nil || len(got) != 0 || len(r.calls) != 0 {
		t.Fatalf("translateLines(nil) = %v, %v with calls %q, want nothing", got, err, r.calls)
	}
}

var _ = reflect.DeepEqual

func TestTranslateLinesOfOneLineCallsTheTranslatorOnce(t *testing.T) {
	var r recorder
	got, err := translateLines([]string{"hello"}, 10, r.translate)
	if err != nil || !reflect.DeepEqual(got, []string{"HELLO"}) || !reflect.DeepEqual(r.calls, []string{"hello"}) {
		t.Fatalf("translateLines = %q, %v with calls %q, want [HELLO] from one call", got, err, r.calls)
	}
}

func TestTranslateLinesSendsAtMostChunkLinesPerCall(t *testing.T) {
	var r recorder
	got, err := translateLines([]string{"a", "b", "c"}, 2, r.translate)
	if err != nil || !reflect.DeepEqual(got, []string{"A", "B", "C"}) || !reflect.DeepEqual(r.calls, []string{"a\nb", "c"}) {
		t.Fatalf("translateLines = %q, %v with calls %q, want [A B C] from calls [a\\nb c]", got, err, r.calls)
	}
}

func TestTranslateLinesSplitsAChunkWhoseLineCountChanged(t *testing.T) {
	var calls []string
	// Merges any multi-line input into one line, and breaks a lone "b" in two:
	// the shapes a model's answer takes that would shift every later subtitle.
	merging := func(text string) (string, error) {
		calls = append(calls, text)
		if text == "b" {
			return "B1\nB2", nil
		}
		return strings.ToUpper(strings.ReplaceAll(text, "\n", " ")), nil
	}
	got, err := translateLines([]string{"a", "b", "c"}, 3, merging)
	if err != nil || !reflect.DeepEqual(got, []string{"A", "B1 B2", "C"}) {
		t.Fatalf("translateLines = %q, %v with calls %q, want [A, B1 B2, C]", got, err, calls)
	}
}

func TestTranslateLinesReturnsTheTranslatorsError(t *testing.T) {
	failing := func(string) (string, error) { return "", errBoom }
	if _, err := translateLines([]string{"a", "b"}, 2, failing); err != errBoom {
		t.Fatalf("translateLines error = %v, want %v", err, errBoom)
	}
}

var errBoom = errors.New("boom")

func TestTranslateCuesKeepsTimingAndSkipsEmptyText(t *testing.T) {
	var r recorder
	cues := []Cue{
		{Index: "1", Timing: "t1", Text: []string{"first line", "second line"}},
		{Index: "2", Timing: "t2"},
		{Index: "3", Timing: "t3", Text: []string{"third"}},
	}
	got, err := translateCues(cues, 10, r.translate)
	want := []Cue{
		{Index: "1", Timing: "t1", Text: []string{"FIRST LINE SECOND LINE"}},
		{Index: "2", Timing: "t2"},
		{Index: "3", Timing: "t3", Text: []string{"THIRD"}},
	}
	if err != nil || !reflect.DeepEqual(got, want) || !reflect.DeepEqual(r.calls, []string{"first line second line\nthird"}) {
		t.Fatalf("translateCues = %#v, %v with calls %q, want %#v", got, err, r.calls, want)
	}
}

func TestTranslateCuesSendsTextWithoutMarkupTags(t *testing.T) {
	var r recorder
	cues := []Cue{{Index: "1", Timing: "t1", Text: []string{`<font color="white" size=".72c">>> All right.</font>`}}}
	got, err := translateCues(cues, 10, r.translate)
	if err != nil || !reflect.DeepEqual(r.calls, []string{">> All right."}) || got[0].Text[0] != ">> ALL RIGHT." {
		t.Fatalf("translateCues = %#v, %v with calls %q, want the tags gone before translating", got, err, r.calls)
	}
}

func TestTranslateCuesKeepsAngleBracketsThatAreNotTags(t *testing.T) {
	var r recorder
	cues := []Cue{{Index: "1", Timing: "t1", Text: []string{"<i>I <3 it</i> when a < b > c"}}}
	if _, err := translateCues(cues, 10, r.translate); err != nil || !reflect.DeepEqual(r.calls, []string{"I <3 it when a < b > c"}) {
		t.Fatalf("translateCues sent %q, %v, want only the <i> tags removed", r.calls, err)
	}
}
