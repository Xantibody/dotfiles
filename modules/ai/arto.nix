# Arto: AI エージェントの作業を可視化する macOS アプリ。
# アプリ本体、neovim 側の連携プラグイン、上流が publish しているキャッシュを
# まとめて 1 ファイルに置く。Linux 版は無いので darwin だけ。
{ inputs, config, ... }:
{
  flake.modules.homeManager.arto =
    { pkgs, ... }:
    let
      sources = pkgs.callPackage ../../_sources/generated.nix { };
    in
    {
      home.packages = [ pkgs.arto ];

      # neovim 側は modules/editor/neovim.nix が組んだ定義に足す形で入る
      nixCats = {
        categoryDefinitions.merge = _: {
          startupPlugins.display = [
            (pkgs.vimUtils.buildVimPlugin {
              name = "arto-vim";
              inherit (sources.arto-vim) src;
            })
          ];
        };
        packageDefinitions.merge.nvim = _: {
          extra.arto_path = "${pkgs.arto}/Applications/Arto.app";
        };
      };
    };

  flake.modules.darwin.arto = {
    nixpkgs.overlays = [
      (final: _prev: {
        arto = inputs.arto.packages.${final.stdenv.hostPlatform.system}.default;
      })
    ];

    # Tauri アプリを手元で組まずに済ませるための上流キャッシュ
    nix.settings = {
      extra-substituters = [ "https://arto.cachix.org" ];
      extra-trusted-public-keys = [
        "arto.cachix.org-1:yaH0JQomRJTosIcTh2xZPKBEny41D7h6QUePYQzWYqc="
      ];
    };

    home-manager.sharedModules = [ config.flake.modules.homeManager.arto ];
  };
}
