# Absorbing what the repo already has

One section per step, matching `survey.md`. An
existing tool that does a step's job stays and the step wires it in; replace a
tool only when it cannot be wired in, and say why in the step's commit body.

## 1. devShell and direnv

- An existing `flake.nix` keeps its style. With flake-utils or hand-written
  `outputs`, add `devShells.<system>.default` there; do not convert to
  flake-parts for this step. `assets/flake.nix` is for a repo with no flake.
- `shell.nix` / `default.nix` with `mkShell`: move its packages and `shellHook`
  into the devShell, then delete it in the same commit.
- devenv (`devenv.nix`, `devenv.yaml`, `.envrc` with `use devenv`): step 1 is
  done. Add later tools through devenv's `packages`. Do not migrate it to a
  plain flake. Later steps change shape: step 2 is devenv's own
  `treefmt.enable = true; treefmt.config.programs.<name>.enable = true;` with
  `treefmt-nix` added to `devenv.yaml` inputs (`devenv inputs add treefmt-nix
  github:numtide/treefmt-nix`), so the `flake.nix` greps below do not apply and
  `nix fmt` is replaced by `treefmt` inside the shell; step 4 runs
  `devenv shell just check` after installing devenv
  (https://devenv.sh/integrations/treefmt/,
  https://devenv.sh/integrations/github-actions/).
- asdf / mise (`.tool-versions`, `mise.toml`, `.mise.toml`), `.nvmrc`,
  `.python-version`, `rust-toolchain.toml`: carry each pinned version into the
  devShell with the matching nixpkgs attribute (check it on
  https://search.nixos.org/packages, e.g. `nodejs_22`). Delete the version file
  once the devShell provides the tool, unless the README documents a non-Nix
  setup that reads it; then keep it and record the duplication in an ADR.
  `rust-toolchain.toml` stays: rustup-style overlays read it.
- `.envrc` with more than `use flake` (exported variables, `dotenv`): keep every
  line, put `use flake` first.

**`.envrc` notes**: `use flake` works with plain direnv (its stdlib defines
`use_flake`) and with nix-direnv, which adds caching, a GC root and fallback to
the last working shell. nix-direnv belongs to the user's machine
(home-manager `programs.direnv.nix-direnv.enable`), not to the repo. Both watch
`flake.nix` and `flake.lock`; when the devShell reads another file (a
`nix/devshell.nix`, a `rust-toolchain.toml`), add `watch_file <path>` before
`use flake`, which nix-direnv requires. Sources:
https://github.com/nix-community/nix-direnv (README, 3.2.0),
https://github.com/direnv/direnv/blob/master/stdlib.sh.

Never run `direnv allow` for the user; verify with `nix develop --command`.

## 2. `nix fmt` through treefmt-nix

- A repo that already formats Nix with alejandra or nixpkgs-fmt keeps it
  (`programs.alejandra`); switching style is a churn commit nobody asked for.
- `treefmt.toml`: move each `[formatter.x]` to `programs.x` (or
  `settings.formatter.x` for one treefmt-nix lacks) and delete the file; the
  treefmt-nix wrapper passes its own `--config-file`, so the TOML would be dead.
- Prettier: `programs.prettier.enable` leaves `.prettierrc` in charge as long as
  `programs.prettier.settings` is unset. If `.prettierrc` loads plugins from
  `node_modules`, Nix's prettier cannot see them; keep prettier out of treefmt
  and call it from the `fmt` / `fmt-check` recipes through the package manager.
- Biome: treefmt-nix always passes `--config-path` to a generated file, so the
  repo's `biome.json` is ignored. Set
  `programs.biome.settings = pkgs.lib.importJSON ./biome.json;` (plain JSON
  only; for `biome.jsonc`, keep biome out of treefmt as with prettier plugins).
  Keep the nixpkgs biome on the version the `$schema` in `biome.json` names;
  biome reports a mismatch and suggests `biome migrate`. treefmt-nix also
  validates `settings` against a bundled schema picked from `pkgs.biome.version`
  (1.x → 1.9.4, 2.3.x → 2.3.6, any other → 2.1.2). nixpkgs-unstable ships biome
  2.6.5, so it is checked against the 2.1.2 schema; if a newer key fails that
  build, set `programs.biome.validate.enable = false` or point
  `programs.biome.validate.schema` at the matching schema.
- rustfmt: treefmt-nix passes `--edition 2024` by default; set
  `programs.rustfmt.edition` to the edition in `Cargo.toml`. `rustfmt.toml` is
  still read.
- gofmt / gofumpt / goimports, black / ruff-format, clang-format: enable the
  one the repo already uses, not the one you prefer.
- A mature repo: the first full format is its own commit, its SHA goes into
  `.git-blame-ignore-revs`. Formatting is mechanical, so no ratchet.

treefmt-nix option names: https://github.com/numtide/treefmt-nix/tree/main/programs.
treefmt flags (`--ci` = `--no-cache` + `--fail-on-change`):
https://github.com/numtide/treefmt/blob/main/config/config.go.

## 3. `just check`

- One list of steps, not two. If `package.json` scripts, a `Makefile`,
  `Taskfile.yml`, mise tasks, tox/nox or `cargo xtask` already name the lint and
  test commands _and something else calls them_ (husky, lint-staged, another
  workflow, the README), the recipes call those (`pnpm run lint`,
  `make test`). Otherwise the recipes call the tools directly and the old entry
  is left for the user to remove.
- Pick the package manager from the lock file (`pnpm-lock.yaml`, `bun.lock`,
  `package-lock.json`, `uv.lock`, `poetry.lock`) and make the install a
  dependency of `check` with its frozen flag, so `just check` works on a fresh
  clone.
- Existing strictness wins when it is stricter than the stack reference;
  otherwise raise it per the stack reference. Existing violations of a raised
  rule go through the stack reference's ratchet, not a mass fix.

## 4. CI

- In an existing job, replace the setup / install / lint / test steps with
  `nix develop --command just check`. Keep jobs that do something else
  (release, deploy, coverage upload, an OS matrix).
- Keep the job's name when it is a required status check
  (`gh api repos/{owner}/{repo}/rules/branches/<default>` lists the
  `required_status_checks` rules from every ruleset that applies;
  `gh api repos/{owner}/{repo}/branches/<default>/protection/required_status_checks`
  covers classic branch protection);
  renaming drops the requirement silently.
- Match the repo's action pinning: tags by major (`actions/checkout@v7`) or
  full SHAs, whichever is already there.
- Nix installer: `DeterminateSystems/nix-installer-action@main` (installs
  Determinate Nix; `determinate: false` gives upstream Nix, unsupported by them).
  Pinning this action (`@v23`) does not pin Nix: it always installs the newest
  Determinate Nix. To pin Nix itself use `DeterminateSystems/determinate-nix-action@v3`
  (tagged per Determinate release).
  A repo already on `cachix/install-nix-action@v31` (upstream Nix) keeps it.
- Cache: none by default; a devShell made of nixpkgs packages comes from
  cache.nixos.org. When `nix develop` builds something (an override, the
  project's own derivation), add `DeterminateSystems/magic-nix-cache-action@main`
  after the installer (GitHub Actions cache, no secret; its README documents
  429 rate-limit failures) or, when the repo has a cachix cache and token,
  `cachix/cachix-action@v17`.

Sources: https://github.com/DeterminateSystems/nix-installer-action (v23),
https://github.com/DeterminateSystems/magic-nix-cache-action,
https://github.com/cachix/install-nix-action (v31.11.5),
https://github.com/cachix/cachix-action (v17), https://github.com/actions/checkout (v7.0.1).
