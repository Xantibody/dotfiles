package main

import "strings"

// Cue is one SRT entry. Index and Timing are kept as written so they come
// back out byte for byte; only Text is translated.
type Cue struct {
	Index  string
	Timing string
	Text   []string
}

func parseSRT(s string) []Cue {
	s = strings.TrimPrefix(strings.ReplaceAll(s, "\r\n", "\n"), "\ufeff")
	var cues []Cue
	for _, block := range strings.Split(s, "\n\n") {
		lines := strings.Split(strings.TrimSpace(block), "\n")
		if len(lines) < 2 {
			continue
		}
		cues = append(cues, Cue{Index: lines[0], Timing: lines[1], Text: lines[2:]})
	}
	return cues
}

func formatSRT(cues []Cue) string {
	blocks := make([]string, len(cues))
	for i, c := range cues {
		blocks[i] = strings.Join(append([]string{c.Index, c.Timing}, c.Text...), "\n") + "\n"
	}
	return strings.Join(blocks, "\n")
}
