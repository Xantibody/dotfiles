# Nix

Every repository this skill touches has a `flake.nix`, so this applies to all of
them, not only to repositories whose product is Nix code.

## Tools and where each runs

| Tool    | Catches                                                               | treefmt (`fmt`, `fmt-check`)                 | `just lint`      |
| ------- | --------------------------------------------------------------------- | -------------------------------------------- | ---------------- |
| nixfmt  | layout                                                                | `programs.nixfmt` rewrites                   | —                |
| deadnix | unused let bindings, lambda args, pattern names                       | `programs.deadnix` runs `deadnix --edit`     | —                |
| statix  | anti-patterns (`manual_inherit`, `useless_parens`, `empty_let_in`, …) | `programs.statix` runs `statix fix` per file | `statix check .` |

treefmt applies the fixable part; `treefmt --ci` then fails on the diff, so CI
rejects anything `nix fmt` would have changed. `statix fix` silently skips lints
it cannot rewrite, so `statix check .` in `lint` is what makes those fail
(`statix check` exits 1 on any report). Both binaries reach the devShell through
`inputsFrom = [ config.treefmt.build.devShell ]`, which carries the treefmt
wrapper plus every enabled program.

`nix flake check` also guards formatting: the treefmt-nix flake module adds
`checks.<system>.treefmt` unless `treefmt.flakeCheck = false`. It copies the
tree, runs `treefmt --no-cache` and fails on `git diff --exit-code`; it never
touches the working tree.

Sources: treefmt-nix `flake-module.nix`, `module-options.nix`,
`programs/{nixfmt,statix,deadnix}.nix`
(https://github.com/numtide/treefmt-nix); statix README and `bin/src/lint.rs`
(https://github.com/oppiliappan/statix); deadnix README
(https://github.com/astro/deadnix).

## Settings

- **nixfmt**: defaults (width 100, indent 2). That is the RFC 166 style nixpkgs
  itself is formatted with. Do not set `width` or `indent`. `strict = true`
  exists (less influenced by the input's line breaks); turn it on only in a repo
  with no Nix history to reformat. The nixpkgs attribute is `pkgs.nixfmt`
  (`pkgs/by-name/ni/nixfmt`); treefmt-nix already uses it. `nixfmt-rfc-style`
  is now a warning alias for it and `nixfmt-classic` throws; replace either
  where a repo still names it.
- **deadnix**: no flags. `no-lambda-arg`, `no-lambda-pattern-names` and
  `no-underscore` each turn a whole class of checks off. The one legitimate
  case is `no-lambda-pattern-names` for `callPackage`-style package files,
  whose argument names are the injection list; if the repo has those, exclude
  only those files (below) rather than setting the flag tree-wide.
- **statix**: all lints on (`disabled-lints = [ ]`, no `statix.toml`).
- **nixf-diagnose** (`programs.nixf-diagnose`; a wrapper around nixd's
  `nixf-tidy`, https://github.com/inclyc/nixf-diagnose) is available in
  treefmt-nix with `autoFix` on by default. Optional; add it only when the repo
  has enough Nix for its semantic checks to pay off.

## Escape hatches and how to close them

| Hatch                                                                                                               | Scope                        | Rule                                                                             |
| ------------------------------------------------------------------------------------------------------------------- | ---------------------------- | -------------------------------------------------------------------------------- |
| `# deadnix: skip`                                                                                                   | the binding on the next line | Allowed only with `HACK(<issue URL>)` on the line directly above the pragma      |
| `statix.toml` `disabled = [ … ]`                                                                                    | one lint, whole tree         | Each entry needs a `# HACK(<issue URL>): …` TOML comment above it                |
| `statix.toml` `ignore = [ … ]`                                                                                      | whole files                  | Same; prefer this over `disabled` for generated files (`Cargo.nix`, `_sources/`) |
| `programs.<name>.excludes` / `settings.excludes` in `treefmt` (`settings.global.excludes` is the old, renamed name) | files                        | Generated files only; name the generator in a comment                            |
| deadnix `--exclude`                                                                                                 | files                        | Do not use; pass excludes through treefmt instead so there is one list           |

statix has no inline suppression comment; `statix.toml` is the only off switch,
which makes it easy to review. Keep it that way. (`ignore` is not in the
README; it is a field of `ConfFile` in `bin/src/config.rs`, and `statix dump`
writes `ignore = [".direnv"]`.)

When `statix.toml` exists, the treefmt run and `statix check` must read the
same list, because treefmt-nix passes `--config` with a generated file and
ignores the repo's `statix.toml`:

```nix
programs.statix =
  let
    conf = pkgs.lib.importTOML ./statix.toml;
  in
  {
    enable = true;
    disabled-lints = conf.disabled or [ ];
    excludes = conf.ignore or [ ];
  };
```

(`programs.<name>.excludes` takes treefmt globs relative to the tree root;
check that each statix `ignore` glob means the same there.)

Guard the deadnix pragma in `lint` so the error says what to do:

```just
lint:
    statix check .
    git ls-files -z '*.nix' | xargs -0 awk 'FNR == 1 { prev = "" } /#[[:space:]]*deadnix:[[:space:]]*skip/ && prev !~ /HACK\(https?:\/\// { printf "%s:%d: deadnix: skip needs a HACK(<issue URL>) comment on the line above. Prefer deleting the binding.\n", FILENAME, FNR; bad = 1 } { prev = $0 } END { exit bad }'
```

## Mature repository

- nixfmt: reformat everything in one commit of its own (`style(nix): format
  with nixfmt`), then add its SHA to `.git-blame-ignore-revs`. Formatting is
  mechanical; no ratchet.
- deadnix and statix fixables: run `nix fmt` again after the format commit and
  commit what `deadnix --edit` and `statix fix` changed as a separate commit.
  Read the deadnix diff before committing: removing an argument from a
  `callPackage` file breaks `.override { thatArg = …; }` callers.
- statix non-fixables: usually few; fix them by hand. If a file cannot be
  fixed now, list it under `statix.toml` `ignore` with a HACK issue rather than
  disabling the lint tree-wide.
