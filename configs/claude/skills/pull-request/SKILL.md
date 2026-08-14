---
name: pull-request
description: Creates GitHub pull requests with a concise Japanese body (なぜやるか / やったこと / やらなかったこと / 資料). Use this skill whenever the user wants to open, create, raise, submit, or update a PR — including phrasings like "PRを作って", "プルリク出して", "push して PR まで", "gh pr create", or simply "レビューに出したい". Also use it when updating the description of a PR that already exists.
---

# Pull requests

GitHub already shows the reviewer the diff. The body's job is to convey the two
things the diff cannot: **why this change exists** and **what was deliberately
left out**. Restating the diff only makes the body longer and wastes the
reviewer's time. Brevity is courtesy, not laziness.

## Pre-flight

1. **Base and branch:**

   ```bash
   BASE=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
   git fetch origin "$BASE"
   git branch --show-current
   ```

   If you are on the default branch, you need to branch off. With uncommitted
   work, `git switch -c <type>/<slug>` carries the working tree over. **If the
   work is already committed onto the default branch**, creating a branch is
   not enough — the local default still points at those commits, so the diff
   comes back empty and the PR has no content:

   ```bash
   git switch -c <type>/<slug>
   git branch -f "$BASE" "origin/$BASE"
   ```

2. **Uncommitted changes:** ask the user whether to include them, then commit
   via the `commit` skill. A PR that omits half the change invites a review of
   the wrong thing.

3. **Confirm the range:** read `git log --oneline "origin/$BASE..HEAD"`. Empty
   means step 1 went wrong. Unfamiliar commits are the user's unpushed work —
   don't silently include them, don't silently drop them; ask.

Check for an existing PR with `gh pr view`; if one exists, use `gh pr edit`
instead of `gh pr create`.

## Read the change first

Read before writing. Use three dots (merge-base comparison) — two dots would
attribute other people's post-fork changes on the base to your PR:

```bash
git diff --stat "origin/$BASE...HEAD"
git log --format='%s%n%b' "origin/$BASE..HEAD"   # commit bodies hold the why
git diff "origin/$BASE...HEAD"
```

Commit bodies are the primary source for the _why_, but verify their claims
against the diff before repeating them. On bot branches (Renovate etc.) with
no bodies, go read the upstream release notes. Never invent a
plausible-sounding rationale.

## Title

Conventional Commits. Type and scope rules come from the `commit` skill and
the repo's CLAUDE.md. A single-commit branch reuses its subject verbatim. A
multi-commit branch gets one line for what the branch achieves — not a list of
operations. If it won't fit in one line, that is evidence the branch should be
split; say so to the user.

## Body

The body is written in Japanese, in this format:

```markdown
## なぜやるか

<この変更が必要な理由。issue があれば closes #123 で引用>

## やったこと

- <何をしたか、簡潔に>

## やらなかったこと

- <あえてスコープ外にしたこと、次に回したこと>

## 資料

- <参考リンク、issue、議論>
```

- **なぜやるか** is the core of the body. If the motivation lives in a commit
  body, lift it from there.
- **やったこと** only needs to be a table of contents for the diff. GitHub
  already shows file lists and line counts.
- **やらなかったこと** is the most valuable section when you can write it —
  stating "this is out of scope" saves the reviewer from wondering whether to
  flag it. If there is truly nothing, drop the section. Never leave an empty
  section.
- **資料** — likewise, drop it if there are no links.

### Diagrams

Include a diagram **only when the architecture changed** — module structure,
direction of dependencies, or flow of control changed in a way prose conveys
poorly. Put the mermaid block inside やったこと and draw only what changed,
not a restatement of the whole system.

Everything else — version bumps, config tweaks, typo fixes, simple additions —
gets no diagram. A forced diagram is decoration that looks like information,
and it costs the body its credibility. When in doubt, don't draw.

If you do draw: always quote labels (`n["foo (bar)"]` — parentheses break the
parse), never use lowercase `end` as a node id, and past ~15 nodes you are
drawing the system instead of the change. Emphasize with `stroke`, not `fill`
(fills swallow labels on GitHub's dark theme).

## Verify, push, create

Write the body outside the worktree so a later `git add -A` can't swallow it:

```bash
BODY=$(mktemp -d)/pr-body.md
```

Before pushing, run the project's checks via the `verify` skill. A PR that
fails its own repo's fmt/check burns a review round on nothing.

```bash
git push -u origin HEAD
gh pr create --base "$BASE" --title "<title>" --body-file "$BODY"
gh pr checks --watch
```

Use `--body-file`, not `--body` (which mangles newlines and mermaid fences).
`gh pr checks --watch` blocks until CI settles — never sleep-and-poll.

If push or create is denied by permissions, that is the user's decision, not
an obstacle to route around. Hand over the exact commands with real paths
substituted, in the form `! git push -u origin <branch>`, so the user can run
them in their own session.

## Report

Give the user the PR URL, the title, and the CI outcome. State explicitly what
you left out — files not committed, checks that couldn't run. A PR that looks
complete but isn't is the most expensive failure here.
