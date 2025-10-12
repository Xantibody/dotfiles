final: prev: {
  deck = prev.buildGoModule (finalAttrs: {
    pname = "deck";
    version = "1.21.5";
    src = prev.fetchFromGitHub {
      owner = "k1LoW";
      repo = "deck";
      rev = "v${finalAttrs.version}";
      sha256 = "sha256-EpE4mR3qmcXeuafupqw3RwC7afLuDxKIoFU8unp86lA=";
    };
    vendorHash = "sha256-DelGxvLReDGwtuddDRiuUxPDR1a9lCWwT9pNgkdV1Xc=";
    meta = {
      homepage = "https://github.com/k1LoW/deck";
      changelog = "https://github.com/k1LoW/deck/releases/tag/v${finalAttrs.version}";
      description = "A tool for creating deck using Markdown and Google Slides";
      license = prev.lib.licenses.mit;
    };
    doCheck = false;
  });
}
