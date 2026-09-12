# Claude Code 以外の AI エージェント CLI と、それらが引く MCP サーバ。
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
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # llm-agents.claude-code  # Nix 管理をやめて別途導入するため一旦コメントアウト
        # nixpkgs より追従が速いので llm-agents 版を使う
        llm-agents.gemini-cli
        context7-mcp
        # github-mcp-server
        # serena
        # slite-mcp-server
      ];

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
        cxD = {
          cmd = "codex --dangerously-bypass-approvals-and-sandbox";
          desc = "承認とサンドボックスを飛ばす（危険）";
        };
      };
    };

  flake.modules.darwin.agents = share;
  flake.modules.nixos.agents = share;
}
