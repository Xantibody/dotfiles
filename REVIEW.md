# REVIEW.md

Checks a change calls up by what it touches. The reliability-checklist
skill reads this table from `origin/main` and prints the rows a diff hits;
each row comes from an incident, named by the commit whose body tells what
broke. A Trigger is a path glob (`**` crosses directories) or a `/regex/`
on the added and removed lines.

| Trigger                                                                       | Check                                                                                                                                                                                                                                                                                                                                | Incident  |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| `.github/workflows/darwin.yml`, `.github/actions/setup-nix/**`, `flake.lock`  | `darwin.yml` still builds the darwin toplevel on aarch64-darwin for every PR and every push to main, with no path filter (it is a required check). After a lock update, wait for that build rather than `check.yml` alone: evaluation passes when a package fails to compile only on darwin, as `_7zz` 26.02 in nixpkgs f496248 did. | `49f2f2d` |
| `modules/flake/checks.nix`, `modules/hosts/**`, `.github/workflows/check.yml` | Every host in `darwinConfigurations` and `nixosConfigurations` still has a `checks.eval-<host>` that `check.yml` runs. `nix flake check` does not evaluate `darwinConfigurations` on its own, so a broken Mac stays green without it.                                                                                                | `ba2d720` |
