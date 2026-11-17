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
   `rat shot` below refuses an older vhs; build a newer one with
   `nix build github:NixOS/nixpkgs/nixpkgs-unstable#vhs` and pass its
   `bin/vhs` as `--vhs`.

2. **The program reads the config under test.** Point it at the tree by
   flag or environment — `nvim -u`, `XDG_CONFIG_HOME`, `starship --config`,
   `fish -C 'source …'` — so the shot does not show whatever happens to be
   installed. When the config only exists after a Nix build, build that
   tree's output and point at the store path.

3. **How the program starts, from the repository.** First the
   repository's run skill (`.claude/skills/<repo>-run/`, or
   `.agents/skills/<repo>-run/` under codex): its Start section and its
   feature map in `references/features.md`. Without one, `just run`. With
   neither, the command from item 2 is the start; when the repository
   ships a program (a TUI, a CLI), say in the report that it has no run
   skill, which is the baseline skill's step 8.

## Take the shot

Do not write the tape by hand. `rat shot` writes it, with the traps that
fail without an error ruled out by its tests, runs vhs, and fails unless
a PNG was written. Keep the images in the temp directory that holds the
PR body; the tape and a GIF land beside them. Leave `--width`, `--height`
and `--font-size` at their defaults, so two shots are comparable:

```bash
rat shot \
  --out <dir>/after.png \
  --setup '<command that loads the config under test>' --ready '<regex>' \
  --command '<what the reviewer should see happen>' --wait '<regex>'
```

`--setup` (repeatable) is typed while hidden, `--command` while shown.
There is no fixed `Sleep`: `--ready` and `--wait` are regexes the whole
screen matches once each step has drawn — the prompt for a shell, the
status line for nvim, which has no prompt. Pick one only the finished
screen has, not the typed command line, and anchor a line with
`(?m)^done *$` (vhs pads each line with spaces). A screen that never
matches fails after `--wait-timeout` (15s) instead of capturing the
half-loaded one. `--tape-only` prints the tape without running it.

Then **look at the image** with the Read tool: check what the change was
meant to change, and one thing it was not meant to touch. With a feature
map, pick both from it — one row the diff touches and one it does not —
and pass each row's path in `--command`, one shot per row; without one,
pick them yourself and name them in the report. A screenshot of a shell
that never loaded the config looks plausible and proves nothing.

A real prompt shows the machine it runs on: an account name, the
hostname, the working directory's path. Before the image goes anywhere,
look for them. When one should not leave the machine, find which prompt
module prints it — an email next to a cloud glyph is the cloud CLI's
account, not git's — and turn that module off in a `--setup`, with
`cd /tmp` for the path. Then shoot again and look again.

## Before / after for a PR

1. **Before** is the base branch, not a memory of it. Check it out in its
   own worktree next to the repo (`ha` layout, `<repo>@main`) and rerun
   `rat shot` with the config path pointing there. Same size, same font,
   same commands.
2. Capture both into the PR body's temp directory, so the paths on
   `--attach` and in the body match:

   ```bash
   rat shot --out <dir>/before.png …
   rat shot --out <dir>/after.png …
   ```

3. Read both images back before writing the caption. The caption says
   what the reviewer should see change, not that a screenshot is attached.
   A pair that looks the same is a pair that should not be attached.

When the change shows in motion — an animation, a key sequence that
redraws — attach the GIF `rat shot` leaves beside the PNG instead; `--attach`
takes it the same way.

## Finish

Report which command, size and config were captured, and anything that
could not be — a program that needs a real TTY vhs does not provide, a
config that would not load — rather than a screenshot of the wrong thing.
