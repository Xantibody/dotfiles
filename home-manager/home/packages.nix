{
  pkgs,
  ...
}:
with pkgs;
[
  #pympress
  google-chrome
  bat
  cliphist
  devbox
  explex
  explex-nf
  eza
  fzf
  gh
#  gnupg
  gnumake
  nix-prefetch-github
  ripgrep
  zellij
  # (buildGoModule {
  #       pname = "iccheck";
  #       version = "0.9.0";
  #       src = fetchFromGitHub {
  #         owner = "salab";
  #         repo = "iccheck";
  #         rev = "v0.9.0";
  #         sha256 = "sha256-2bD5gN/7C79njrCVoR5H2ses6pWAQHZcYj7/f2+Ui/o=";
  #       };
  #       vendorHash = "sha256-pqjtoshoQlz+SFpaaxN3GMaDdZ+ztiIV6w+CTrRHuaA=";
  #       meta = with lib; {
  #         homepage = "https://github.com/salab/iccheck";
  #       };
  #       doCheck = false;
  #       subPackages = [
  #         "."
  #         "./cmd"
  #         "./pkg/domain"
  #         "./pkg/fleccs"
  #         "./pkg/lsp"
  #         "./pkg/ncdsearch"
  #         "./pkg/printer"
  #         "./pkg/search"
  #         "./pkg/utils"
  #       ];
  #     })
]
