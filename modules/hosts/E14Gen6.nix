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
      "firmware"
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
      "theme"
      "which-key"
      # 道具
      "fish"
      "fzf"
      "prompt"
      "kitty"
      "felis"
      "neovim"
      "emacs"
      "mdsf"
      "git"
      "ha"
      "claude"
      "agents"
      "comma"
      "skk"
      "zen"
      "magical-merchant"
      "1password"
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
    # nixosConfigurations の名前と揃え、nixos-rebuild --flake . が名前なしで当たるようにする
    networking.hostName = "E14Gen6";
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "24.11";
  };
}
