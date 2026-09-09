{ pkgs, ... }:
let
  k8s = import ./k8s.nix { inherit pkgs; };
  mcp = import ./mcp.nix { inherit pkgs; };
  profile = import ./profile.nix { inherit pkgs; };
  darwin = import ./darwin.nix { inherit pkgs; };
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
with pkgs;
(
  [
    bat
    cargo
    deck
    delta
    difftastic
    direnv
    duckdb
    discord-ptb
    eza
    fd
    gh
    ghq
    gnumake
    go
    gopls
    iccheck
    nix-prefetch-github
    obsidian
    ripgrep
    # tsgo-lsp プラグインが PATH 上の tsgo を起動する (typescript 7 系は tsc と tsgo を同梱)
    typescript
    vhs
    yaskkserv2

    # llm-agents.claude-code  # Nix 管理をやめて別途導入するため一旦コメントアウト
    # nixpkgs より追従が速いので llm-agents 版を使う
    llm-agents.gemini-cli
  ]
  ++ k8s
  ++ mcp
  ++ profile
  ++ pkgs.lib.optionals isDarwin darwin
)
