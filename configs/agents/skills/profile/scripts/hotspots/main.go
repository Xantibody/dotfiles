// hotspots ranks the frames of a folded-stacks file so the hot spots of a
// flame graph can be read from a terminal transcript. The SVG stays the
// artifact for the user; this is the same data as text.
//
//	go run <skill-dir>/scripts/hotspots/main.go [-n 15] <file.folded>
//
// Self width is the share of samples where the frame is the leaf, i.e. where
// the CPU actually was. Total width includes children, which is what the
// flame graph draws. A folded line is "frame;frame;frame count".
package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
)

func main() {
	n := flag.Int("n", 15, "number of frames to list per table")
	flag.Parse()
	if flag.NArg() != 1 {
		fmt.Fprintln(os.Stderr, "usage: hotspots [-n N] <file.folded>")
		os.Exit(2)
	}
	f, err := os.Open(flag.Arg(0))
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer f.Close()

	self := map[string]float64{}
	total := map[string]float64{}
	var samples float64
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 1<<20), 1<<26)
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
	if samples == 0 {
		fmt.Fprintln(os.Stderr, "no folded stacks found")
		os.Exit(1)
	}

	fmt.Printf("samples: %.0f\n\n", samples)
	fmt.Println("self (where the CPU is):")
	print(self, samples, *n)
	fmt.Println()
	fmt.Println("total (frame plus its children):")
	print(total, samples, *n)
}

func print(m map[string]float64, samples float64, n int) {
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
		fmt.Printf("%6.1f%%  %s\n", 100*r.count/samples, r.frame)
	}
}
