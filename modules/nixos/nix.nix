let
  caches = import ../common/nix-caches.nix;
in
{
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
}
