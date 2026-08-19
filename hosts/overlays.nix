{ inputs }:

with inputs;
[
  mcp-servers-nix.overlays.default
  llm-agents.overlays.shared-nixpkgs
  (import ./my-tools.nix { inherit inputs; })
]
