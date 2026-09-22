---
name: rustdoc
description: Write and enforce rustdoc for a Rust crate — audit which public items are undocumented, write item and crate-level docs the way the Rust Book and the API Guidelines describe, and wire up the lints, justfile recipe and CI job that keep them from rotting.
when_to_use: When documenting a Rust crate or changing its doc comments — "rustdoc 書いて", "doc コメント直して", "pub 項目のドキュメント", "docs.rs に出す", "cargo doc 通して", "missing_docs" — and before adding a public item to a crate that already denies missing docs.
---

# rustdoc

Two jobs, in this order: write the docs, then make the toolchain refuse the
next undocumented item. Doing only the first leaves a crate that decays back
within a release.

## 1. Audit

Measure before writing, so the report has a number in it.

```bash
# How many public items carry nothing. A cached build prints nothing —
# touch the crate root first.
touch src/lib.rs
cargo rustc --lib --all-features -- -W missing_docs 2>&1 | grep -c 'missing documentation'

# What rustdoc itself objects to: broken links, malformed code blocks.
RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features --document-private-items

# How many doctests exist today.
cargo test --doc --all-features

# Doc comments in a language the rest of the repo does not use.
rg -n '^\s*//[/!].*[ぁ-んァ-ヶ一-龥]' src
```

Note also whether Clippy pedantic is on. `missing_errors_doc` and
`missing_panics_doc` only fire on items that already have docs, so they start
applying the moment the first doc comment lands — budget for `# Errors`
sections in the same change, not a follow-up.

## 2. Write

### Shape of an item doc

- First line is one sentence naming what the item **is**, ending in a period.
  It is what shows up in the module index, on its own, so it has to stand
  alone. Blank `///` line, then the detail.
- Prefer a noun phrase for types and a third-person verb for functions
  ("Number of cards left in the deck", "Reports whether the deck is empty").
- Struct fields and enum variants get one sentence each. Resist the urge to
  restate the type: `/// Player who owns the card.` beats `/// The owner.`
- Section order, all optional: `# Examples`, `# Errors`, `# Panics`,
  `# Safety`.
- Link with intra-doc links — ``[`Type::method`]`` — never a bare path in
  backticks. A link that moves with a rename is the point. For a path that is
  long or ambiguous, use the reference form:

  ```rust
  /// See [`GameState`] for the shared zones.
  ///
  /// [`GameState`]: crate::game::GameState
  ```

- Keep the rationale that is already in the code. "Why `Vec` and not
  `HashSet`" belongs in the field's doc if a caller's choice depends on it;
  "why not the obvious refactor" is an anchor comment and belongs in `//`
  above the item, out of the rendered page.
- `#[doc(hidden)]` for items that are public only because a macro needs them.

### Container docs

- `//!` at the top of the file documents the module. Every public module gets
  one paragraph: what lives here, and intra-doc links to the two or three
  types a reader should start from.
- The crate root is `#![doc = include_str!("../README.md")]` when the README
  is a good introduction — one text, checked by one set of doctests, shown
  identically on GitHub and docs.rs. Its examples become doctests, so they
  now have to compile.

### Examples

`# Examples` goes on the crate, every module, and any function whose behaviour
is not obvious from its signature — accessors that answer a rules question,
anything encoding a convention (which end of the `Vec` is the top), anything
with a surprising `None`. A pure `len()` does not need one.

- Fail with `?`, not `unwrap()` (API Guidelines C-QUESTION-MARK), hiding the
  scaffolding:

  ````rust
  /// # Examples
  ///
  /// ```
  /// use my_crate::Thing;
  ///
  /// # fn main() -> Result<(), my_crate::ThingError> {
  /// let thing = Thing::builder().name("x").build()?;
  /// assert_eq!(thing.name(), "x");
  /// # Ok(())
  /// # }
  /// ```
  ````

  The error type needs `Debug`, not `Display` — `Termination` only requires
  `Debug` — so this works before the crate has an `Error` impl.

- **Exception:** a README included with `include_str!` may use `unwrap()`.
  Hidden `#` lines are invisible on GitHub, where the same text is read as
  prose; a `?` with no visible `main` reads as a mistake there.
- Assert something. An example that only constructs a value proves nothing
  when it runs as a doctest.
- ` ```ignore ` is a last resort and needs a reason next to it;
  ` ```no_run ` for something that compiles but should not execute, and
  ` ```text ` for a non-Rust block, which also stops rustdoc trying to
  compile it.

## 3. Enforce

Nothing above survives contact with the next PR unless the build fails
without it.

`Cargo.toml`:

```toml
[lints.rust]
missing_docs = "deny"

[lints.rustdoc]
broken_intra_doc_links = "deny"
private_intra_doc_links = "deny"
missing_crate_level_docs = "deny"
private_doc_tests = "deny"
invalid_codeblock_attributes = "deny"
invalid_html_tags = "deny"
invalid_rust_codeblocks = "deny"
bare_urls = "deny"
unescaped_backticks = "deny"
redundant_explicit_links = "deny"

[package.metadata.docs.rs]
all-features = true
```

`missing_docs` is a rustc lint, so an existing `cargo clippy` or `cargo check`
job catches it with no new CI step. `[lints.rustdoc]` only fires while
building docs, which is what the recipe and the job below are for.

Do **not** add `missing_doc_code_examples`: it is nightly-only and will fail
a stable build.

`justfile`:

```just
# Build docs, failing on any rustdoc warning
doc:
    RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features --document-private-items

check: lint format-check test doc
```

`--document-private-items` is what tokio, ripgrep and rust-lang/cargo pass:
it checks links in private items too, which is where broken ones hide.

CI job, matching the recipe:

```yaml
doc:
  name: Doc
  runs-on: ubuntu-latest
  env:
    RUSTDOCFLAGS: -D warnings
  steps:
    - uses: actions/checkout@v4
    - uses: dtolnay/rust-toolchain@stable
    - uses: Swatinem/rust-cache@v2
    - run: cargo doc --no-deps --all-features --document-private-items
```

Doctests are run by `cargo test`, so an existing test job already covers them.

Land the lints **after** the docs, in their own commit. A lint commit that
also has to add two hundred doc comments cannot be reviewed, and every commit
before it is red.

## Language

Match the repository, the same rule as any other prose: read the README and
the last twenty commit subjects. A crate whose README and history are English
gets English rustdoc even when the conversation is Japanese. Anchor comments
(`AIDEV-NOTE:`, `HACK(<url>):`) are the exception — they are notes to the next
session, stay in the language the user writes, and belong in `//` above the
item so they never reach the rendered page.

## Sources

- The Rust Book, ch. 14.2 "Publishing a Crate to Crates.io" — `///`, `//!`,
  the conventional sections, doctests, `pub use` for a flat public API
- Rust API Guidelines, "Documentation" — C-CRATE-DOC, C-EXAMPLE,
  C-QUESTION-MARK, C-FAILURE, C-LINK, C-METADATA, C-RELNOTES, C-HIDDEN
- The rustdoc book, "Lints" — which of them are stable
- tokio, serde, ripgrep, rust-lang/cargo — the deny sets and CI steps above
  are theirs
