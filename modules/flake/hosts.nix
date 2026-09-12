# 実機 1 台につき 1 つの構成。
# host 側のファイルは「どの機能を載せるか」と自分の名前を書くだけで、
# darwinSystem / nixosSystem を呼ぶのはここ 1 箇所。
{
  config,
  inputs,
  lib,
  ...
}:
{
  options.my.hosts = {
    darwin = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "flake.modules.darwin に同名の module を持つ macOS ホスト";
    };
    nixos = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "flake.modules.nixos に同名の module を持つ NixOS ホスト";
    };
  };

  config.flake = {
    darwinConfigurations = lib.genAttrs config.my.hosts.darwin (
      name:
      inputs.nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [ config.flake.modules.darwin.${name} ];
      }
    );

    nixosConfigurations = lib.genAttrs config.my.hosts.nixos (
      name:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [ config.flake.modules.nixos.${name} ];
      }
    );
  };
}
