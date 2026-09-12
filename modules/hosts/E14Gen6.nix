# ThinkPad E14 Gen6 (NixOS)。
{ config, lib, ... }:
let
  nixos = config.flake.modules.nixos;
in
{
  my.hosts.nixos = [ "E14Gen6" ];

  flake.modules.nixos.E14Gen6 = {
    imports = lib.attrVals [
      # 土台
      "nix"
      "nixpkgs"
      "user"
      "home-manager"
      "locale"
      "networking"
      "security"
      "fonts"
      # ハードウェア
      "hardware-configuration"
      "boot"
      "power"
      "bluetooth"
      "fingerprint"
      "keyboard"
      "remap"
      "audio"
      "printing"
      # デスクトップ
      "hyprland"
      "waybar"
      "rofi"
      "notifications"
      "idle"
      # 道具
      "fish"
      "fzf"
      "prompt"
      "kitty"
      "neovim"
      "emacs"
      "mdsf"
      "git"
      "claude"
      "agents"
      "comma"
      "skk"
      "zen"
      "k8s"
      "dev-cli"
      "apps"
      "profiling"
      "docker"
      "sops"
    ] nixos;

    my.user = {
      name = "raizawa";
      home = "/home/raizawa";
    };
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "24.11";
  };
}
