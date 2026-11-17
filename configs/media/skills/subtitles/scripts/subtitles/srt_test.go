package main

import (
	"reflect"
	"testing"
)

func TestParseSRTOfEmptyInputHasNoCues(t *testing.T) {
	if cues := parseSRT(""); len(cues) != 0 {
		t.Fatalf("parseSRT(\"\") = %v, want no cues", cues)
	}
}

func TestParseSRTReadsOneCue(t *testing.T) {
	got := parseSRT("1\n00:00:01,000 --> 00:00:02,500\nHello there\n")
	want := []Cue{{Index: "1", Timing: "00:00:01,000 --> 00:00:02,500", Text: []string{"Hello there"}}}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("parseSRT = %#v, want %#v", got, want)
	}
}

func TestParseSRTReadsSeveralMultiLineCues(t *testing.T) {
	got := parseSRT("1\n00:00:01,000 --> 00:00:02,000\nfirst line\nsecond line\n\n2\n00:00:03,000 --> 00:00:04,000\nnext\n")
	want := []Cue{
		{Index: "1", Timing: "00:00:01,000 --> 00:00:02,000", Text: []string{"first line", "second line"}},
		{Index: "2", Timing: "00:00:03,000 --> 00:00:04,000", Text: []string{"next"}},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("parseSRT = %#v, want %#v", got, want)
	}
}

func TestParseSRTToleratesWindowsLineEndingsAndBOM(t *testing.T) {
	got := parseSRT("\ufeff1\r\n00:00:01,000 --> 00:00:02,000\r\nhi\r\n\r\n\r\n2\r\n00:00:03,000 --> 00:00:04,000\r\nbye\r\n")
	want := []Cue{
		{Index: "1", Timing: "00:00:01,000 --> 00:00:02,000", Text: []string{"hi"}},
		{Index: "2", Timing: "00:00:03,000 --> 00:00:04,000", Text: []string{"bye"}},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("parseSRT = %#v, want %#v", got, want)
	}
}

func TestFormatSRTWritesBackWhatParseSRTRead(t *testing.T) {
	src := "1\n00:00:01,000 --> 00:00:02,000\nfirst line\nsecond line\n\n2\n00:00:03,000 --> 00:00:04,000\nnext\n"
	if got := formatSRT(parseSRT(src)); got != src {
		t.Fatalf("formatSRT(parseSRT(src)) = %q, want %q", got, src)
	}
}
