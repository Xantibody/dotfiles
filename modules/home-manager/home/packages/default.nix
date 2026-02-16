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
    cargo
    deck
    delta
    difftastic
    direnv
    discord-ptb
    eza
    fd
    gh
    gnumake
    go
    gopls
    iccheck
    nix-prefetch-github
    obsidian
    ripgrep
    vhs
    yaskkserv2

    llm-agents.claude-code
    llm-agents.codex
    llm-agents.gemini-cli
  ]
  ++ k8s
  ++ mcp
  ++ pkgs.lib.optionals isDarwin darwin
)
