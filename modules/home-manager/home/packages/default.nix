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
    # tsgo-lsp プラグインが PATH 上の tsgo を起動する
    # tsc も同梱されるので typescript は別途入れなくてよい
    typescript-go
    vhs
    yaskkserv2

    # llm-agents.claude-code  # Nix 管理をやめて別途導入するため一旦コメントアウト
    # llm-agents.gemini-cli   # Nix 管理をやめて別途導入するため一旦コメントアウト
  ]
  ++ k8s
  ++ mcp
  ++ pkgs.lib.optionals isDarwin darwin
)
