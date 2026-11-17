# Feature map

<!--
Skeleton for .claude/skills/<repo>-run/references/features.md, the run skill's list of what
<repo> does and how to see each thing working. Write it in the repo's language, replace
every <placeholder>, delete every comment. One row per thing a user relies on, found from
the README, the routes or the commands, not from memory. Three columns:

- Feature: what a user would call it.
- How to reach it: the URL path, the clicks, the command and its input, from a fresh start.
- What to see: what must appear when it works, concrete enough that a missing one is noticed.

This is also the shared vocabulary for an instruction ("walk the login row") and the
scoring list for an end-to-end test kept from a walked flow.
-->

## Smoke

<!-- The few rows that break first when the app is broken. `just smoke` drives exactly
these, so keep it to a handful; the rest of the map goes under "Everything else". -->

| Feature     | How to reach it           | What to see                  |
| ----------- | ------------------------- | ---------------------------- |
| <Home page> | <open `/`>                | <the list of items renders>  |
| <Sign in>   | <`/login`, submit a user> | <the user's name in the bar> |

## Everything else

| Feature    | How to reach it               | What to see                       |
| ---------- | ----------------------------- | --------------------------------- |
| <Add item> | <`/items/new`, fill, save>    | <the item at the top of `/items`> |
| <Export>   | <`<cli> export --format csv`> | <a CSV with a header row>         |
