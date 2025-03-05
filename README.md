# dotfiles
my configuration


## Nix
```bash
nix run nixpkgs#home-manager -- switch --flake .#raizawa
```

## NixOS
```bash
sudo nixos-rebuild switch --flake .
```
