// flake.lock を読み、同じ名前のノードが複数ある (follows されていない) 入力について、
// どの経路 (root からの inputs チェーン) がそのノードを参照しているかを表にする。
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
)

type node struct {
	Inputs map[string]json.RawMessage `json:"inputs"`
	Locked struct {
		Rev          string `json:"rev"`
		LastModified int64  `json:"lastModified"`
		Ref          string `json:"ref"`
		Type         string `json:"type"`
		Owner        string `json:"owner"`
		Repo         string `json:"repo"`
	} `json:"locked"`
}

type lock struct {
	Nodes map[string]node `json:"nodes"`
	Root  string          `json:"root"`
}

func main() {
	raw, err := os.ReadFile("flake.lock")
	if err != nil {
		panic(err)
	}
	var l lock
	if err := json.Unmarshal(raw, &l); err != nil {
		panic(err)
	}
	// 各ノードへの到達経路を集める
	paths := map[string][]string{}
	var walk func(name, path string, depth int)
	walk = func(name, path string, depth int) {
		if depth > 6 {
			return
		}
		n := l.Nodes[name]
		for inputName, rawRef := range n.Inputs {
			var target string
			if err := json.Unmarshal(rawRef, &target); err != nil {
				// follows 形式 ["a","b"] は既に別ノードとして辿られるので飛ばす
				continue
			}
			p := path + "/" + inputName
			paths[target] = append(paths[target], p)
			walk(target, p, depth+1)
		}
	}
	walk(l.Root, "", 0)

	base := regexp.MustCompile(`^(.*?)(_\d+)?$`)
	groups := map[string][]string{}
	for name := range l.Nodes {
		if name == l.Root {
			continue
		}
		b := base.FindStringSubmatch(name)[1]
		groups[b] = append(groups[b], name)
	}
	keys := make([]string, 0, len(groups))
	for k, v := range groups {
		if len(v) > 1 {
			keys = append(keys, k)
		}
	}
	sort.Strings(keys)
	for _, k := range keys {
		names := groups[k]
		sort.Strings(names)
		fmt.Printf("== %s (%d copies)\n", k, len(names))
		for _, n := range names {
			nd := l.Nodes[n]
			ps := paths[n]
			sort.Strings(ps)
			short := ps
			if len(short) > 3 {
				short = append(short[:3], fmt.Sprintf("...(+%d)", len(ps)-3))
			}
			rev := nd.Locked.Rev
			if len(rev) > 7 {
				rev = rev[:7]
			}
			fmt.Printf("   %-16s %s %s  via %s\n", n, rev, nd.Locked.Ref, strings.Join(short, ", "))
		}
	}
}
