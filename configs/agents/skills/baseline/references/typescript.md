# TypeScript / JavaScript

Read this when the repository has a `package.json` or `tsconfig.json`.
Versions below are what nixos-unstable (and npm/GitHub, where they differ)
carried on 2026-11-17: TypeScript 7.0.2 (the Go port, binary `tsc`; same on
npm), oxlint 1.91.0 with tsgolint 7.0.2006 (upstream: oxlint 1.94.0, tsgolint
7.0.2007), oxfmt 0.75.0 (upstream 0.79.0), Node 24 as nixpkgs' default, Vitest
5.1.0 (npm).

## State of the toolchain (late 2026)

- **TypeScript 7.0** shipped 2026-07-08. It is the Go port formerly called
  tsgo / typescript-go, published as the normal `typescript` package with a
  `tsc` binary. It has **no programmatic API**; one is planned for 7.1, which
  has not shipped (npm `latest` is 7.0.2). nixpkgs renamed `typescript-go` to
  `typescript` and builds `cmd/tsgo` into `bin/tsc`.
- **typescript-eslint does not support TS 7.** Its peer range is
  `typescript >=4.8.4 <6.1.0` (8.73.0), and maintainers say nothing can be
  done until TS 7 ships an API (#12518, closed as not planned; tracking issue
  #10940, open). A repo on ESLint + typescript-eslint keeps TS 6 in
  `node_modules` for the linter.
- **oxlint type-aware linting is stable** (2026-07-22). It runs tsgolint, built
  on typescript-go; the tsgolint README's rule list marks 60 of 62 targeted
  typed rules done (only `naming-convention`, `prefer-destructuring` missing),
  including `no-unsafe-argument/assignment/call/member-access/return/type-assertion`,
  `strict-boolean-expressions`, `switch-exhaustiveness-check`,
  `no-floating-promises`, `no-misused-promises`. Not every typescript-eslint
  typed rule is targeted: `no-unsafe-class-instance-assignment` (in
  `strictTypeChecked`) has no oxlint port.

Default for a repo with no linter: **oxlint (type-aware) + tsc 7 + oxfmt +
Vitest.** A repo already on ESLint keeps ESLint (absorb, see ESLint path).

## Survey

| Found                                                                                                                                                                                                                                              | Do                                                                                                                                                                                       |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.oxlintrc.json(c)` / `oxlint.config.ts`                                                                                                                                                                                                           | Keep every rule and override; add the missing baseline rules below. Never weaken a rule the repo set                                                                                     |
| `eslint.config.*` / `.eslintrc*`                                                                                                                                                                                                                   | ESLint path. Legacy `.eslintrc*`: migrate to flat config in its own commit first (`npx @eslint/migrate-config`)                                                                          |
| `biome.json` lint section                                                                                                                                                                                                                          | Keep Biome as the linter only if the repo has no type-aware need; otherwise add oxlint for typed rules and turn the overlapping Biome rules off. Do not run two linters on the same rule |
| `.prettierrc*` / `biome.json` formatter                                                                                                                                                                                                            | Formatting below: keep that formatter in treefmt, or migrate to oxfmt in one `style:` commit                                                                                             |
| `tsconfig.json` with `baseUrl`, `moduleResolution: node`/`node10`/`classic`, `esModuleInterop: false`, `allowSyntheticDefaultImports: false`, `alwaysStrict: false`, `target: es5`, `downlevelIteration`, `outFile`, `module: amd/umd/system/none` | TS 7 hard-errors on these (`outFile` was removed in 6.0). Remove them in a `refactor(tsconfig)` commit before anything else                                                              |
| `package.json` `scripts.lint/typecheck/test`                                                                                                                                                                                                       | Tighten the script in place and have the just recipe call it (`pnpm run test`); one definition, not two                                                                                  |
| `oxlint` / `oxlint-tsgolint` / `typescript` in `devDependencies`                                                                                                                                                                                   | The repo pins it; run that copy through the package manager (`pnpm exec`) and leave the nixpkgs one out. One version per tool                                                            |
| `jest`                                                                                                                                                                                                                                             | Keep Jest; do not migrate test runners as part of the baseline                                                                                                                           |
| several lockfiles                                                                                                                                                                                                                                  | Ask which package manager is real; delete the others in a `chore` commit                                                                                                                 |

## devShell

Package manager, decided in this order:

1. `package.json` `packageManager` field (`pnpm@10.28.0` → pnpm, major 10).
2. Lockfile: `pnpm-lock.yaml` → pnpm; `bun.lock` / `bun.lockb` → bun;
   `package-lock.json` → npm; `yarn.lock` → yarn (`.yarnrc.yml` present →
   Yarn Berry).
3. Nothing: **pnpm**. Its isolated `node_modules` makes an undeclared
   (phantom) dependency an import error, which is the structural version of a
   lint rule. Add `"packageManager": "pnpm@<version>"` to `package.json`.

| Package    | nixpkgs attribute                                                            | Note                                                                                                                                                                                                                                                                     |
| ---------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Node       | `nodejs` (= `nodejs_24`); `nodejs_22`, `nodejs_26` exist                     | Match `.nvmrc` / `.node-version` / `engines.node` major; else `nodejs`. Node 26 became Active LTS 2026-10-28 but nixpkgs' default is still 24                                                                                                                            |
| pnpm       | `pnpm` (= `pnpm_12`); `pnpm_10`, `pnpm_11`                                   | Match the `packageManager` major                                                                                                                                                                                                                                         |
| bun        | `bun`                                                                        | Only when the repo is a bun repo                                                                                                                                                                                                                                         |
| npm        | (in `nodejs`)                                                                |                                                                                                                                                                                                                                                                          |
| yarn       | `yarn` (classic), `yarn-berry`                                               |                                                                                                                                                                                                                                                                          |
| TypeScript | `typescript` (= `typescript_7`, 7.0.2, binary `tsc`); `typescript_5` (5.9.3) | Omit when `package.json` pins `typescript`; TS 6 is not packaged                                                                                                                                                                                                         |
| oxlint     | `oxlint`                                                                     | The nixpkgs build wraps `tsgolint` onto its PATH, so `--type-aware` works with no npm package. oxlint looks for the type-aware binary in `$OXLINT_TSGOLINT_PATH`, then `node_modules/.bin`, then `PATH`, so an `oxlint-tsgolint` devDependency wins over the nixpkgs one |
| oxfmt      | `oxfmt`                                                                      | Comes in through `config.treefmt.build.devShell`; do not list it again                                                                                                                                                                                                   |
| ripgrep    | `ripgrep`                                                                    | Only if a recipe uses `rg`; the recipes below use `git grep`                                                                                                                                                                                                             |

Verified at https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/top-level/all-packages.nix
(`nodejs = nodejs_24`, `pnpm = pnpm_12`, `typescript = typescript_7`),
`pkgs/by-name/ty/typescript_7/package.nix`, `pkgs/by-name/ox/oxlint/package.nix`,
`pkgs/top-level/aliases.nix` (`typescript-go` renamed). Vitest, ESLint
plugins and knip are not taken from nixpkgs: they are `devDependencies`.

```nix
devShells.default = pkgs.mkShell {
  inputsFrom = [ config.treefmt.build.devShell ];
  packages = with pkgs; [
    nodejs
    pnpm
    typescript # tsc 7; drop if package.json pins typescript
    oxlint
    just
  ];
};
```

## Formatting: treefmt owns it

Default: **oxfmt via treefmt-nix** (the dotfiles model uses it). treefmt-nix
routes JS/TS/JSON/YAML/Markdown/CSS/SCSS/HTML/Vue/GraphQL files to it. It
reads `.oxfmtrc.json`, `.oxfmtrc.jsonc`, `oxfmt.config.ts` or
`oxfmt.config.mts` (one per directory) and five `.editorconfig` properties
(`end_of_line`, `indent_style`, `indent_size`, `max_line_length`,
`insert_final_newline`). It uses Prettier's output as its baseline and treats
unexpected differences as bugs. Import sorting is **off by default**; turn it
on so the linter's `sort-imports` can stay off:

```nix
treefmt.programs.oxfmt.enable = true;
```

```jsonc
// .oxfmtrc.json
{ "sortImports": true }
```

- A repo already on Prettier or Biome: keep it as the formatter
  (`treefmt.programs.prettier` / `treefmt.programs.biome` exist) unless the user
  wants the switch. A switch is one `style: format with oxfmt` commit, its SHA
  added to `.git-blame-ignore-revs`. No ratchet for formatting.
- Delete `fmt` / `format` scripts that run a second formatter; `nix fmt` is the
  only writer and `treefmt --ci` the only gate.

## tsconfig

TS 6.0 changed the defaults and TS 7 inherits them: `strict: true`,
`module: esnext`, `target` = the latest stable ES (es2025), `types: []`,
`rootDir` = the tsconfig's directory, `noUncheckedSideEffectImports: true`.
`types: []` means globals such as `node` or `vitest/globals` must be listed.
Write the strict flags explicitly anyway, so the file states the contract.

```jsonc
{
  "compilerOptions": {
    // On by default since TS 6; stated so nobody turns it off by omission.
    "strict": true,
    // Beyond strict. Each closes a hole strict leaves open.
    "noUncheckedIndexedAccess": true, // arr[i] and rec[k] are T | undefined
    "exactOptionalPropertyTypes": true, // `a?: T` does not accept explicit undefined
    "noPropertyAccessFromIndexSignature": true, // index-signature keys need obj["k"]
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "allowUnreachableCode": false,
    "allowUnusedLabels": false,
    // Module syntax a single-file transpiler (esbuild, Node type stripping,
    // Vite) can handle. verbatimModuleSyntax turns isolatedModules on.
    "verbatimModuleSyntax": true,
    "erasableSyntaxOnly": true, // no enum, namespace, parameter properties
    "moduleDetection": "force",
    "noUncheckedSideEffectImports": true,
    "forceConsistentCasingInFileNames": true,
    // Full types in error messages; an agent cannot expand "...".
    "noErrorTruncation": true,
    "skipLibCheck": true,
    "noEmit": true,
    // Pick one pair per runtime:
    //   Node app or library:  "module": "nodenext"  (moduleResolution follows)
    //   bundled app (Vite):   "module": "preserve", "moduleResolution": "bundler"
    "module": "nodenext",
    "types": ["node"],
  },
  "include": ["src", "test"],
}
```

- A library that publishes `.d.ts`: add `"isolatedDeclarations": true` (exports
  need explicit types; other tools can emit declarations).
- Checked JS: `"allowJs": true, "checkJs": true`.
- `erasableSyntaxOnly` bans `enum`; the replacement is a `const` object with
  `as const` and a union type. Drop the flag only for a repo that emits through
  `tsc` and has decided to keep enums (record that in an ADR).
- Mature repo: enabling these produces type errors. Use the tsc ratchet below;
  never add `// @ts-expect-error` per line.

## Linter: oxlint

`.oxlintrc.json` (JSONC; comments allowed). Categories at `"error"` mirror the
author's own repos; every rule turned off states why. `restriction` stays off
as a group because its rules contradict each other by design; the useful ones
are opted in by name.

```jsonc
{
  // No "$schema": the nixpkgs oxlint leaves nothing in node_modules to point at.
  "plugins": ["typescript", "unicorn", "oxc", "import", "promise", "node"],
  "categories": {
    "correctness": "error",
    "suspicious": "error",
    "pedantic": "error",
    "perf": "error",
    "style": "error",
  },
  "options": { "typeAware": true },
  "rules": {
    // --- escape hatches: closed, or open only with an issue link ---
    "typescript/ban-ts-comment": [
      "error",
      {
        "ts-expect-error": { "descriptionFormat": "^:?\\s*HACK\\(https?://[^)\\s]+\\)" },
        "ts-ignore": true,
        "ts-nocheck": true,
        "ts-check": false,
      },
    ],
    "typescript/no-explicit-any": "error",
    // `as const` stays allowed. Narrow with a type guard or parse with a schema.
    "typescript/consistent-type-assertions": ["error", { "assertionStyle": "never" }],
    "typescript/no-non-null-assertion": "error",
    "typescript/no-unsafe-argument": "error",
    "typescript/no-unsafe-assignment": "error",
    "typescript/no-unsafe-call": "error",
    "typescript/no-unsafe-member-access": "error",
    "typescript/no-unsafe-return": "error",
    "typescript/no-unsafe-type-assertion": "error",
    // --- type-aware correctness ---
    "typescript/no-floating-promises": "error",
    "typescript/no-misused-promises": "error",
    "typescript/strict-boolean-expressions": "error",
    "typescript/switch-exhaustiveness-check": "error",
    "typescript/only-throw-error": "error",
    // Syntactic, not type-aware: exported functions state their types.
    "typescript/explicit-module-boundary-types": "error",
    // --- dependency rules: the message names what to use instead ---
    "import/no-cycle": "error",
    "no-restricted-imports": [
      "error",
      {
        "paths": [
          {
            "name": "lodash",
            "message": "Use the standard library (Array/Object/structuredClone).",
          },
        ],
        "patterns": [
          {
            "group": ["**/internal/**"],
            "message": "internal/ is private to its parent directory; import the parent's index.ts.",
          },
        ],
      },
    ],
    // --- off: arbitrary thresholds, not defects ---
    "max-lines": "off",
    "max-lines-per-function": "off",
    "max-statements": "off",
    "max-params": "off",
    "no-magic-numbers": "off",
    // --- off: style a formatter or reviewer owns ---
    "sort-imports": "off", // oxfmt sorts imports ("sortImports": true)
    "sort-keys": "off",
    "id-length": "off",
    "no-ternary": "off",
    "func-style": "off",
    "init-declarations": "off",
    "capitalized-comments": "off",
  },
  "overrides": [
    // Boundary template (Ports & Adapters): edit to the repo's layout or delete.
    {
      "files": ["src/lib/**"],
      "rules": {
        "no-restricted-imports": [
          "error",
          {
            "patterns": [
              {
                "group": ["**/jobs/**"],
                "message": "lib/ is an adapter and must not import use cases. Move the shared type to the port (src/state.ts).",
              },
            ],
          },
        ],
      },
    },
    {
      "files": ["**/*.test.ts", "**/*.test.tsx"],
      "plugins": ["vitest"],
      "rules": {},
    },
  ],
}
```

- Start from `oxlint --init` only for an empty repo; otherwise merge into the
  existing file. Run `oxlint --rules` to see what the installed version knows.
- A rule that floods a mature repo is ratcheted, not turned off (Ratchet).
- An `overrides` entry that weakens a rule for some files is an escape hatch
  too: put `// HACK(<issue URL>): why` above it.
- Structure beats lint: if a boundary can be a package boundary (pnpm
  workspace package with an `exports` map), prefer that; `no-restricted-imports`
  is for what package boundaries cannot express.

## ESLint path (repo already on ESLint)

Keep ESLint. typescript-eslint pins TS below 6.1, so `node_modules` keeps
`typescript@6` (or the alias the TS 7 post recommends,
`"typescript": "npm:@typescript/typescript6@^6.0.2"`) for the linter while the
type gate runs `tsc` 7 from nixpkgs. Merge into the existing flat config:

```js
import { defineConfig } from "eslint/config";
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default defineConfig(
  {
    linterOptions: {
      // Inline directive comments are ignored; exceptions live in this file
      // as per-file overrides with a HACK(<issue URL>) comment above them.
      // (Keep the literal directive name out of comments here: the
      // lint-ts-hatches recipe greps for it.)
      noInlineConfig: true,
      reportUnusedDisableDirectives: "error",
      reportUnusedInlineConfigs: "error",
    },
  },
  js.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  { languageOptions: { parserOptions: { projectService: true } } },
  {
    rules: {
      "@typescript-eslint/ban-ts-comment": [
        "error",
        {
          "ts-expect-error": { descriptionFormat: "^:?\\s*HACK\\(https?://[^)\\s]+\\)" },
          "ts-ignore": true,
          "ts-nocheck": true,
        },
      ],
      "@typescript-eslint/consistent-type-assertions": ["error", { assertionStyle: "never" }],
      "@typescript-eslint/strict-boolean-expressions": "error",
      "@typescript-eslint/switch-exhaustiveness-check": "error",
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["**/internal/**"],
              message: "internal/ is private to its parent; import the parent's index.ts.",
            },
          ],
        },
      ],
    },
  },
);
```

- `strictTypeChecked` already brings `no-explicit-any`, `no-non-null-assertion`,
  every `no-unsafe-*`, and `ban-ts-comment` (min description 10).
- With `noInlineConfig: true`, ESLint reports each ignored directive as a
  warning ("'…' has no effect because you have 'noInlineConfig' setting in
  your config"), so `--max-warnings 0` turns any inline disable into a failure.
- If the team will not give up inline disables: `noInlineConfig: false` plus
  `@eslint-community/eslint-plugin-eslint-comments` (`comments.recommended` from
  `.../configs`, and `require-description` at error) and the `lint-ts-hatches`
  recipe below.
- When typescript-eslint supports TS 7 (after the 7.1 API), drop the TS 6
  alias. Re-check issue typescript-eslint#10940 before deciding.

## Escape hatches

| Hatch                                             | Rule                                                                                                                                                                                                                                                                                                                                                                                                          |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `// @ts-ignore`, `// @ts-nocheck`                 | Banned (`ban-ts-comment`)                                                                                                                                                                                                                                                                                                                                                                                     |
| `// @ts-expect-error`                             | Only as `// @ts-expect-error HACK(https://…/issues/N): why`                                                                                                                                                                                                                                                                                                                                                   |
| `any`                                             | Banned (`no-explicit-any`); `no-unsafe-*` catch `any` that leaks in from libraries. Use `unknown` and narrow                                                                                                                                                                                                                                                                                                  |
| `x as T`, `<T>x`                                  | Banned (`assertionStyle: "never"`); `as const` allowed. Narrow with a type predicate or parse with a schema (zod / valibot)                                                                                                                                                                                                                                                                                   |
| `x!`                                              | Banned (`no-non-null-assertion`); handle the `undefined`                                                                                                                                                                                                                                                                                                                                                      |
| `// oxlint-disable…`, `// eslint-disable…`        | Only as `// oxlint-disable-next-line <rule> -- HACK(https://…/issues/N): why`. A file-wide `oxlint-disable` / `eslint-disable` (no `-line` / `-next-line`) is never allowed, with or without a link. Enforced by `lint-ts-hatches`; oxlint honours `eslint-disable*` too unless `options.respectEslintDisableDirectives` is `false`; unused ones fail via `--report-unused-disable-directives-severity=error` |
| `overrides` / `ignorePatterns` that weaken a rule | `// HACK(<issue URL>): why` above the entry                                                                                                                                                                                                                                                                                                                                                                   |

oxlint has no `noInlineConfig` equivalent and no rule requiring a reason, but
it does parse a description after a directive (`-- why`, or a single `-`
surrounded by spaces). The HACK link is therefore
enforced by the recipe, the same way `lint-go-suppressions` does it for Go.

## Ratchet (mature repo)

Run the full `check` once. If clean, use the plain recipes. Otherwise ratchet
each tool, record the decision in an ADR, and file one issue for the burn-down.
Do not mass-fix, mass-disable or mass-`@ts-expect-error`.

**ESLint** (bulk suppressions, ESLint ≥ 9.24.0):

1. `eslint --fix --suppress-all` (fix what is auto-fixable, suppress the rest),
   commit `eslint-suppressions.json` in its own commit.
2. `check` runs plain `eslint`: a new violation fails; a fixed one leaves an
   unused suppression, which also fails ("There are suppressions left that do
   not occur anymore") until `eslint --prune-suppressions` lowers the file.
3. Only `"error"` rules are suppressed, which is another reason the baseline has
   no warnings. Do not pass `--pass-on-unpruned-suppressions`.

**oxlint** (bulk suppressions, hidden flags): `oxlint --suppress-all` writes
`oxlint-suppressions.json` in the working directory; `--prune-suppressions`
drops fixed entries; a new violation fails with "There are new violations not
covered by the suppressions file", a stale one with "There are suppressions
that do not occur anymore". The flags are hidden from `--help` and not yet
documented (oxc 2026 Q4 plan: "The code is complete, but it has not been
properly stabilized or documented"). Always run oxlint from the repo root so the file is found. If the
flags misbehave, fall back to an `overrides` entry listing the legacy files
with the rule `"off"` and a HACK comment; delete files from the list as they
are fixed.

**tsc** has no baseline. Two options:

- Default: the `typecheck-ts` ratchet recipe below. It counts errors per file
  and code (`src/a.ts TS2345`), not per line, so edits elsewhere in a file do
  not churn it. More errors fail; fewer errors also fail until
  `just typecheck-ts-baseline` lowers `.tsc-baseline`, so the count only goes
  down.
- Structural: put fixed directories under a strict `tsconfig.json` and the
  rest under a `tsconfig.legacy.json` with the new flags off, joined by project
  references (`tsc -b`). Move a directory across when it is clean. Use this when
  the errors cluster in a few directories.

## just recipes

The core `check` recipe calls these. Replace `pnpm` with the detected package
manager (`npm ci` / `npm exec`, `bun install --frozen-lockfile` / `bunx`,
`yarn install --immutable` / `yarn`).

```just
# Install exactly what the lockfile says
[private]
setup-ts:
    pnpm install --frozen-lockfile

# Lint with type information; warnings and unused disables fail
lint-ts: setup-ts lint-ts-hatches
    oxlint --type-aware --deny-warnings --report-unused-disable-directives-severity=error

# Every inline disable and @ts-expect-error must name the issue that removes it
lint-ts-hatches:
    #!/usr/bin/env bash
    set -euo pipefail
    hatch='(oxlint|eslint)-disable|@ts-expect-error'
    found=$(git grep -n -E "$hatch" -- '*.ts' '*.tsx' '*.mts' '*.cts' '*.js' '*.jsx' '*.mjs' '*.cjs' '*.vue' || true)
    bad=$(printf '%s\n' "$found" | grep -E "$hatch" | grep -v -E 'HACK\(https?://[^)]+\)' || true)
    wide=$(printf '%s\n' "$found" | grep -E '(oxlint|eslint)-disable([^-]|$)' || true)
    if [ -n "$wide" ]; then
        printf '%s\n' "$wide"
        echo 'File-wide disables are not allowed. Disable one line: // oxlint-disable-next-line <rule> -- HACK(<issue URL>): <why>'
        exit 1
    fi
    if [ -n "$bad" ]; then
        printf '%s\n' "$bad"
        echo 'Fix the code instead. If you cannot: // oxlint-disable-next-line <rule> -- HACK(<issue URL>): <why>'
        exit 1
    fi

# Type-check the whole project (tsc 7)
typecheck-ts: setup-ts
    tsc --noEmit

# Run the tests once, no watch
test-ts: setup-ts
    pnpm exec vitest run
```

ESLint path: `lint-ts` runs `pnpm exec eslint --max-warnings 0 .` instead of
oxlint (bulk suppressions apply automatically when the file exists).
Project references: `tsc -b --noEmit`. Test runner: `node --test` for a repo
already on `node:test`; `bun test` for a bun repo; Jest repos keep
`pnpm exec jest --ci`. `vitest run` fails when it finds no test files: on an
empty repo write the first real test rather than adding `--passWithNoTests`.

Ratchet variant of `typecheck-ts`:

```just
# Type errors may only go down: compare per-file/per-code counts to .tsc-baseline
typecheck-ts: setup-ts
    #!/usr/bin/env bash
    set -euo pipefail
    if ! diff -u .tsc-baseline <(just _tsc-errors); then
        echo 'More errors: fix the new ones. Fewer errors: run `just typecheck-ts-baseline` and commit.'
        exit 1
    fi

# Rewrite .tsc-baseline after fixing type errors (never to absorb new ones)
typecheck-ts-baseline: setup-ts
    just _tsc-errors > .tsc-baseline

# tsc errors as "<count> <file> <code>", line numbers dropped
[private]
_tsc-errors:
    #!/usr/bin/env bash
    set -uo pipefail
    command -v tsc > /dev/null || { echo 'tsc not on PATH' >&2; exit 127; }
    { tsc --noEmit --pretty false || true; } \
        | grep -E 'error TS[0-9]+' \
        | sed -E 's/\([0-9]+,[0-9]+\)//; s/: error (TS[0-9]+):.*/ \1/' \
        | sort | uniq -c
    exit 0
```

A config error (`error TS5xxx` with no file) survives the `sed` as a whole
line, is not in the baseline, and so fails the diff instead of being hidden.
When `.tsc-baseline` reaches empty, delete it and the three ratchet recipes and
go back to the plain `typecheck-ts` in one commit.

Notes:

- `options.typeAware` in the config makes the editor's oxlint LSP type-aware
  too; the CLI flag repeats it so the recipe does not depend on the config.
- `oxlint --type-check` can also report tsc diagnostics. Keep `tsc` as the type
  gate: it handles project references and is the reference implementation.
- `--deny-warnings` keeps a rule left at `"warn"` from passing silently.
- Optional: `knip` (unused files, exports, dependencies) as a devDependency,
  `pnpm exec knip` in `lint-ts`; the author's Tauri repo runs it in `check`.

## Unverified (check on first use)

- UNVERIFIED: oxlint `--suppress-all` / `--prune-suppressions` are hidden and
  undocumented. oxc has a suppression test fixture run with
  `--type-aware --type-check`, but whether `--type-check` (compiler)
  diagnostics are suppressible was not confirmed.
- UNVERIFIED: `oxlint --init` output.
- UNVERIFIED: `tsc` 7 `--pretty false` line format (`file(l,c): error TSnnnn: …`)
  is assumed unchanged from 5.x for the `_tsc-errors` parser; run the recipe
  on a known error before relying on it.
- UNVERIFIED: `tsc -b --noEmit` with project references on TS 7.
- No `nix` command was run; attributes were read from the nixpkgs tree, not
  evaluated.

Checked against source (2026-11-17): oxlint `ban-ts-comment` matches
`descriptionFormat` against the untrimmed text after the directive name, so
`^:?\s*HACK\(` accepts both `@ts-expect-error HACK(…)` and
`@ts-expect-error: HACK(…)`. `consistent-type-assertions` with
`assertionStyle: "never"` still allows `as const`. Categories: `max-lines`,
`max-lines-per-function` are `pedantic`; `max-statements`, `max-params`,
`no-magic-numbers`, `sort-imports`, `sort-keys`, `id-length`, `no-ternary`,
`func-style`, `init-declarations`, `capitalized-comments` are `style`; so all
are on under the categories above and need the explicit `"off"`.
`no-restricted-imports` and `import/no-cycle` are `restriction` and need the
explicit `"error"`.

## Sources

- TypeScript 7.0 announcement (defaults, hard errors, no API, `@typescript/typescript6`): https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/
- TypeScript 6.0 announcement (default changes, deprecations): https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/
- TSConfig reference: https://www.typescriptlang.org/tsconfig/
- typescript-eslint TS 7: https://github.com/typescript-eslint/typescript-eslint/issues/12518 (closed, not planned), https://github.com/typescript-eslint/typescript-eslint/issues/10940 (tracking, open); peer range from https://registry.npmjs.org/typescript-eslint/latest
- typescript-eslint `strictTypeChecked` contents: https://github.com/typescript-eslint/typescript-eslint/blob/main/packages/eslint-plugin/src/configs/flat/strict-type-checked.ts
- tsgolint rule coverage (README "Implemented Rules"): https://github.com/oxc-project/tsgolint/blob/main/README.md; tsgolint lookup order: https://github.com/oxc-project/oxc/blob/main/crates/oxc_linter/src/tsgolint.rs
- oxlint config schema (`options.typeAware`, `respectEslintDisableDirectives`, plugin names): https://github.com/oxc-project/oxc/blob/main/npm/oxlint/configuration_schema.json; rule sources and categories: https://github.com/oxc-project/oxc/tree/main/crates/oxc_linter/src/rules
- oxfmt `sortImports` (default disabled): https://github.com/oxc-project/oxc/blob/main/npm/oxfmt/configuration_schema.json
- ESLint `noInlineConfig` warning: https://github.com/eslint/eslint/blob/main/lib/linter/linter.js
- oxc 2026 Q4 plan (bulk suppressions status): https://github.com/oxc-project/oxc/issues/28275
- typescript-eslint typed linting: https://typescript-eslint.io/getting-started/typed-linting/
- `ban-ts-comment`: https://typescript-eslint.io/rules/ban-ts-comment/
- `consistent-type-assertions`: https://typescript-eslint.io/rules/consistent-type-assertions/
- oxlint type-aware: https://oxc.rs/docs/guide/usage/linter/type-aware.html, rule list https://github.com/oxc-project/tsgolint
- oxlint CLI: https://oxc.rs/docs/guide/usage/linter/cli.html; config: https://oxc.rs/docs/guide/usage/linter/config.html; ignore comments: https://oxc.rs/docs/guide/usage/linter/ignore-comments.html
- oxlint suppression flags: https://github.com/oxc-project/oxc/blob/main/apps/oxlint/src/command/lint.rs, https://github.com/oxc-project/oxc/issues/10549, https://github.com/oxc-project/oxc/discussions/22198, https://github.com/oxc-project/oxc/issues/28275
- oxlint `--` descriptions: https://github.com/oxc-project/oxc/blob/main/crates/oxc_linter/src/disable_directives.rs
- ESLint linterOptions: https://eslint.org/docs/latest/use/configure/configuration-files; bulk suppressions: https://eslint.org/docs/latest/use/suppressions (introduced in https://github.com/eslint/eslint/releases/tag/v9.24.0)
- eslint-comments plugin: https://eslint-community.github.io/eslint-plugin-eslint-comments/
- oxfmt: https://oxc.rs/docs/guide/usage/formatter.html, https://oxc.rs/docs/guide/usage/formatter/config.html; treefmt-nix: https://github.com/numtide/treefmt-nix/blob/main/programs/oxfmt.nix
- Node release schedule: https://github.com/nodejs/Release/blob/main/schedule.json
- Vitest: https://registry.npmjs.org/vitest/latest
- nixpkgs: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ty/typescript_7/package.nix, https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ox/oxlint/package.nix
