# agent skills

`skills/` の skill は、どう届くかで 2 種類に分かれる。「毎回回る」skill はモデルが一覧から読み込む。「打って使う」skill は `disable-model-invocation: true` で一覧から隠しており、ユーザーが `/name` (codex は `$name`) と打った時だけ動くので、毎セッションの一覧に description が載らない。隠した skill は他の skill からも読み込めない。そのため、そこへ向かう線は「/name を案内」と書き、ユーザーが打つまで止まる。図では実線が「その手順で必ず読み込む」、点線が「条件が合った時だけ読み込む」。

`AGENTS.md` は Claude だけの指示書ではない。`modules/ai/claude.nix` が `~/.claude/CLAUDE.md` に、`modules/ai/agents.nix` が `~/.codex/AGENTS.md` に、同じファイルを配る。毎セッション両 agent が読むので、規則の本文は skill 側に置き、AGENTS.md は「いつ何を読むか」と skill 名だけを持つ。

skill も同じ 2 経路で配る。各 feature が `my.skills` に載せた dir を、claude.nix が `~/.claude/skills/` に、agents.nix が codex 用の `~/.agents/skills/` に並べる (Claude Code は `~/.agents/` を読まない)。`~/.claude/skills/ha` と `~/.claude/skills/agent-browser` がここに無いのはそのためで、前者は flake input `kawarimidoll/ha` 同梱の skill を `modules/git/ha.nix` が、後者は llm-agents.nix の `agent-browser` 同梱の skill を `modules/ai/claude.nix` が `my.skills` に載せている。`mcp-defaults` と `tsgo-lsp` は SKILL.md を持たない Claude plugin なので `~/.claude/skills/` にだけ置く。codex は frontmatter の `name` と `description` しか見ないので、`when_to_use` のトリガー語や `disable-model-invocation`、`hooks` は codex では効かず、隠す skill には `agents/openai.yaml` で同じことを書く。

`rtk` / `ck` / `codegraph` も skill ではなく `modules/ai/agents.nix` が入れるツールで、Claude には `settings.json` の hook と `mcp-defaults` が、codex には `/etc/codex/config.toml` と `~/.codex/hooks.json` が配線する。

`textlint/` は skill ではなく、PR / issue 本文にかける textlint の設定と自前ルール。`modules/ai/_textlint.nix` (claude feature の一部) がこれを `lint-body` と `lint-body-hook` の 2 コマンドに焼き込む。hook は pull-request と issue の frontmatter が skill を呼んだときに登録し、`gh pr create` などの `--body-file` に指摘が残っていればコマンドを止める。

## 実装から PR まで

```mermaid
flowchart TD
  implement["implement<br/>TDD で実装する"]
  check["check<br/>lint / test / fmt"]
  commit["commit<br/>Conventional Commits"]
  hr["history-review<br/>pass か rebuild を返す"]
  reconstruct["reconstruct<br/>最終 diff から積み直す"]
  pr["pull-request<br/>PR 本文を書く"]
  issue["issue<br/>issue を立てる"]
  explain["explain<br/>人が読む文の構造"]
  subgraph shot ["画面を撮る"]
    bv["browser-verify<br/>ブラウザ"]
    tv["terminal-verify<br/>ターミナル"]
  end
  anchors["anchors<br/>HACK / AIDEV-NOTE の規則と一覧"]
  design["design<br/>設計相談"]
  testdesign["test-design<br/>何をテストするか"]
  ab[/"agent-browser<br/>headless Chrome の CLI"/]
  vhs[/"vhs<br/>tape から端末を撮る"/]
  lint[/"lint-body<br/>本文の textlint (hook も同じ検査)"/]

  implement -->|"毎サイクル"| check
  implement -->|"毎サイクル"| commit
  implement -->|"実装が終わった時"| hr
  implement -.->|"画面が変わった時"| shot
  implement -.->|"設計に迷った時"| design
  implement -.->|"何を試すか迷った時"| testdesign
  implement -.->|"HACK / AIDEV-NOTE を残す時"| anchors
  anchors -.->|"閉じた HACK を外す時"| implement
  anchors -.->|"TODO は"| issue
  hr -->|"rebuild なら"| reconstruct
  reconstruct -->|"1 commit ずつ"| commit
  pr -->|"pre-flight"| hr
  pr -->|"push 前"| check
  pr -->|"本文を書く時"| explain
  pr -.->|"未コミットがある時"| commit
  pr -.->|"before / after を撮る時"| shot
  pr -.->|"やらなかったことを残す時"| issue
  issue -->|"本文を書く時"| explain
  explain -.->|"やらなかったことの行き先"| issue
  explain -->|"gh に渡す前"| lint
  bv --> ab
  tv --> vhs
```

## 打って使う skill

```mermaid
flowchart LR
  user(["ユーザーが /name と打つ"])
  version["version<br/>次の SemVer"]
  bp["branch-protection<br/>main を保護する"]
  docs["docs<br/>ドキュメント"]
  refactor["refactor<br/>整理の計画"]
  check["check"]
  commit["commit"]
  explain["explain"]
  anchors["anchors"]
  issue["issue"]
  rustdoc["rustdoc<br/>Rust の doc"]

  user --> version & bp & docs & refactor
  version -->|"tag 前"| check
  version -->|"報告の URL"| explain
  version -.->|"tag 後は /branch-protection を案内"| bp
  bp -->|"報告の URL"| explain
  docs -.->|"Rust は /rustdoc を案内"| rustdoc
  docs -.->|"コードを直すなら /refactor を案内"| refactor
  docs -.->|"why-not を残す時"| anchors
  docs -.->|"TODO は"| issue
  refactor -.->|"計画を実行する時"| check
  refactor -.->|"計画を実行する時"| commit
```

`rustdoc` は一覧に載る skill で、`*.rs` を触った時にも読み込まれる。

## skill を作る時

```mermaid
flowchart LR
  sa["skill-authoring<br/>仕様確認・validator・図の更新"]
  sc["skill-creator (plugin)<br/>草稿と eval"]
  readme[/"README.md<br/>この図"/]

  sa -->|"草稿と eval"| sc
  sa -->|"skill を変えた commit で"| readme
```

どこからも読み込まれず、ユーザーの依頼で直接呼ばれる skill:

- `profile` — 計測
