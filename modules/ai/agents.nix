# Claude Code 以外の AI エージェント CLI と、それらが引く MCP サーバ。
# codex には Claude と同じ指示書 (configs/agents/AGENTS.md) と同じ skill (my.skills) を渡す。
# Claude Code は ~/.agents/ を読まないので、skill dir は agent ごとに 1 本ずつ並べる。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  share = {
    nixpkgs.overlays = [
      inputs.mcp-servers-nix.overlays.default
      inputs.llm-agents.overlays.shared-nixpkgs
    ];
    home-manager.sharedModules = [ hm.agents ];
  };
in
{
  flake.modules.homeManager.agents =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        # llm-agents.claude-code  # Nix 管理をやめて別途導入するため一旦コメントアウト
        # nixpkgs より追従が速いので llm-agents 版を使う
        llm-agents.gemini-cli
        context7-mcp
        # agent が引くツール。hook / MCP の配線は Claude 側が configs/agents/settings.json と
        # mcp-defaults、codex 側が /etc/codex/config.toml
        llm-agents.rtk # Bash 出力を圧縮する proxy。Claude では PreToolUse hook が前置する
        llm-agents.ck # 意味検索の grep。`ck --sem`、MCP は `ck --serve`
        llm-agents.codegraph # コードのシンボルと呼び出しのグラフ。MCP は `codegraph serve --mcp`
        # github-mcp-server
        # serena
        # slite-mcp-server
      ];

      # AIDEV-NOTE: ~/.codex/config.toml は置かない。codex が trust / plugins を書き込み、symlink は起動時に実体で置き換える (openai/codex#6646)
      home.file = {
        ".codex/AGENTS.md".source = ../../configs/agents/AGENTS.md;
      }
      // lib.mapAttrs' (
        name: src: lib.nameValuePair ".agents/skills/${name}" { source = src; }
      ) config.my.skills;

      # codex には plan mode がないので ccp 相当は置いていない。--sandbox read-only は
      # 「書けない」だけで計画を出す挙動ではなく、同じ p を当てると cc 側と誤解を生む
      my.shell.abbr = {
        cx = {
          cmd = "codex";
          desc = "Codex CLI";
        };
        cxr = {
          cmd = "codex resume";
          desc = "セッション再開。引数なしはピッカー、--last で直近";
        };
        cxA = {
          cmd = "codex --approve-for-me";
          desc = "承認を auto_review に委ねる。sandbox は workspace-write 固定";
        };
      };
    };

  flake.modules.darwin.agents = share;
  flake.modules.nixos.agents = share;
}
