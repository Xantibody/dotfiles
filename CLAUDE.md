# dotfiles

Nix flake managing macOS (nix-darwin) and NixOS hosts via home-manager.

## Commit Scopes

Infer the Conventional Commits scope from staged file paths using these rules:

| Path Pattern                               | Inferred Scope                   |
| ------------------------------------------ | -------------------------------- |
| `flake.lock`                               | `deps`                           |
| `flake.nix`                                | `flake`                          |
| `.github/renovate*`                        | `renovate`                       |
| `configs/<name>/`                          | `<name>` (e.g., `claude`, `k9s`) |
| `modules/home-manager/programs/<name>.nix` | `<name>` (e.g., `fish`, `kitty`) |
| `modules/home-manager/programs/<name>/`    | `<name>` (e.g., `nixcats`)       |
| `modules/home-manager/home/`               | `home`                           |
| `modules/darwin/`                          | `darwin`                         |
| `modules/nixos/`                           | `nixos`                          |
| `overlays/`                                | `overlays`                       |
