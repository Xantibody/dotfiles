# フォント。explex-nf は日本語と等幅のために両方の host で要る。
{
  flake.modules.darwin.fonts =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ (import ../overlays/explex-nf.nix) ];
      fonts.packages = [ pkgs.explex-nf ];
    };

  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ (import ../overlays/explex-nf.nix) ];
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        explex-nf
      ];
    };
}
