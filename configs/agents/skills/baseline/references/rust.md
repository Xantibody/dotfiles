# Rust

Load this when the survey finds a `Cargo.toml`. It fills in the Rust parts
of steps 1–4.

## Survey

Find these before you change anything. Each one you find is something to
absorb, not something to replace:

| Found                                                                                 | Means                                                                |
| ------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `rust-toolchain.toml` / `rust-toolchain`                                              | toolchain is pinned → use the rust-overlay devShell variant          |
| `[lints]` / `[workspace.lints]` in Cargo.toml                                         | merge the defaults below into it; never lower a level it sets        |
| `#![deny(...)]` / `#![warn(...)]` in lib.rs/main.rs                                   | move them into `[lints]` in the same commit, then delete them        |
| `clippy.toml` / `.clippy.toml`                                                        | merge keys; keep its `disallowed-*` entries                          |
| `deny.toml` / `.deny.toml` (also under `.cargo/`; `.config/` since cargo-deny 0.21.0) | cargo-deny is already adopted → wire it into `just`                  |
| `.config/nextest.toml`                                                                | nextest is already adopted → use the nextest test recipe             |
| `rust-version` in Cargo.toml                                                          | MSRV. Below 1.81, `reason =` and `#[expect]` don't exist (see Lints) |
| `[workspace]` with `members`                                                          | put lints in `[workspace.lints]`; members inherit them               |
| `[lints.rustdoc]` / `missing_docs` / `[package.metadata.docs.rs]`                     | the crate documents itself → doc lints and `lint-rust-doc` apply     |

## 1. devShell

Default: the toolchain from nixpkgs. It needs no extra input, comes from the
binary cache, and is the same `rustc` that `nix fmt` and any Nix build use.

```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    cargo
    rustc
    clippy
    rustfmt
    rust-analyzer # wrapper already sets RUST_SRC_PATH to rustPlatform.rustLibSrc
    just
    ripgrep # lint-rust-inner-allow recipe
    cargo-deny # only if step "cargo-deny" applies
    # cargo-nextest  # only if the repo already uses nextest
  ];
};
```

All attributes were checked in the nixpkgs tree on 2026-11-17. `cargo`,
`clippy`, `rustc` and `rustfmt` come from `rustPackages` (Rust 1.99 in
`pkgs/top-level/all-packages.nix`). `rust-analyzer`, `cargo-deny`,
`cargo-nextest`, `cargo-hack`, `cargo-llvm-cov`, `taplo`, `just` and
`ripgrep` live under `pkgs/by-name`. The `rust-analyzer` wrapper sets
`RUST_SRC_PATH` itself with `--set-default`
(`pkgs/by-name/ru/rust-analyzer/package.nix`), so do not export it again.

Use the variant below only when the repo already has a `rust-toolchain.toml`
(rustup users and CI depend on it), or when the user needs nightly or a
cross target. Pick **rust-overlay** over fenix. `fromRustupToolchainFile`
takes the file as it is, while fenix's `fromToolchainFile` needs a `sha256`
in pure evaluation and that hash has to be bumped on every toolchain change.

```nix
# flake.nix inputs
rust-overlay = {
  url = "github:oxalica/rust-overlay";
  inputs.nixpkgs.follows = "nixpkgs";
};

# perSystem (flake-parts): replace pkgs with the overlaid one
_module.args.pkgs = import inputs.nixpkgs {
  inherit system;
  overlays = [ inputs.rust-overlay.overlays.default ];
};
# toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
# devShell packages: [ toolchain pkgs.just ... ]  (no separate cargo/clippy/rustfmt)
```

```toml
# rust-toolchain.toml — the components the devShell and rustup users both need
[toolchain]
channel = "1.99.0"
components = ["rustfmt", "clippy", "rust-analyzer", "rust-src"]
```

## 2. Formatting (treefmt-nix)

```nix
treefmt.programs.rustfmt = {
  enable = true;
  edition = "2024"; # must equal `edition` in Cargo.toml; the module passes --edition
  # package = toolchain;  # rust-overlay variant only, so fmt and clippy agree
};
treefmt.programs.taplo.enable = true; # optional: formats Cargo.toml and deny.toml
```

