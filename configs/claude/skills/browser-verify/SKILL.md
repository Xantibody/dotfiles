---
name: browser-verify
description: Looks at a web screen with agent-browser instead of guessing from the code — after a frontend change to see the rendered result, and before a PR to capture a before / after pair the reviewer would otherwise have to run the app to see. House workflow only; the CLI's own usage guide comes from `agent-browser skills get core`.
when_to_use: When a change alters something a browser renders — a page, a component, a layout, a chart, a CSS rule — and the implement skill reaches Green, or the pull-request skill's Screenshots gate opens. Also when the user asks to see, check, or capture a screen — "画面見て", "スクショ撮って", "描画確認して", "before/after 撮って", "ブラウザで確認して".
---

# Browser verification

Tests say the code does what it says; they do not say the screen looks
right. When the change is something a browser renders, look at it. This
skill is the house workflow around `agent-browser`; the CLI's own guide
(refs, snapshots, sessions, waiting) is loaded from the tool itself so it
matches the installed version.

## Pre-flight

1. **Load the CLI's guide first**, before the first command:

   ```bash
   agent-browser skills get core
   ```

2. **Chrome:** the Nix package ships the CLI only. If `agent-browser open`
   fails for want of a browser, the one-time download is:

   ```bash
   agent-browser install
   ```

   It fetches Chrome for Testing into the user's cache. If the download is
   denied in this session, hand it over as `! agent-browser install`.

3. **Own session, always.** The default session is shared with every
   agent and persists across conversations. Set one for the task and close
   it at the end:

   ```bash
   export AGENT_BROWSER_SESSION="$(agent-browser session id --scope worktree --prefix verify)"
   ```

   Every Bash call is a fresh shell, so put the `export` in front of each
   command chain, or pass `--session <name>` explicitly.

4. **A running app.** The project's dev server or preview — the `run`
   skill knows how to start it; a static site is served from its build
   output. Note the URL; the skill does not start servers itself.

## Verify a change

Same viewport every time, so two runs are comparable and a layout that
only breaks at one width is caught on purpose, not by luck:

```bash
agent-browser open <url>
agent-browser set viewport 1280 800
agent-browser wait --load networkidle
agent-browser snapshot -i                      # what is on the page, by role
agent-browser screenshot <dir>/after.png
```

Then **look at the image** with the Read tool. The snapshot tells you the
button exists; the screenshot tells you it is where it should be, readable,
and not overlapping something. Check what the change was meant to change,
and one thing it was not meant to touch. A mobile width (`set viewport
390 844`) is a second pass when the change touches layout.

Interact when the state you need is behind a click — open the menu, fill
the form, trigger the empty state — using refs from a fresh snapshot each
time. Do not screenshot terminal output, and do not screenshot a mermaid
block; those belong in code blocks and GitHub renders the latter itself.

## Before / after for a PR

The pull-request skill's Screenshots gate asks for a pair only when the
text would otherwise be describing pixels. When it opens:

1. **Before** is the base branch, not a memory of it. Run the base in its
   own worktree next to the repo (`ha` layout, `<repo>@main`) on a second
   port, or stash and restart if the app is cheap to restart. Same URL
   path, same viewport, same state (logged in or not, same data).
2. Capture both into the temp directory that holds the PR body, so the
   paths on `--attach` and in the body match:

   ```bash
   agent-browser screenshot <dir>/before.png     # on the base
   agent-browser screenshot <dir>/after.png      # on the branch
   ```

3. Read both images back before writing the caption. The caption says
   what the reviewer should see change, not that a screenshot is attached.
   A pair that looks the same is a pair that should not be attached.

Full-page (`--full`) only when the change is below the fold; otherwise
the viewport shot is the honest one.

## Finish

```bash
agent-browser close
```

Leave nothing running. Report which URL and viewport were captured, and
anything that could not be verified — a state you could not reach, a
server that would not start — rather than a screenshot of the wrong
thing.
