{ inputs }:

with inputs;
[
  mcp-servers-nix.overlays.default
  llm-agents.overlays.default
  (final: _prev: {
    arto = arto.packages.${final.system}.default;
  })
]
