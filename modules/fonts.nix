# フォント。explex-nf は日本語と等幅のために両方の host で要る。
{
  flake.modules.darwin.fonts =
    { pkgs, ... }:
    {
      fonts.packages = [ pkgs.explex-nf ];
    };

  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        explex-nf
      ];
    };
}
