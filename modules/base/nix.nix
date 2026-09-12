# nix daemon そのものの設定。
let
  # 上流の flake が publish しているキャッシュ。自前ビルドを避けるためだけの設定。
  # substituters ではなく extra- を使うのは cache.nixos.org のデフォルトを潰さないため。
  caches = {
    extra-substituters = [
      "https://arto.cachix.org"
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "arto.cachix.org-1:yaH0JQomRJTosIcTh2xZPKBEny41D7h6QUePYQzWYqc="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
in
{
  flake.modules.darwin.nix = {
    nix = {
      optimise.automatic = true;
      settings = {
        experimental-features = "nix-command flakes";
        max-jobs = 8;
      }
      // caches;
    };
  };

  flake.modules.nixos.nix = {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      }
      // caches;
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 3d";
      };
    };
  };
}
