// Package hotspots ranks the frames of a folded-stacks file so the hot spots
// of a flame graph can be read from a terminal transcript. The SVG stays the
// artifact for the user; this is the same data as text.
//
//	rat hotspots [-n 15] <file.folded>
//
// Self width is the share of samples where the frame is the leaf, i.e. where
// the CPU actually was. Total width includes children, which is what the
// flame graph draws. A folded line is "frame;frame;frame count".
package hotspots

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"sort"
	"strconv"
	"strings"
)

// maxLine is the longest folded line read; a deep stack makes a long one.
var maxLine = 1 << 26

// Run ranks the frames of the file at path, listing n per table, and
// returns the exit code: 0 when it printed, 1 when the file could not be
// read or held no stacks.
func Run(n int, path string, stdout, stderr io.Writer) int {
	f, err := os.Open(path)
	if err != nil {
		fmt.Fprintf(stderr, "hotspots: %v\n", err)
		return 1
	}
	defer f.Close()

	self := map[string]float64{}
	total := map[string]float64{}
	var samples float64
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, min(1<<20, maxLine)), maxLine)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		sp := strings.LastIndexByte(line, ' ')
		if sp < 0 {
			continue
		}
		count, err := strconv.ParseFloat(line[sp+1:], 64)
		if err != nil {
			continue
		}
		frames := strings.Split(line[:sp], ";")
		samples += count
		self[frames[len(frames)-1]] += count
		seen := map[string]bool{}
		for _, fr := range frames {
			if !seen[fr] { // recursion must not count a frame twice
				seen[fr] = true
				total[fr] += count
			}
		}
	}
	// a read error or a line past the buffer stops Scan early; ranking the
	// part read would pass a truncated profile off as a whole one
	if err := sc.Err(); err != nil {
		fmt.Fprintf(stderr, "hotspots: read %s: %v\n", path, err)
		return 1
	}
	if samples == 0 {
		fmt.Fprintf(stderr, "hotspots: %s has no folded stacks; want lines like \"main;f;g 12\" (the output of a stackcollapse script)\n", path)
		return 1
	}

	fmt.Fprintf(stdout, "samples: %.0f\n\n", samples)
	fmt.Fprintln(stdout, "self (where the CPU is):")
	table(stdout, self, samples, n)
	fmt.Fprintln(stdout)
	fmt.Fprintln(stdout, "total (frame plus its children):")
	table(stdout, total, samples, n)
	return 0
}

// table writes the n widest frames of m as percentages of samples.
func table(w io.Writer, m map[string]float64, samples float64, n int) {
	type kv struct {
		frame string
		count float64
	}
	var rows []kv
	for k, v := range m {
		rows = append(rows, kv{k, v})
	}
	sort.Slice(rows, func(i, j int) bool {
		if rows[i].count != rows[j].count {
			return rows[i].count > rows[j].count
		}
		return rows[i].frame < rows[j].frame
	})
	if len(rows) > n {
		rows = rows[:n]
	}
	for _, r := range rows {
		fmt.Fprintf(w, "%6.1f%%  %s\n", 100*r.count/samples, r.frame)
	}
}
