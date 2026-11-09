# aarch64-linux の derivation を mac から組むための NixOS VM。
# nix-darwin が launchd で常駐させ、nix.buildMachines に自分を足すので、
# --system aarch64-linux や linux 向けの flake 出力をそのまま build できる。
{
  flake.modules.darwin.linux-builder = {
    nix.linux-builder.enable = true;
  };
}
