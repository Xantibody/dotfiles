# dotfiles

Nix flake managing macOS (nix-darwin) and NixOS hosts via home-manager.

## Module Layout

`flake.nix` holds inputs and nothing else; everything under `modules/` is
loaded by import-tree as a flake-parts module. One file is one feature, and
that file carries every class the feature touches:

```nix
# modules/japanese/skk.nix
{
  flake.modules.homeManager.skk = { ... };  # 辞書と CLI
  flake.modules.darwin.skk = { ... };       # launchd で常駐させる
  flake.modules.nixos.skk = { ... };        # 同じ home-manager 側を載せる
}
```

Group by what a person calls the thing, not by the option namespace it lands
in. There is no `programs/` or `services/` directory: fish's darwin
`programs.fish.enable`, its home-manager configuration and its abbreviations
are all in `modules/shell/fish.nix`, and `modules/hardware/e14gen6/fingerprint.nix`
holds a service, two PAM entries and a polkit rule because they are one sensor.

A feature's darwin/nixos module hands its home-manager half to
`home-manager.sharedModules`, so a host lists a feature once. Hosts are in
`modules/hosts/`; they name features with `lib.attrVals` (not `with`, whose
bindings lose to any let or function argument of the same name) and set
`my.user` and the platform. Values shared between features are options —
`my.dock.apps`, `my.shell.abbr`, `my.skk.dictionary` — never specialArgs.

`flake.modules` is `lazyAttrsOf`, so a feature no host lists is never
evaluated. A file starting with `_` is not read by import-tree; use that for
something that is not a flake-parts module.

Two recipes guard the layout. `just snapshot <host>` writes the evaluated
configuration to `.ai/profiles/`, so a refactor is checked by diffing rather
than by rereading; `just eval-profile <host>` measures evaluation cost the
way the numbers in the commit history were measured.

## Git Workflow

Commit straight to `main` — pushing is done by the user. This is a
single-maintainer repo, so a branch and PR buy no review value for an
ordinary change.

Branch and open a PR only when the diff is large — roughly 200+ changed lines,
or a change spanning several modules or hosts — where an isolated, reviewable
unit is actually worth the ceremony.

## Commit Scopes

Infer the Conventional Commits scope from staged file paths using these rules:

| Path Pattern               | Inferred Scope                                       |
| -------------------------- | ---------------------------------------------------- |
| `flake.lock`               | `deps`                                               |
| `flake.nix`                | `flake`                                              |
| `.github/renovate*`        | `renovate`                                           |
| `configs/<name>/`          | `<name>` (e.g., `claude`, `k9s`)                     |
| `modules/<name>.nix`       | `<name>` (e.g., `apps`, `audio`)                     |
| `modules/<dir>/<name>.nix` | `<name>` — the feature, not the directory            |
| `modules/base/<name>.nix`  | the setting it configures (`nix`, `nixpkgs`, `user`) |
| `modules/hosts/`           | `hosts`                                              |
| `modules/flake/`           | `flake`                                              |
| `overlays/`                | `overlays`                                           |
| `script/`, `justfile`      | `script`                                             |
