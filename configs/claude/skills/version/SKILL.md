---
name: version
description: Determines the next version number following Semantic Versioning 2.0.0.
---

# Semantic Versioning (version)

This skill determines the next version number for a release based on the [Semantic Versioning 2.0.0](https://semver.org/) specification. It analyzes the commit history since the last release and recommends the appropriate version bump.

## Version Format

```text
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incremented for incompatible API changes.
- **MINOR**: Incremented for backward-compatible functionality additions. Resets PATCH to 0.
- **PATCH**: Incremented for backward-compatible bug fixes.

Pre-release and build metadata extensions are available as additional labels appended to the MAJOR.MINOR.PATCH format.

## Specification Rules

1. **Public API Declaration**: Software using Semantic Versioning MUST declare a public API. This API could be declared in the code itself or exist strictly in documentation.

2. **Normal Version Format**: A normal version number MUST take the form X.Y.Z where X, Y, and Z are non-negative integers, and MUST NOT contain leading zeroes. X is the major version, Y is the minor version, and Z is the patch version. Each element MUST increase numerically. For instance: 1.9.0 -> 1.10.0 -> 1.11.0.

3. **Release Immutability**: Once a versioned package has been released, the contents of that version MUST NOT be modified. Any modifications MUST be released as a new version.

4. **Zero Major Version (0.y.z)**: Major version zero is for initial development. Anything MAY change at any time. The public API SHOULD NOT be considered stable.

5. **Version 1.0.0**: Version 1.0.0 defines the public API. The way in which the version number is incremented after this release is dependent on this public API and how it changes.

6. **Patch Version Z (x.y.Z)**: MUST be incremented if only backward-compatible bug fixes are introduced. A bug fix is defined as an internal change that corrects incorrect behavior.

7. **Minor Version Y (x.Y.z)**: MUST be incremented if new, backward-compatible functionality is introduced to the public API. It MUST be incremented if any public API functionality is marked as deprecated. It MAY be incremented if substantial new functionality or improvements are introduced within the private code. It MAY include patch level changes. Patch version MUST be reset to 0 when minor version is incremented.

8. **Major Version X (X.y.z)**: MUST be incremented if any backward-incompatible changes are introduced to the public API. It MAY also include minor and patch level changes. Patch and minor versions MUST be reset to 0 when major version is incremented.

9. **Pre-release Version**: A pre-release version MAY be denoted by appending a hyphen and a series of dot-separated identifiers immediately following the patch version. Identifiers MUST comprise only ASCII alphanumerics and hyphens [0-9A-Za-z-]. Pre-release versions have a lower precedence than the associated normal version. Examples: 1.0.0-alpha, 1.0.0-alpha.1, 1.0.0-0.3.7, 1.0.0-x.7.z.92, 1.0.0-x-y-z.--.

10. **Build Metadata**: Build metadata MAY be denoted by appending a plus sign and a series of dot-separated identifiers immediately following the patch or pre-release version. Identifiers MUST comprise only ASCII alphanumerics and hyphens [0-9A-Za-z-]. Build metadata MUST be ignored when determining version precedence. Examples: 1.0.0-alpha+001, 1.0.0+20130313144700, 1.0.0-beta+exp.sha.5114f85, 1.0.0+21AF26D3----117B344092BD.

11. **Precedence**: Precedence refers to how versions are compared to each other when ordered.
    - Precedence MUST be calculated by separating major, minor, patch, and pre-release identifiers in that order. Build metadata does not figure into precedence.
    - Precedence is determined by the first difference when comparing each of these identifiers from left to right: Major, minor, and patch versions are always compared numerically. Example: 1.0.0 < 2.0.0 < 2.1.0 < 2.1.1.
    - When major, minor, and patch are equal, a pre-release version has lower precedence than a normal version. Example: 1.0.0-alpha < 1.0.0.
    - Precedence for two pre-release versions with the same major, minor, and patch version MUST be determined by comparing each dot-separated identifier from left to right until a difference is found. Example: 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.

## How to Determine the Next Version

When analyzing commits since the last release, map Conventional Commits types to version bumps:

| Commit Type / Indicator                                     | Version Bump            |
| ----------------------------------------------------------- | ----------------------- |
| `BREAKING CHANGE:` footer or `!`                            | **MAJOR**               |
| `feat`                                                      | **MINOR**               |
| `fix`, `perf`                                               | **PATCH**               |
| `docs`, `style`, `refactor`, `test`, `build`, `ci`, `chore` | **PATCH** (if included) |

The highest applicable bump wins. For example, if there is at least one breaking change, bump MAJOR regardless of other commits.

## Workflow

1. **Find the latest version tag** (e.g., `git describe --tags --abbrev=0`).
2. **List commits since that tag** (e.g., `git log <tag>..HEAD --oneline`).
3. **Analyze each commit** for type, scope, and breaking change indicators.
4. **Determine the highest bump level** (MAJOR > MINOR > PATCH).
5. **Calculate the next version** by applying the bump to the current version.
6. **Present the recommendation** with a summary of the changes that drove the decision.

## Examples

### Patch Release

Current version: 1.2.3

```text
fix: resolve null pointer in config parser
docs: update installation guide
```

Next version: **1.2.4**

### Minor Release

Current version: 1.2.3

```text
feat(api): add endpoint for user preferences
fix: handle empty response body gracefully
```

Next version: **1.3.0**

### Major Release

Current version: 1.2.3

```text
feat!: redesign authentication flow
feat(api): add batch processing endpoint
fix: correct timezone handling
```

Next version: **2.0.0**

### Pre-release

Current version: 2.0.0

```text
feat: add experimental caching layer
```

Next version (pre-release): **2.1.0-alpha.1**

## How to Use

When asked to determine or recommend a version number, the agent MUST:

1. Check the current version from git tags or version files.
2. Analyze commits since the last release using Conventional Commits format.
3. Apply Semantic Versioning rules to recommend the next version.
4. Explain the reasoning behind the recommendation.
