---
name: terminal-verify
description: Looks at what a terminal renders with vhs instead of guessing from the config — after a change to a prompt, a colour scheme, a TUI or an editor's UI, and before a PR to capture a before / after pair the reviewer would otherwise have to install the config to see.
when_to_use: When a change alters what a terminal draws — a shell prompt, a theme or palette, a status line, a TUI layout, an editor's UI — and the implement skill reaches Green, or the pull-request skill's Screenshots gate opens on something a terminal renders. Also when the user asks to see or capture a terminal screen — "ターミナルの見た目確認して", "プロンプトのスクショ撮って", "TUI の before/after 撮って", "配色どうなったか見て".
---

# Terminal verification

A config that evaluates is not a prompt that looks right. When the change
is something a terminal draws — colours, glyphs, layout, a status line —
render it and look. `vhs` drives a headless terminal from a tape file and
writes a PNG.

Plain command output is not this skill's job. Text the reviewer could
search and copy belongs in a code block; a screenshot earns its place only
when the colour, the alignment or the glyphs are the point.

## Pre-flight

1. **vhs 0.12.1 or later.** 0.12.0 exits 0 and writes no file at all
   ([charmbracelet/vhs#787](https://github.com/charmbracelet/vhs/issues/787)).
   If `vhs --version` says 0.12.0, run it from a newer nixpkgs instead:

   ```bash
   nix run github:NixOS/nixpkgs/nixpkgs-unstable#vhs -- <dir>/after.tape
   ```

2. **The program reads the config under test.** Point it at the tree by
   flag or environment — `nvim -u`, `XDG_CONFIG_HOME`, `starship --config`,
   `fish -C 'source …'` — so the shot does not show whatever happens to be
   installed. When the config only exists after a Nix build, build that
   tree's output and point at the store path.

## Write the tape

Keep the tape next to the images in the temp directory that holds the PR
body. Same size and font every time, so two shots are comparable:

```
Output "<dir>/after.gif"
Set Shell "bash"
Set Width 1200
Set Height 600
Set FontSize 18
Hide
Type "<command that loads the config under test>"
Enter
Sleep 1s
Type "clear"
Enter
Show
Type "<what the reviewer should see happen>"
Enter
Sleep 1s
Screenshot "<dir>/after.png"
Sleep 500ms
```

Four traps, each of which fails without an error:

- **Quote absolute paths.** An unquoted `/` path is a parse error.
- **`clear` before `Show`.** `Hide` stops recording, not drawing: the
  setup commands are still on the screen the screenshot captures.
- **Never end on `Screenshot`.** Without a command after it the PNG is
  sometimes not written ([#540](https://github.com/charmbracelet/vhs/issues/540)).
- **Give `Output` a `.gif`.** An `Output` ending in `.png` is a frame
  directory, and a `Screenshot` to the same name collides with it.

`Hide` / `Show` keep the setup out of the frame. Run it with
`timeout 300 vhs <dir>/after.tape`, then **look at the image** with the
Read tool: check what the change was meant to change, and one thing it was
not meant to touch. A screenshot of a shell that never loaded the config
looks plausible and proves nothing.

A real prompt shows the machine it runs on: an account name, the
hostname, the working directory's path. Before the image goes anywhere,
look for them. When one should not leave the machine, find which prompt
module prints it — an email next to a cloud glyph is the cloud CLI's
account, not git's — and turn that module off for the tape in the hidden
setup, with `cd /tmp` for the path. Then shoot again and look again.

## Before / after for a PR

1. **Before** is the base branch, not a memory of it. Check it out in its
   own worktree next to the repo (`ha` layout, `<repo>@main`) and copy the
   tape with the config path pointing there. Same size, same font, same
   commands.
2. Capture both into the PR body's temp directory, so the paths on
   `--attach` and in the body match:

   ```bash
   timeout 300 vhs <dir>/before.tape
   timeout 300 vhs <dir>/after.tape
   ```

3. Read both images back before writing the caption. The caption says
   what the reviewer should see change, not that a screenshot is attached.
   A pair that looks the same is a pair that should not be attached.

When the change shows in motion — an animation, a key sequence that
redraws — attach the GIF instead; `--attach` takes it the same way.

## Finish

Report which command, size and config were captured, and anything that
could not be — a program that needs a real TTY vhs does not provide, a
config that would not load — rather than a screenshot of the wrong thing.