`programs.rustfmt` takes `edition` (default `"2024"`) and runs
`rustfmt --config skip_children=true --edition <edition>` on `*.rs`. The
`package` option (default `pkgs.rustfmt`) is defined for every program by
`mkFormatterModule`, which runs `${package}/bin/rustfmt` (the module sets
`mainProgram = "rustfmt"`). An overlay toolchain therefore works as
`package` as long as its components include `rustfmt`.
Keep any existing `rustfmt.toml`, since rustfmt still reads it. Do not also
put `cargo fmt --check` in `just check`. The shared format check already
covers Rust, and a second formatter can disagree with the first.

## 3. Lints

### Cargo.toml

Groups get `priority = -1` so that single lints override them. If a group
and a lint share a priority, clippy's `lint_groups_priority` (correctness)
fires. Levels follow this split:

- **warn**: style and quality lints. `just check` passes `-D warnings`, so
  they still fail the gate, but a half-finished Red step still compiles
  in the editor.
- **deny / forbid**: escape hatches. You never need one mid-task, and the
  editor marks them red right away.

Never set `warnings = "deny"` in Cargo.toml. It blocks the Red step of TDD
on a single unused variable.

```toml
[lints.rust]
unsafe_code = "forbid" # forbid: cannot be #[expect]ed away
rust_2018_idioms = { level = "warn", priority = -1 }
let_underscore_drop = "warn" # not the `let_underscore` group: it would lower deny-by-default let_underscore_lock
unused_qualifications = "warn"

[lints.clippy]
# No `all = "warn"`: the default set is already on, and `all` would lower
# the deny-by-default `correctness` group to warn.
pedantic = { level = "warn", priority = -1 }
# Escape hatches: only #[expect(lint, reason = "...")] survives.
allow_attributes = "deny" # #[allow] → #[expect]; unfulfilled expect then warns
allow_attributes_without_reason = "deny" # every allow/expect needs `reason = "..."`
undocumented_unsafe_blocks = "deny" # matters only if unsafe_code is relaxed to deny
unwrap_used = "deny" # use `?`, or .expect("<invariant>") which carries its reason
let_underscore_must_use = "deny" # `let _ = fallible()` silently drops a Result
as_conversions = "deny" # use From / TryFrom; casts truncate silently
dbg_macro = "deny"
todo = "deny"
unimplemented = "deny"
panic = "deny" # return an error; tests are exempt via clippy.toml
# Library crates only (a binary prints by design):
# print_stdout = "deny"
# print_stderr = "deny"
```

In a workspace, write the same tables as `[workspace.lints.rust]` and
`[workspace.lints.clippy]` in the root manifest, and give every member

```toml
[lints]
workspace = true
```

A member cannot combine `workspace = true` with lints of its own: Cargo
fails with "cannot override `workspace.lints` in `lints`" (Cargo's
`tests/testsuite/lints_table.rs`, `workspace_and_package_lints`). Put a
per-crate difference (for example `print_stdout` only on the library
crates) in that crate's `lib.rs` as `#![deny(clippy::print_stdout)]`.

Notes on the choices:

- `expect_used` stays off. The message in `.expect("...")` is the reason
  the philosophy asks for, the same idea as `reason =` on an attribute.
  `unwrap_used` has no message, so it is denied.
- `allow_attributes` checks only outer `#[allow]`. It ignores inner
  `#![allow]` and anything written inside macros. Inner `#![allow]` still has to
  carry a `reason` (`allow_attributes_without_reason`), and the
  `lint-rust-inner-allow` recipe below closes the rest of the gap.
- Both `allow_attributes*` lints are gated on MSRV 1.81, when `#[expect]`
  and `reason =` were stabilized. Below that `rust-version` they silently
  do nothing. Raise `rust-version`, or tell the user these two lints are
  inert.
- If the crate really needs `unsafe`, relax `unsafe_code` to `"deny"` and
  put `#[expect(unsafe_code, reason = "...")]` on each module that uses it.
  Keep `undocumented_unsafe_blocks` so every block needs a `// SAFETY:`
  comment.
- Pedantic's `missing_errors_doc` and `missing_panics_doc` fire only on
  items that already have a doc comment, so they start applying with the
  first one: write the `# Errors` / `# Panics` sections in the same change.
  In a binary-only crate you may set them to `"allow"` in Cargo.toml with a
  one-line comment. A Cargo.toml line is a reviewed config change, not an
  inline escape hatch.
