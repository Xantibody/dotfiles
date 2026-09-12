# darwin と nixos の両方から nix.settings に合成されるバイナリキャッシュ設定。
# substituters ではなく extra- を使うのは cache.nixos.org のデフォルトを潰さないため。
{
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
}
