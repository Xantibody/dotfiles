{ pkgs, ... }:
let
  k8s = import ./k8s.nix { inherit pkgs; };
  mcp = import ./mcp.nix { inherit pkgs; };
in
with pkgs;
(
  [
    arto
    bat

    obsidian
    cargo
    deck
    direnv
    eza
    fd
    go
    gopls

    gh
    gnumake

    iccheck
    nix-prefetch-github
    ripgrep
    vhs
    llm-agents.claude-code
    llm-agents.codex
    llm-agents.gemini-cli

    yaskkserv2
    discord-ptb
  ]
  ++ k8s
  ++ mcp
)