- Leave out `nursery`, `restriction` as a group
  (`blanket_clippy_restriction_lints` objects to it) and `cargo`. Bans
  and duplicate versions are cargo-deny's job.
- Treat these as opt-in, for a crate whose domain calls for them. Clippy
  (`[lints.clippy]`): `indexing_slicing`, `arithmetic_side_effects`,
  `wildcard_enum_match_arm`, `exit` (libraries), `missing_assert_message`.
  rustc (`[lints.rust]`): `unreachable_pub` (libraries),
  `missing_debug_implementations`.

Doc lints are opt-in as well: for a crate published to docs.rs, a repo
the survey found already documenting itself, or when the user asks. A
plain library without either is offered them, not marked partial. The
set is the one tokio, ripgrep and rust-lang/cargo turn on, at `warn` like
every quality lint (the `-D warnings` in `lint-rust` and `lint-rust-doc` fails
the gate):

```toml
[lints.rust]
missing_docs = "warn"

[lints.rustdoc]
broken_intra_doc_links = "warn"
private_intra_doc_links = "warn"
missing_crate_level_docs = "warn"
private_doc_tests = "warn"
invalid_codeblock_attributes = "warn"
invalid_html_tags = "warn"
invalid_rust_codeblocks = "warn"
bare_urls = "warn"
unescaped_backticks = "warn"
redundant_explicit_links = "warn"

[package.metadata.docs.rs]
all-features = true
```

- `missing_docs` is a rustc lint, so `lint-rust` already catches it.
  `[lints.rustdoc]` fires only while docs build, which is what the
  `lint-rust-doc` recipe is for.
- Count the gap before turning `missing_docs` on, once per library crate:
  `touch <crate>/src/lib.rs && cargo rustc -p <crate> --lib --all-features -- -W missing_docs 2>&1 | grep -c 'missing documentation'`
  (a cached build prints nothing). Land the docs first and the lint in
  its own commit: a commit that adds both cannot be reviewed, and a lint
  landed before the docs leaves every commit until they land red.
- Never add `missing_doc_code_examples`. It is nightly-only and fails a
  stable build.

The required reason format follows the house convention:
`reason = "HACK(<issue URL>): <what to remove once it is fixed>"` for a
workaround, or a plain sentence for a permanent decision. A grep for
`HACK\(` matches anywhere on a line, so these attributes turn up with every
other anchor.

### clippy.toml

```toml
# Tests may unwrap/panic/index: a failing test is the desired outcome.
allow-unwrap-in-tests = true
allow-panic-in-tests = true
allow-indexing-slicing-in-tests = true
# Apps and unpublished crates: let clippy suggest API-changing fixes.
# Keep the default (true) for a crate published to crates.io.
avoid-breaking-exported-api = false
```

Leave `msrv` unset. Clippy reads it from `rust-version`. Keep
`allow-dbg-in-tests` and `allow-print-in-tests` at their default, `false`.

`disallowed-methods`, `disallowed-types` and `disallowed-macros` hold the
"the error names the fix" rules. Each entry takes `path`, `reason`,
`replacement` and `allow-invalid`. Add one only when the repo has a real
case: an adapter that must be used, or a wrapper that replaces a std call.
Do not seed them generically.

```toml
disallowed-methods = [
  { path = "std::env::var", reason = "config is read once in crate::config so tests can inject it", replacement = "crate::config::Config::from_env" },
]
disallowed-types = [
  { path = "std::collections::HashMap", reason = "output order must be stable", replacement = "indexmap::IndexMap" },
]
```

### cargo-deny (optional)

Adopt it when the crate ships a binary or has more than a handful of
dependencies, or when the repo already has a `deny.toml`. Generate the file
with `cargo deny init`, then tighten it:

