// folded stacks を読み、各サンプルを「スタック中に現れるソース (flake input) の集合」で
// 集計する。同じサンプルが複数ソースに数えられるので合計は 100% を超える。
// leaf 列はそのソースのフレームが末端 (自己時間) だったサンプルの割合。
package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

var srcRe = regexp.MustCompile(`«(github:[^/]+/[^/]+/[0-9a-f]{7}|git\+https://github.com/nixos/nixpkgs\?ref=nixos-unstable-small&rev=[0-9a-f]{7}|gitlab:[^/]+/[^/]+/[0-9a-f]{7})`)

func main() {
	f, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	defer f.Close()
	any := map[string]int{}
	leaf := map[string]int{}
	total := 0
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 1<<20), 1<<24)
	for sc.Scan() {
		line := sc.Text()
		sp := strings.LastIndex(line, " ")
		n, _ := strconv.Atoi(line[sp+1:])
		total += n
		frames := strings.Split(line[:sp], ";")
		seen := map[string]bool{}
		for _, fr := range frames {
			if m := srcRe.FindStringSubmatch(fr); m != nil {
				seen[m[1]] = true
			}
		}
		for s := range seen {
			any[s] += n
		}
		for i := len(frames) - 1; i >= 0; i-- {
			if m := srcRe.FindStringSubmatch(frames[i]); m != nil {
				leaf[m[1]] += n
				break
			}
		}
	}
	type row struct {
		src       string
		any, leaf int
	}
	rows := []row{}
	for s, a := range any {
		rows = append(rows, row{s, a, leaf[s]})
	}
	sort.Slice(rows, func(i, j int) bool { return rows[i].leaf > rows[j].leaf })
	fmt.Printf("samples: %d\n%6s %6s  source\n", total, "leaf%", "any%")
	for _, r := range rows {
		fmt.Printf("%5.1f%% %5.1f%%  %s\n", 100*float64(r.leaf)/float64(total), 100*float64(r.any)/float64(total), r.src)
	}
}
