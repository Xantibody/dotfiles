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

## Local Verification

Do not evaluate or build a whole host locally to verify a change: no
`nix eval .#…Configurations.<host>…`, `nix flake check` or
`darwin-rebuild build`. CI evaluates and builds every host (`check.yml`,
`darwin.yml`, `nixos.yml`), and a host for another platform takes more than
ten minutes from this machine. Verify locally with `nix fmt`, a search for
references the change should have removed, and the tests of the thing that
changed; say in the report that host evaluation is left to CI.
`.claude/settings.json` denies those commands and `nix build .#checks…eval-…`,
so the rule holds without anyone remembering it.

This repository is the first one under the commit gate in observe mode
(`modules/git/verify-gate.nix`): when `git config verify.gate` prints
`observe`, run the local checks above as `verify-gate run -- <command>` after
the last edit, so the commit's `Verified-by:` trailer names them instead of
`none`. The gate only records; a commit without verification still goes
through.

`just snapshot` and `just eval-profile` are for a module-layout refactor and
run only when the user asks for them. When nix does run, it runs one at a
time: one uncached host evaluation peaks above 2 GB, and overlapping two or
three has frozen a 16 GB machine. That holds across agents — a workflow or a
set of subagents may read and edit in parallel, but exactly one runs nix,
after the others have finished.

## Git Workflow

Commit straight to `main` — pushing is done by the user. This is a
single-maintainer repo, so a branch and PR buy no review value, and that
holds for a large diff too. Branch and open a PR only when the user asks
for one.

## Commit Scopes

Infer the Conventional Commits scope from staged file paths using these rules:

| Path Pattern               | Inferred Scope                                       |
| -------------------------- | ---------------------------------------------------- |
| `flake.lock`               | `deps`                                               |
| `flake.nix`                | `flake`                                              |
| `.github/renovate*`        | `renovate`                                           |
| `configs/<name>/`          | `<name>` (e.g., `agents`, `k9s`)                     |
| `modules/<name>.nix`       | `<name>` (e.g., `apps`, `audio`)                     |
| `modules/<dir>/<name>.nix` | `<name>` — the feature, not the directory            |
| `modules/base/<name>.nix`  | the setting it configures (`nix`, `nixpkgs`, `user`) |
| `modules/hosts/`           | `hosts`                                              |
| `modules/flake/`           | `flake`                                              |
| `overlays/`                | `overlays`                                           |
| `script/`, `justfile`      | `script`                                             |
