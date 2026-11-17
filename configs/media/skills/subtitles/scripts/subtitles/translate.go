package main

import (
	"regexp"
	"strings"
)

// markup matches the <font>, <i>, <b> and <u> tags SRT and YouTube's captions
// carry. A tag left in would be translated, or dropped, as if it were speech;
// any other angle bracket ("<3", "a < b") is speech and stays.
var markup = regexp.MustCompile(`(?i)</?(font|i|b|u)\b[^<>]*>`)

// translator turns newline-separated text into its translation.
type translator func(text string) (string, error)

// translateLines sends up to chunk lines per call, so the model loads once
// per chunk rather than once per subtitle.
func translateLines(lines []string, chunk int, tr translator) ([]string, error) {
	var result []string
	for start := 0; start < len(lines); start += chunk {
		part, err := translatePart(lines[start:min(start+chunk, len(lines))], tr)
		if err != nil {
			return nil, err
		}
		result = append(result, part...)
	}
	return result, nil
}

// translatePart trusts an answer only when it has one line per input line;
// otherwise a merged or split line would move every later subtitle onto the
// wrong timestamp. It halves the part until the counts agree, and a single
// line takes the whole answer.
func translatePart(lines []string, tr translator) ([]string, error) {
	out, err := tr(strings.Join(lines, "\n"))
	if err != nil {
		return nil, err
	}
	got := strings.Split(strings.TrimSpace(out), "\n")
	if len(lines) == 1 {
		return []string{strings.Join(got, " ")}, nil
	}
	if len(got) == len(lines) {
		return got, nil
	}
	half := len(lines) / 2
	left, err := translatePart(lines[:half], tr)
	if err != nil {
		return nil, err
	}
	right, err := translatePart(lines[half:], tr)
	if err != nil {
		return nil, err
	}
	return append(left, right...), nil
}

// translateCues translates each cue's text as one line, keeping its index and
// timing. Cues without text are left alone rather than sent as empty lines.
func translateCues(cues []Cue, chunk int, tr translator) ([]Cue, error) {
	var lines []string
	var at []int
	for i, c := range cues {
		if text := strings.TrimSpace(markup.ReplaceAllString(strings.Join(c.Text, " "), "")); text != "" {
			lines = append(lines, text)
			at = append(at, i)
		}
	}
	translated, err := translateLines(lines, chunk, tr)
	if err != nil {
		return nil, err
	}
	out := append([]Cue(nil), cues...)
	for j, i := range at {
		out[i].Text = []string{translated[j]}
	}
	return out, nil
}
