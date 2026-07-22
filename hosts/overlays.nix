{ inputs }:

with inputs;
[
  mcp-servers-nix.overlays.default
  llm-agents.overlays.shared-nixpkgs
  (import ./my-tools.nix { inherit inputs; })
  (_final: prev: {
    # Workaround: direnv build hangs on darwin due to test-fish failure
    # https://github.com/NixOS/nixpkgs/issues/507531
    direnv = prev.direnv.overrideAttrs (_: {
      doCheck = false;
    });
  })
]
