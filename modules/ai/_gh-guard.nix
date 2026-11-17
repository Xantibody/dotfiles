# ruleset・保護・contents・merges を書き換える gh 操作に確認を挟む PreToolUse hook (gh-guard.sh)。
# agent はユーザーの admin トークンで動き、ruleset の bypass も効くので、permission の分類器に
# 任せず決定的に止める。ユーザー起点の書き込み (branch-protection skill など) は確認 1 回で通る。
#
# claude feature の一部なので `_` 始まりにして import-tree から外し、claude.nix が imports で読む。
# settings.json の PreToolUse Bash が名前で呼ぶ。
# AIDEV-NOTE: `Bash(gh api * rulesets*)` のような途中ワイルドカードの ask は採らない。引数の順序や -X の位置で一致が変わる
{ ... }:
let
  mkGhGuard =
    pkgs:
    pkgs.writeShellApplication {
      name = "gh-guard";
      runtimeInputs = [ pkgs.jq ];
      text = builtins.readFile ./gh-guard.sh;
    };

  ask = command: {
    name = "ask: ${command}";
    input.tool_input.command = command;
    expect = ''.hookSpecificOutput.permissionDecision == "ask" and .hookSpecificOutput.hookEventName == "PreToolUse"'';
  };
  pass = command: {
    name = "pass: ${command}";
    input.tool_input.command = command;
    expect = ". == null";
  };
in
{
  flake.modules.homeManager.gh-guard =
    { pkgs, ... }:
    {
      home.packages = [ (mkGhGuard pkgs) ];
    };

  perSystem =
    { pkgs, ... }:
    {
      checks.gh-guard = import ./_hook-check.nix pkgs {
        name = "gh-guard";
        hook = mkGhGuard pkgs;
        cases =
          map ask [
            "gh api -X PUT repos/o/r/contents/README.md -f message=x -f content=eA=="
            "gh api --method PUT repos/o/r/contents/a/b"
            "gh api --method=DELETE repos/o/r/rulesets/12823463"
            "gh api -XPATCH /repos/o/r/rulesets/1"
            "gh api -X put repos/{owner}/{repo}/branches/main/protection --input p.json"
            "gh api repos/o/r/rulesets --input ruleset.json"
            "gh api repos/o/r/branches/main/protection/required_status_checks -F strict=true"
            "gh api orgs/o/rulesets -f name=x"
            "gh api repos/o/r/merges -f base=main -f head=feat"
            "gh api -X PATCH repos/o/r/git/refs/heads/main -f sha=abc"
            "gh api -X PUT repos/o/r/pulls/12/merge"
            "gh api -H 'Accept: application/vnd.github+json' -X DELETE repos/o/r/branches/main/protection"
            "gh api graphql -f query='mutation { createCommitOnBranch(input: {}) { commit { oid } } }'"
            "rtk gh api -X PUT repos/o/r/contents/x"
            "rtk proxy gh api -X PUT repos/o/r/contents/x"
            "verify-gate run -- gh api -X PUT repos/o/r/contents/x"
            "GH_TOKEN=t gh api -X PUT repos/o/r/contents/x"
            "env GH_HOST=github.com gh api -X PUT repos/o/r/contents/x"
            "/opt/homebrew/bin/gh api -X PUT repos/o/r/contents/x"
            "cd repo && gh api -X PUT repos/o/r/contents/x"
            "bash -c 'gh api -X PUT repos/o/r/contents/x'"
            "echo $(gh api -X DELETE repos/o/r/rulesets/1)"
            "gh pr merge --admin"
            "gh pr merge 12 --squash --admin"
            "gh pr merge --auto --squash"
            "rtk gh pr merge --auto"
            "git status; gh pr merge 3 --admin"
          ]
          ++ map pass [
            ""
            "gh api repos/o/r/rulesets"
            "gh api repos/o/r/contents/README.md --jq .content"
            "gh api -X GET repos/o/r/branches/main/protection"
            "gh api --method GET repos/o/r/rulesets -f includes_parents=true"
            "gh api repos/o/r/pulls/12/merge"
            "gh api -X POST repos/o/r/issues -f title=x"
            "gh api -X PATCH repos/o/r -f description=x"
            "gh api graphql -f query='query { viewer { login } }'"
            "gh api graphql -f query='mutation { addComment(input: {}) { clientMutationId } }'"
            "gh pr merge 12 --squash"
            "gh pr view 12 --json mergeStateStatus"
            "gh ruleset list"
            "rtk gh api repos/o/r/contents/x"
            "git log --grep contents"
            "echo gh api -X PUT repos/o/r/contents/x"
          ];
      };
    };
}
