---
name: version
description: Determines the next version number following Semantic Versioning 2.0.0. Use this skill when the user asks to determine the next version, bump the version, prepare a release, or create a version tag. Analyzes commit history with Conventional Commits to recommend the appropriate MAJOR, MINOR, or PATCH bump.
disable-model-invocation: true
---

# Semantic Versioning (version)

Determine the next version number per [Semantic Versioning 2.0.0](https://semver.org/) by analyzing the Conventional Commits history since the last release.

## Determining the Bump

Map commit types since the last release to version bumps:

| Commit Type / Indicator                                     | Version Bump            |
| ----------------------------------------------------------- | ----------------------- |
| `BREAKING CHANGE:` footer or `!`                            | **MAJOR**               |
| `feat`                                                      | **MINOR**               |
| `fix`, `perf`                                               | **PATCH**               |
| `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore` | **PATCH** (if included) |

The highest applicable bump wins. While the major version is 0 (initial development), the API is not considered stable — confirm with the user whether a breaking change should bump MAJOR or MINOR.

## Workflow

1. **Find the latest version tag**: `git describe --tags --abbrev=0 --match 'v*'` — without `--match`, any non-version tag (a deploy marker, a bookmark) is picked up and the changelog starts from the wrong point
2. **List commits since that tag**: `git log <tag>..HEAD --oneline`
3. **Analyze each commit** for type, scope, and breaking change indicators
4. **Determine the highest bump level** (MAJOR > MINOR > PATCH) and calculate the next version
5. **Present the recommendation** with a summary of the changes that drove the decision
6. **On user confirmation**, create an annotated tag with a changelog (below)

If no previous tag exists, treat all commits as the initial release changelog. For repositories with many non-conventional commits, focus on commits that follow Conventional Commits format and note the total count of the rest separately.

## Tag Creation with Changelog

The annotated tag message contains a structured changelog of all changes since the last release, browsable via `git tag -n999` or `git show <tag>`.

Group commits by type in this display order (skip empty groups), and highlight breaking changes at the top before the grouped sections:

`feat` → Features, `fix` → Bug Fixes, `perf` → Performance Improvements, `refactor` → Refactoring, `docs` → Documentation, `style` → Code Style, `test` → Tests, `build` → Build System, `ci` → CI/CD, `chore` → Chores, `revert` → Reverts

### Tag Message Format

```text
v<VERSION>

Release Date: <YYYY-MM-DD>

[BREAKING CHANGES (if any)]

## Features
- (scope): description (commit-hash)
- description (commit-hash)

## Bug Fixes
- (scope): description (commit-hash)

...
```

### Creating the Tag

Use `git tag -a` with a HEREDOC to pass the multi-line message:

```bash
git tag -a "v<VERSION>" -m "$(cat <<'EOF'
<changelog content>
EOF
)"
```

Before tagging, make sure the tree is clean and the checks pass (`verify` skill). A tag on a broken or half-committed state is the one kind of commit that is awkward to redo, because the name is already taken.

After creating the tag, confirm success with `git tag -l "v<VERSION>"` and display the message with `git tag -n999 "v<VERSION>"`.

A tag that only exists locally is the failure mode here — it is easy to forget, and nothing reminds you. `git push` is deny-listed on purpose, so hand the user the exact command in the form `! git push origin v<VERSION>` and say plainly that the tag is not on the remote until they run it.

A first tag is the point a repository stops being disposable, so it is also the
natural moment to check branch protection — see the `branch-protection` skill.
Keep it to one line if protection already exists; a release is a bad time for a
detour.