```toml
[advisories]
unmaintained = "all" # the default; written out so nobody loosens it silently
yanked = "deny"
ignore = [
  # Every exception carries a reason and an expiry: the escape hatch closes itself.
  # `expiry` needs cargo-deny >= 0.21.0 (2026-11-16); nixpkgs has 0.20.2 on
  # 2026-11-17. On an older one, leave `expiry` out and put the date in `reason`.
  # { id = "RUSTSEC-0000-0000", reason = "HACK(<issue URL>): ...", expiry = "2027-03-01" },
]

[bans]
multiple-versions = "warn"
wildcards = "deny"

[licenses]
allow = ["MIT", "Apache-2.0"] # extend from the first `cargo deny check licenses` run
confidence-threshold = 0.93

[sources]
unknown-registry = "deny"
unknown-git = "deny"
```

Split the checks by what can make them fail:

- `bans licenses sources` change only when the code changes. They go in
  `just check`. cargo-deny loads the advisory database only when the
  `advisories` check runs. `bans` fetches std-replacement data only if
  `[bans.std-replacements]` is configured, so leave that table out of
  `check`'s config or run with `--offline`.
- `advisories` fetches the RustSec database on every run and can fail a
  PR that touched nothing. Give it its own `just audit-rust` recipe and run it
  from a scheduled workflow (and from `pull_request` when Cargo.lock
  changes). Do not put it in `check`. For an offline run, use the root
  flag: `cargo deny --offline check`. Since 0.20.0 it replaces
  `check --disable-fetch` and also disables crate fetching.

## 4. just recipes

```just
# Type-check and lint every target in every crate. Clippy runs `check`,
# so no separate `cargo check` is needed.
lint-rust: lint-rust-inner-allow lint-rust-ignore (lint-comments "//" "*.rs")
    cargo clippy --workspace --all-targets --all-features --locked -- -D warnings

# Unit, integration and doc tests. No --all-targets here: with it,
# `cargo test` skips doctests.
test-rust:
    cargo test --workspace --all-features --locked

# Inner #![allow] is invisible to clippy::allow_attributes.
lint-rust-inner-allow:
    #!/usr/bin/env bash
    set -euo pipefail
    if rg -n --glob '*.rs' '^\s*#!\[allow\(' .; then
        echo 'error: use #![expect(<lint>, reason = "HACK(<issue URL>): ...")] instead of #![allow]; expect fails once the violation is gone' >&2
        exit 1
    fi

# An ignored test names the issue for the environment it cannot run in.
lint-rust-ignore:
    #!/usr/bin/env bash
    set -euo pipefail
    if rg -n --glob '*.rs' '#\[ignore\b' . | rg -v '#\[ignore\s*=\s*"HACK\(https?://[^)\s]+\)'; then
        echo 'error: a flaky test is fixed or deleted, never ignored. A test the environment cannot run (an OS, an outside service): #[ignore = "HACK(<issue URL>): <environment>"]' >&2
        exit 1
    fi

# Docs build, only with the doc lints. Private items too: that is where
# broken intra-doc links hide.
lint-rust-doc:
    RUSTDOCFLAGS="-D warnings" cargo doc --workspace --no-deps --all-features --locked --document-private-items

# cargo-deny, offline-stable part (only if adopted)
lint-rust-deny:
    cargo deny check bans licenses sources

# Advisory DB check; network, not part of `check`
audit-rust:
    cargo deny check advisories
```

Hang `lint-rust` (and `lint-rust-deny`, and `lint-rust-doc` with the doc
lints) under the shared `lint`, and `test-rust` under `test`. Rust has no
separate type check: clippy compiles every target, so a Rust-only
repository drops `typecheck` from `check`. Formatting comes from the
shared format step.

- `lint-rust-ignore`: `#[ignore]` takes a free-text reason, so nothing else
  stops a flaky test from being ignored. Only an environment the test cannot
  run in earns the HACK form. A slow test leaves `check` as its own test
  target (`[[test]] name = "slow"` with `test = false`, run by `test-slow`
  as `cargo test --test slow`), not through `#[ignore]`.
- Property tests: proptest as a dev-dependency, its `proptest!` tests run by
  `test-rust` like any other, so no recipe is added. Commit the
  `proptest-regressions/` files it writes on a failure: they replay the
  shrunk case first on every later run.
- `--workspace`: when the root manifest is also a package, a bare `cargo`
  command acts only on that root package.
- `--all-features`: if features are mutually exclusive, this fails to
  compile. Then list the feature sets explicitly, or use `cargo hack
  --each-feature` (`pkgs.cargo-hack`). Don't drop the flag silently.
