# この repo 自体を触るための設定 (開発シェルとフォーマッタ)。
# ホストの構成には一切入らない。
{ inputs, ... }:
{
  systems = import inputs.systems;
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages =
          with pkgs;
          [
            vim-startuptime
            just
          ]
          # NixOSの指紋キャッシュを消すための依存関係
          ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            python312
            libfprint
            gobject-introspection
            gtk3
            python3Packages.pygobject3
            gusb
            json-glib
          ];
      };
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          actionlint.enable = true;
          gofmt.enable = true;
          nixfmt.enable = true;
          fish_indent.enable = true;
          stylua.enable = true;
          shfmt.enable = true;
          oxfmt.enable = true;
        };
      };
    };
}
