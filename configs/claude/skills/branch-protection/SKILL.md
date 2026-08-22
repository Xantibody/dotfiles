---
name: branch-protection
description: Applies a GitHub branch protection ruleset to a repository that has none, at the point the repository stops being disposable. Use this skill when the user cuts a version tag, says a PoC or prototype is finished, publishes a repo, or asks about branch protection, rulesets, main への直 push, "PoCが終わった", "tagを切った", "リポジトリを保護して", "ブランチ保護". Also use it right after the version skill creates a tag, to check whether protection is still missing.
---

# Branch Protection (branch-protection)

A brand-new repository should have no protection — every guard rail is friction
while you are still deciding whether the thing is worth keeping. The cost only
inverts once the repository becomes something you maintain: a tag exists, the
PoC concluded, someone else might clone it. That crossing is what this skill
acts on, and it is why the trigger is a milestone rather than repository
creation.

Protection is per-repository. A personal account has no organization-wide
rulesets, so nothing propagates on its own — neither to sibling repositories
nor to newly created ones. Each repository is opted in deliberately, one at a
time.

## Before touching anything

Read the current state. Two independent layers exist and either one can block a
push on its own, so checking only one gives a false picture:

```bash
gh api repos/<owner>/<repo>/rulesets --jq '.[] | {id, name, enforcement}'
gh api repos/<owner>/<repo>/branches/<default-branch>/protection
```

- `404 Branch not protected` from the second call means no legacy protection.
- `403 Upgrade to GitHub Pro` from either means the repository is **private on a
  Free plan**, where neither layer is available. Stop, say so plainly, and
  suggest the alternative: making the repo public, or relying on local
  discipline. Do not attempt the write — it will fail.

**If a ruleset already exists, do not overwrite it.** Report what it contains
against what this skill would apply, and let the user decide. An existing
ruleset usually encodes a decision someone made on purpose; silently replacing
it destroys that intent.

While reading, check the ruleset's `conditions.ref_name.include`. An empty
array matches no branch at all, so the ruleset is inert despite looking active
in the UI — worth flagging as a bug, because it reads as protection that isn't
there.

## What to apply

Build the rule list from what the repository actually is, not from a fixed
template.

| Rule                     | When to include                                                                                                        |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `deletion`               | Always. Prevents losing the default branch to a mistyped command; costs nothing in daily work.                         |
| `non_fast_forward`       | Always. Blocks force-push over shared history, same reasoning.                                                         |
| `pull_request`           | Only when review has a reader. A single-maintainer repository gains nothing but ceremony — the author is the reviewer. |
| `required_status_checks` | Only when CI exists **and** you can name a check that really runs.                                                     |

The two "always" rules are about accidents; the other two are about process.
Keeping them separate is what lets a solo repository be protected against
mistakes while still allowing direct pushes to the default branch.

Never invent a status check context. A required check that never reports leaves
every PR permanently unmergeable. Take the name from a run that has actually
completed:

```bash
gh api repos/<owner>/<repo>/commits/<default-branch>/check-runs --jq '.check_runs[].name'
```

If nothing has run yet, leave `required_status_checks` out and revisit after CI
runs once.

## Applying

Create the ruleset with a heredoc — the JSON is nested past what `-f` handles:

```bash
gh api -X POST repos/<owner>/<repo>/rulesets --input - <<'JSON'
{
  "name": "main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"}
  ],
  "bypass_actors": [
    {"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}
  ]
}
JSON
```

`~DEFAULT_BRANCH` follows a rename; a literal `"main"` silently stops matching
if the branch is ever renamed. Prefer it.

`actor_id: 5` is the repository admin role. Including it means the owner can
still push through the ruleset in an emergency, at the cost of a
`remote: Bypassed rule violations` warning on every such push. Drop the
`bypass_actors` array entirely when the point is to stop yourself, and keep it
when the ruleset is there to catch accidents rather than to enforce process.

Adding `pull_request` needs the parameter block, since an omitted count is not
the same as zero:

```json
{ "type": "pull_request", "parameters": { "required_approving_review_count": 0 } }
```

Read the ruleset back after writing and show the user the resulting rule list.
The API accepts a well-formed body that matches nothing, so a successful
response is not evidence that the protection is live.

## After a tag

When this skill runs off the back of a release, do the check but keep it to one
line if protection already exists — a release is not the moment for a long
detour. If it is missing, propose the rule set and apply it only on
confirmation.