- `--locked`: CI must not rewrite Cargo.lock. Commit Cargo.lock for
  libraries too.
- `-D warnings` comes after `--`, so it reaches only workspace crates.
  Setting it through `RUSTFLAGS` would also invalidate the build cache.
  It does not override `forbid`.
- nextest, only if the repo already uses it:
  `cargo nextest run --workspace --all-features --locked`, followed by
  `cargo test --doc --workspace --all-features --locked`. nextest does not
  run doctests, and it accepts all of `cargo test`'s options, `--locked`
  included (https://nexte.st/docs/running/). Since 0.9.85 a run that finds
  no tests fails by default (`--no-tests=auto`, exit code 4). In a repo with
  no tests yet, pass `--no-tests=warn` until the first test lands.

## Ratchet: existing violations

Clippy has no baseline file and cannot report only new violations. Run
`cargo clippy --workspace --all-targets --all-features --message-format=json`
once and count the hits per lint and per file. The counts decide which
approach to use:

1. **Fix everything in one commit.** This is the default when the total is
   small or mostly machine-fixable. First run
   `cargo clippy --fix --allow-dirty --workspace --all-targets --all-features`,
   which applies only MachineApplicable suggestions, then fix the rest by
   hand. Commit it as a structural change on its own (Tidy First), separate
   from the commit that adds `[lints]`.
2. **Per-file `#![expect]`.** Use this when there are too many to fix in
   one commit. At the top of each file that has violations, add one inner
   attribute that lists that file's lints:
   `#![expect(clippy::unwrap_used, clippy::as_conversions, reason = "HACK(<issue URL>): pre-baseline violations; remove each lint once this file is clean")]`.
   This is a real ratchet. New files and clean files get the full rules.
   Once a listed lint no longer fires in that file,
   `unfulfilled_lint_expectations` warns, and `-D warnings` fails until
   the entry is removed. The limit: inside a listed file, new violations
   of the listed lints are not caught. Open a single tracking issue and
   use its URL in every attribute. Generate the attributes from the JSON
   with a throwaway Go program. Group by the primary span's `file_name`
   and by `message.code.code` where `reason == "compiler-message"`. An
   expectation that holds in one target or feature set but not another
   (for example code only under `cfg(test)`) is reported as unfulfilled
   in the other one. Fix those hits first, or scope the expectation with
   `#![cfg_attr(not(test), expect(...))]` (UNVERIFIED: reasoned from how
   `cfg_attr` expands, not tested).
3. **Per-lint staging.** Use this when a single lint has hundreds of hits
   across the codebase (typically a pedantic lint). Set that lint to
   `"allow"` in Cargo.toml with a `# HACK(<issue URL>)` comment. Then turn
   one lint on per commit: fix its hits and delete the line. Be honest
   with the user: until a staged lint is flipped, new violations of it
   are not caught at all. This is the weakest of the three, so prefer 2
   whenever the hits cluster in a few files.

With approach 2, a change can add a lint to a file's `#![expect]`, or a new
`#![expect]` to a clean file, and clippy passes: the attribute carries a
HACK URL, which is all the escape-hatch rules ask of it. `lint-rust-expect`
lists every lint named in an inner `#![expect(...)]` per file, at the base
the Go ratchet uses (`LINT_BASE` in CI, else the merge-base with
`origin/<default>`) and in the working tree, and fails on any pair the base
did not have. Hang it under `lint-rust` once the first `#![expect]` lands;
`default_branch` is the Go reference's variable, set once at the top of the
justfile.

```just
# Per-file #![expect] lists may only shrink against LINT_BASE (CI) or the merge-base (local)
lint-rust-expect:
    #!/usr/bin/env bash
    set -euo pipefail
    base="${LINT_BASE:-$(git merge-base HEAD origin/{{ default_branch }})}"
    if ! git cat-file -e "$base^{commit}" 2> /dev/null; then
        echo "lint-rust-expect: base $base is not in this clone; CI needs actions/checkout with fetch-depth: 0" >&2
        exit 1
    fi
    # stdin: one file; prints "<file> <lint>" for each lint in an inner expect, rustfmt-wrapped or not
    lints() {
        tr '\n' ' ' | { grep -oE '#!\[[^]]*expect\([^]]*\]' || true; } \
            | sed -E 's/.*expect\(//; s/reason *=.*//' \
            | { grep -oE '[A-Za-z_][A-Za-z0-9_]*(::[A-Za-z_][A-Za-z0-9_]*)*' || true; } \
            | awk -v f="$1" '{ print f, $0 }'
    }
    old=$({ git grep -l -F '#![' "$base" -- '*.rs' || true; } \
        | while IFS= read -r s; do git show "$s" | lints "${s#*:}"; done | sort)
    new=$({ git grep -l --untracked -F '#![' -- '*.rs' || true; } \
        | while IFS= read -r p; do lints "$p" < "$p"; done | sort)
    added=$(comm -13 <(printf '%s\n' "$old") <(printf '%s\n' "$new") | grep . || true)
    if [ -n "$added" ]; then
        printf '%s\n' "$added"
        echo "These #![expect] entries are new since $base. Fix the new violation instead; a file's #![expect] list only goes down."
        exit 1
    fi
```

A file renamed while it still has an `#![expect]` counts as new under its
new name: clean it before the rename. The recipe lives in the justfile the
same change can edit, so it holds only while edits to the justfile are
reviewed. Approach 3 has no such guard: a new `"allow"` line in Cargo.toml
is caught only by review.

Never apply `#![allow]` or `"allow"` across the whole crate just to make
`just check` pass, and never lower an existing level. Report the counts
and the approach you chose to the user.

## Sources

- Cargo `[lints]`, priority: https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section
- `[workspace.lints]`: https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table
- `workspace = true` plus own lints is an error: https://github.com/rust-lang/cargo/blob/master/tests/testsuite/lints_table.rs
- `cargo test --all-targets` excludes doctests: https://doc.rust-lang.org/cargo/commands/cargo-test.html#target-selection
- rustc lint groups: https://doc.rust-lang.org/rustc/lints/groups.html
- rustc allowed-by-default lints: https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html
- Clippy lint list: https://clippy.rust-lang.org/master/index.html
- Clippy lint names (checked 2026-11-17): https://github.com/rust-lang/rust-clippy/blob/master/clippy_lints/src/declared_lints.rs
- `allow_attributes*` behavior and MSRV gate: https://github.com/rust-lang/rust-clippy/blob/master/clippy_lints/src/attrs/mod.rs , https://github.com/rust-lang/rust-clippy/blob/master/clippy_lints/src/attrs/allow_attributes.rs , https://github.com/rust-lang/rust-clippy/blob/master/clippy_utils/src/msrvs.rs (`LINT_REASONS_STABILIZATION` = 1.81.0)
- Clippy group default levels (`correctness` is deny): https://github.com/rust-lang/rust-clippy/blob/master/README.md
- clippy.toml options: https://doc.rust-lang.org/clippy/lint_configuration.html
- treefmt-nix rustfmt: https://github.com/numtide/treefmt-nix/blob/main/programs/rustfmt.nix
- nixpkgs Rust attributes: https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/all-packages.nix , https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ru/rust-analyzer/package.nix
- rust-overlay: https://github.com/oxalica/rust-overlay
- fenix: https://github.com/nix-community/fenix
- cargo-deny: https://embarkstudios.github.io/cargo-deny/checks/cfg.html , https://embarkstudios.github.io/cargo-deny/checks/advisories/cfg.html , https://embarkstudios.github.io/cargo-deny/cli/check.html
- cargo-deny `--offline` (root flag, replaced `--disable-fetch` in 0.20.0), `expiry` (0.21.0), config search path: https://github.com/EmbarkStudios/cargo-deny/blob/main/CHANGELOG.md , https://github.com/EmbarkStudios/cargo-deny/pull/881 , https://github.com/EmbarkStudios/cargo-deny/blob/main/src/cargo-deny/check.rs , https://github.com/EmbarkStudios/cargo-deny/blob/main/src/cargo-deny/common.rs
- nixpkgs cargo-deny version: https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ca/cargo-deny/package.nix
- nextest and doctests: https://nexte.st/docs/running/
- proptest (failure persistence in `proptest-regressions/`): https://proptest-rs.github.io/proptest/proptest/failure-persistence.html
