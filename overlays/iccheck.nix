final: prev: {
  iccheck = prev.buildGoModule (finalAttrs: {
    pname = "iccheck";
    version = "0.9.0";
    src = prev.fetchFromGitHub {
      owner = "salab";
      repo = "iccheck";
      rev = "v0.9.0";
      sha256 = "sha256-2bD5gN/7C79njrCVoR5H2ses6pWAQHZcYj7/f2+Ui/o=";
    };
    vendorHash = "sha256-pqjtoshoQlz+SFpaaxN3GMaDdZ+ztiIV6w+CTrRHuaA=";
    meta = {
      homepage = "https://github.com/salab/iccheck";
      changelog = "https://github.com/salab/iccheck/releases/tag/v${finalAttrs.version}";
      license = prev.lib.licenses.mit;
    };
    doCheck = false;
    subPackages = [
      "."
      "./cmd"
      "./pkg/domain"
      "./pkg/fleccs"
      "./pkg/lsp"
      "./pkg/ncdsearch"
      "./pkg/printer"
      "./pkg/search"
      "./pkg/utils"
    ];
  });
}
