# claude skills

`skills/` の skill がどう呼び合うか。実線は「その skill を読み込む」、点線は「必要な時だけ相談する」。`reconstruct` だけはモデルから隠れていて、ユーザーが `/reconstruct` と打った時にしか動かない。

`~/.claude/skills/ha` と `~/.claude/skills/agent-browser` はここに無い。前者は flake input `kawarimidoll/ha` 同梱の skill を `modules/git/ha.nix` が、後者は llm-agents.nix の `agent-browser` 同梱の skill を `modules/ai/claude.nix` がそのまま置いている。

`textlint/` は skill ではなく、PR / issue 本文にかける textlint の設定と自前ルール。`modules/ai/_textlint.nix` (claude feature の一部) がこれを `lint-body` と `lint-body-hook` の 2 コマンドに焼き込む。hook は pull-request と issue の frontmatter が skill を呼んだときに登録し、`gh pr create` などの `--body-file` に指摘が残っていればコマンドを止める。

```mermaid
flowchart TD
  subgraph build["実装"]
    direction LR
    design["design<br/>設計相談"]
    implement["implement<br/>TDD で実装する"]
    testdesign["test-design<br/>何をテストするか"]
  end

  subgraph ship["レビューに出す"]
    direction LR
    pr["pull-request<br/>PR 本文を書く"]
    issue["issue<br/>issue を立てる"]
    explain["explain<br/>人が読む文の構造"]
  end

  subgraph history["履歴"]
    direction LR
    hr["history-review<br/>pass か rebuild を返す"]
    user(["ユーザーが /reconstruct を打つ"])
    reconstruct["reconstruct<br/>最終 diff から積み直す"]
  end

  subgraph release["リリース"]
    direction LR
    version["version<br/>次の SemVer"]
    bp["branch-protection<br/>main を保護する"]
  end

  subgraph meta["skill を作る"]
    direction LR
    sa["skill-authoring<br/>仕様確認と validator"]
    sc["skill-creator (plugin)<br/>草稿と eval"]
  end

  subgraph solo["単独"]
    direction LR
    refactor["refactor<br/>整理の計画を立てる"]
    docs["docs<br/>ドキュメント"]
    profile["profile<br/>計測"]
    anchors["anchors<br/>HACK / AIDEV-NOTE の一覧"]
  end

  subgraph shared["共通"]
    direction LR
    check["check<br/>lint / test / fmt"]
    commit["commit<br/>Conventional Commits"]
    lint["lint-body<br/>本文の textlint (hook も同じ検査)"]
    bv["browser-verify<br/>agent-browser で画面を見る"]
  end

  implement -.->|"設計に迷った時"| design
  implement -.->|"何を試すか迷った時"| testdesign
  implement -->|"実装が終わった時"| hr
  pr -->|"pre-flight"| hr
  pr -->|"本文を書く時"| explain
  pr -->|"やらなかったことを残す時"| issue
  issue -->|"本文を書く時"| explain
  hr -->|"rebuild"| user
  user --> reconstruct
  version -->|"tag 後"| bp
  sa -->|"草稿と eval"| sc

  implement -->|"毎サイクル"| check
  implement -->|"毎サイクル"| commit
  pr -->|"push 前"| check
  explain -->|"gh に渡す前"| lint
  implement -.->|"画面が変わった時"| bv
  pr -.->|"before / after を撮る時"| bv
  reconstruct -->|"1 commit ずつ"| commit
  version -->|"tag 前"| check
  refactor -.->|"計画を実行する時"| commit

  classDef hidden stroke-dasharray:4 3
  class reconstruct hidden
```
