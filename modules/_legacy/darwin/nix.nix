let
  caches = import ../common/nix-caches.nix;
in
{
  optimise.automatic = true;
  settings = {
    experimental-features = "nix-command flakes";
    max-jobs = 8;
  }
  // caches;
}
