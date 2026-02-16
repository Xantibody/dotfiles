{ inputs }:

with inputs;
[
  mcp-servers-nix.overlays.default
  llm-agents.overlays.default
  (final: _prev: {
    ichigyo-ls = ichigyo-ls.packages.${final.system}.default;
  })
]
