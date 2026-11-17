---
name: <repo>-run
description: Starts <repo> and drives it to see a change working — the command that launches it, where it answers, how to stop it, the smoke run, and the feature map of what to look at. Load before calling a behaviour change done and before committing it.
when_to_use: When a change to <repo> alters what it does and has to be seen running, or the user asks to start or smoke it — "起動して", "動かして確認して", "smoke 回して", "<repo> 立ち上げて".
---

<!--
Skeleton for the repository's run skill (baseline step 8). Copy it to
.claude/skills/<repo>-run/SKILL.md, with assets/features.md as references/features.md next
to it, and link .agents/skills/<repo>-run to ../../.claude/skills/<repo>-run so codex finds
the same skill. Keep the name <repo>-run: `run` and `verify` are Claude Code's built-in
skills and would shadow it. Replace every <placeholder>, delete every comment. The body is
English like the house skills; the trigger phrases are in the language the user types.
-->

# Running <repo>

## Start

```bash
just run
```

<!-- What it prints once it is ready, and where it answers: the URL and port, the socket,
the prompt. What it needs first (an environment variable, a database, a seed) and the
command that provides it. -->

Ready when <the line it prints or the URL that answers>. It needs <what, and how to get it>.

## Stop

<!-- How to stop it so nothing is left running: Ctrl-C, `just stop`, the container to remove. -->

<How to stop it>.

## Smoke

```bash
just smoke
```

It starts the app on its own, drives the rows under "Smoke" in
`references/features.md`, stops it, and exits non-zero when a row breaks. Run
it before committing a change that alters behaviour. It is not the whole map:
the rest is walked by hand, a row at a time, when a change touches it.

## Look at a change

Pick two rows from `references/features.md`: one the diff touches and one it
does not. Start the app, follow each row's path, and check what the row says
to see. Look with the tool that fits what the row shows — the
`browser-verify` skill for a page, the `terminal-verify` skill for what a
terminal draws, the command's own output for a CLI. Report the two rows and
what was seen.

When a change adds a feature or moves the way to reach one, update its row in
the same commit; a map that lags is a map nobody walks.
