{ pkgs, ... }:
let
  k8s = import ./k8s.nix { inherit pkgs; };
  mcp = import ./mcp.nix { inherit pkgs; };
  darwin = import ./darwin.nix { inherit pkgs; };
  isDarwin = pkgs.stdenv.isDarwin;
in
with pkgs;
(
  [
    bat
    c4
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
    vhs
    yaskkserv2

    # llm-agents.claude-code  # Nix 管理をやめて別途導入するため一旦コメントアウト
    # llm-agents.gemini-cli   # Nix 管理をやめて別途導入するため一旦コメントアウト
  ]
  ++ k8s
  ++ mcp
  ++ pkgs.lib.optionals isDarwin darwin
)
