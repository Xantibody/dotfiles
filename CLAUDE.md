# dotfiles

Nix flake managing macOS (nix-darwin) and NixOS hosts via home-manager.

## Git Workflow

Commit and push straight to `main`. This is a single-maintainer repo, so a
branch and PR buy no review value for an ordinary change.

Branch and open a PR only when the diff is large — roughly 200+ changed lines,
or a change spanning several modules or hosts — where an isolated, reviewable
unit is actually worth the ceremony.

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
