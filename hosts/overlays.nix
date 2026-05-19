{ inputs }:

with inputs;
[
  mcp-servers-nix.overlays.default
  llm-agents.overlays.default
  (final: prev: {
    ichigyo-ls = ichigyo-ls.packages.${final.system}.default;
    # Workaround: direnv build hangs on darwin due to test-fish failure
    # https://github.com/NixOS/nixpkgs/issues/507531
    direnv = prev.direnv.overrideAttrs (_: {
      doCheck = false;
    });
  })
]
