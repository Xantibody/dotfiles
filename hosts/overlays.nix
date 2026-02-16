{ inputs }:

with inputs;
[
  mcp-servers-nix.overlays.default
  llm-agents.overlays.default
]
