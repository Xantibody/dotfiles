# Survey tests

One section per step. **Done** lists the tests that must all pass; **Partial**
lists the shapes that mean the step was started but does not hold yet. Anything
else is **missing**. Absorbing what a partial step already has is the
procedure's job (`absorb.md`), not the survey's.

The formatter check and `just check` can rewrite files (`treefmt --ci` formats
before it fails). Run them only on a clean tree (`git status --porcelain` is
empty); on a dirty tree mark the step `unknown` and say why. A diff they leave
is evidence for the row — report `git diff --stat` and leave it in place for
`baseline` to commit.

## 1. devShell and direnv

**Done** when all hold:

```sh
git ls-files --error-unmatch flake.nix flake.lock
grep -rqE 'devShells?\b' --include='*.nix' .
grep -qE '^[[:space:]]*use (flake|devenv)\b' .envrc
grep -qxE '/?\.direnv/?' .gitignore
nix develop --command true
```

**Partial** looks like: `flake.nix` with packages but no devShell; `flake.nix`
untracked (a flake in a git repo sees only tracked files, so `nix develop`
reports the path as missing; `git add` it, staging is enough); no `flake.lock`;
`.envrc` missing or still `use nix`; `.direnv/` not ignored; a
`devShell.<system>` output (the pre-`devShells` name).

## 2. `nix fmt` through treefmt-nix

**Done** when:

```sh
grep -qE 'treefmt-nix' flake.nix
grep -rqE 'nixfmt\.enable|alejandra\.enable|nixpkgs-fmt\.enable' --include='*.nix' .
nix develop --command treefmt --version
nix build --no-link ".#checks.$(nix eval --raw --impure --expr builtins.currentSystem).treefmt"
```

The last test builds treefmt-nix's flake check, which formats a copy of the
tree and fails on a diff, so it never touches the working tree. It sees only
files git tracks.

**Partial**: `formatter = pkgs.nixfmt…` or `pkgs.alejandra` (only `.nix` files
are covered); a standalone `treefmt.toml` (works, but no Nix pins the
formatters); treefmt-nix without the wrapper in the devShell (add
`inputsFrom = [ config.treefmt.build.devShell ]`); a language's files left
unformatted while a formatter config for them exists.

## 3. `just check`

**Done** when:

```sh
nix develop --command just --summary | tr ' ' '\n' | grep -qx check
nix develop --command just check
```

and `just --show check` (plus the recipes it depends on) runs a format check,
lint, type check (when the stack has one) and the tests, and nothing in them
swallows a failure:

```sh
for r in $(just --summary); do just --show "$r"; done \
  | grep -nE '\|\| *true|^ *-[^-]|--exit-zero|continue-on-error|--max-warnings[ =]*[1-9]|; *exit 0'
```

A hit there is `partial`. In a justfile, a recipe line starting with `-`
ignores its exit code.

**Partial**: a justfile without `check`; `check` that skips formatting or lint;
the placeholder `echo … exit 1` lines from `assets/justfile` still present in
`check` or a recipe it depends on (`run` and `smoke` are step 8's);
lint configs below the stack reference's strict defaults or missing what `nix.md` and `repo-wide.md` add (the deadnix guard, zizmor, typos); a recipe that needs a
step the README tells humans to do first (`npm ci`) instead of depending on it.

## 4. CI

Find the default branch first:
`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
(offline: `git symbolic-ref --short refs/remotes/origin/HEAD`, which prints
`origin/<branch>`; drop the `origin/`). Workflow files
cannot read it, so write it into `on.push.branches`.

**Done** when one workflow under `.github/workflows/` has all of:

```sh
f=$(grep -lE 'nix develop.*just check' .github/workflows/*.y*ml)
grep -qE '^\s*pull_request:' "$f"
grep -qE '^\s*push:' "$f" && grep -qE "branches:.*\b<default>\b" "$f"
! grep -qE 'paths(-ignore)?:' "$f"
grep -qE 'fetch-depth: *0( |$)' "$f"
grep -qE '^\s*LINT_BASE:' "$f"
```

**Partial**: CI runs `npm test` / `cargo test` / setup-* actions directly
(a second, drifting copy of step 3); CI runs only `nix flake check` (formatting
only, unless the flake wires lint and tests into `checks`); only one trigger;
a shallow checkout or no `LINT_BASE` (a ratchet recipe then has no base to
compare against: `assets/check.yml` sets both);
path filters on what is, or will be, a required check (a PR outside the paths
never reports and can never merge).

## 5. Architecture map

Look for the map at `docs/architecture.md`, `ARCHITECTURE.md`,
`docs/introduction.md`, `doc/`, or an "Architecture" heading in the README.

**Done** when one map exists with a codemap (the top-level components and the
dependencies between them) and a rules section that names the checks step 3
enforces.

**Partial**: a map without a rules section, or whose rules name no check; two
maps that disagree; a map that names directories the repo no longer has.

## 6. Decision records

Look for the directory at `.adr-dir` (its content is the path), `docs/adr/`,
`doc/adr/`, `docs/decisions/`, `doc/architecture/decisions/`, `adr/`, and for a
template at `<dir>/template.md`, `<dir>/templates/template.md` or
`<dir>/adr-template.md`. `## Considered Options` / `## Decision Outcome`
headings mean MADR; a `## Status` heading means Nygard / adr-tools.

**Done** when the directory exists and holds a template. No record is required:
records are written when a decision is made, never in advance.

**Partial**: records without a template; a template without an `Enforced by`
section (or MADR's equivalent added); file names that break the directory's own
numbering.

## 7. Dependency updates

Look for `renovate.json`, `renovate.json5`, `.github/renovate.json5`,
`.renovaterc*`, or a `renovate` key in `package.json`, and for
`.github/dependabot.yml`.

**Done** when a Renovate config exists, extends `config:recommended`, has the
nix manager on (`nix: { enabled: true }`) so `flake.lock` is tracked, and sets
`mode: "full"`.

**Partial**: Renovate without the nix manager (`flake.lock` never moves);
Dependabot only (it does not update `flake.lock`); Renovate and Dependabot both
on the same ecosystem (duplicate PRs).

## 8. Run and smoke

Look for the run skill at `.claude/skills/*-run/SKILL.md`; `<name>` below is
its directory name.

**Done** when all hold:

```sh
nix develop --command just --summary | tr ' ' '\n' | grep -qx run
nix develop --command just --summary | tr ' ' '\n' | grep -qx smoke
nix develop --command just smoke
test -f .claude/skills/<name>/references/features.md
test -f .agents/skills/<name>/SKILL.md
```

and `just --show smoke` starts the app itself (it does not assume one is
already running) and drives the rows under the feature map's smoke section,
which holds a few rows, not the whole map. Do not run `just run` for the
survey: it stays in the foreground, and `just smoke` passing already shows the
app starts. A broken smoke row must make `just smoke` exit non-zero, so the
swallow check of step 3 applies to it too.

**Partial**: `run` or `smoke` still the placeholder from `assets/justfile`;
a `smoke` that only checks the process started and drives no feature-map row;
a run skill without `references/features.md`, or a feature map without the
three columns (feature, how to reach it, what to see); the skill only under
`.claude/skills/` (codex cannot find it) or only under `.agents/skills/`
(Claude Code does not read that path); a run skill named `run` or `verify`,
which the built-in skills of the same name shadow.
