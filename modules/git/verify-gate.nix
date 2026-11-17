# コミット前に検証したかを Verified-by trailer で残す commit gate (verify-gate.sh)。
# hook は全リポジトリ共通の git 設定に載るが、動くのは `git config verify.gate` を立てたリポジトリだけ。
# 今は dotfiles だけを observe にし、止めずに記録して誤検知を見る。
# checks.verify-gate が一時リポジトリでコミットを切って trailer を確かめる。分岐を足したら場面も足す。
#
# AIDEV-NOTE: Claude Code の PreToolUse hook にはしない。`rtk hook claude` が同じ Bash に updatedInput を返すので重なり方が定まらず、人の手のコミットにも効かない
# AIDEV-NOTE: core.hooksPath ではなく設定の hook.<name> で足す。hooksPath は各リポジトリの .git/hooks を覆い隠すが、設定の hook はそれと並んで走る
{ config, ... }:
let
  hm = config.flake.modules.homeManager;

  mkVerifyGate =
    pkgs:
    pkgs.writeShellApplication {
      name = "verify-gate";
      runtimeInputs = [
        pkgs.git
        pkgs.coreutils
        pkgs.gnugrep
      ];
      text = builtins.readFile ./verify-gate.sh;
    };

  # gate を observe で動かすリポジトリ。gitdir: の末尾の / は配下すべて (ha の worktree を含む) に当たる
  observed = [ "~/Repository/private/github.com/Xantibody/dotfiles/" ];
in
{
  flake.modules.homeManager.verify-gate =
    { lib, pkgs, ... }:
    let
      verifyGate = mkVerifyGate pkgs;
    in
    {
      home.packages = [ verifyGate ];

      programs.git.settings.hook.verify-gate = {
        event = "commit-msg";
        command = "${lib.getExe verifyGate} commit-msg";
      };

      programs.git.includes = map (dir: {
        condition = "gitdir:${dir}";
        contents.verify.gate = "observe";
      }) observed;
    };

  flake.modules.darwin.verify-gate = {
    home-manager.sharedModules = [ hm.verify-gate ];
  };

  flake.modules.nixos.verify-gate = {
    home-manager.sharedModules = [ hm.verify-gate ];
  };

  perSystem =
    { pkgs, lib, ... }:
    {
      checks.verify-gate =
        pkgs.runCommand "verify-gate"
          {
            nativeBuildInputs = [
              pkgs.git
              (mkVerifyGate pkgs)
            ];
          }
          ''
            export HOME=$TMPDIR GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=$TMPDIR/gitconfig
            git config --global user.name test
            git config --global user.email test@example.com
            git config --global init.defaultBranch main
            git config --global hook.verify-gate.event commit-msg
            git config --global hook.verify-gate.command "${lib.getExe (mkVerifyGate pkgs)} commit-msg"

            failed=0
            fail() {
              failed=1
              echo "FAIL $1"
              echo "  want: $2"
              echo "  got:  $3"
            }
            trailers() {
              git log -1 --format='%(trailers:key=Verified-by,valueonly,separator=%x2C)'
            }
            expect_trailers() {
              local got
              got=$(trailers)
              [[ $got == "$2" ]] || fail "$1" "$2" "$got"
            }
            n=0
            fresh() {
              n=$((n + 1))
              mkdir "$TMPDIR/r$n"
              cd "$TMPDIR/r$n"
              git init -q
              echo base >base
              git add base
              git commit -q -m base
              [[ -z ''${1:-} ]] || git config verify.gate "$1"
            }

            fresh
            verify-gate run -- true 2>/dev/null
            echo a >a && git add a && git commit -q -m "gate unset"
            expect_trailers "gate unset adds nothing" ""

            fresh observe
            echo a >a && git add a && git commit -q -m "no run"
            expect_trailers "no verification records none" "none"

            fresh observe
            echo a >a
            verify-gate run -- true 2>/dev/null
            verify-gate run -- echo ok >/dev/null 2>&1
            git add a && git commit -q -m "verified"
            expect_trailers "passing commands on the committed tree are recorded" "true,echo ok"

            fresh observe
            mkdir sub && echo a >sub/a
            (cd sub && verify-gate run -- true 2>/dev/null)
            git add sub && git commit -q -m "from a subdir"
            expect_trailers "a run in a subdir names the dir" "true (in sub)"

            fresh observe
            echo a >a
            verify-gate run -- false 2>/dev/null && fail "run passes the exit code" 1 0
            git add a && git commit -q -m "failed"
            expect_trailers "a failing command is not recorded" "none"

            fresh observe
            echo a >a
            verify-gate run -- true 2>/dev/null
            echo changed >a
            git add a && git commit -q -m "changed after the run"
            expect_trailers "a change after the run records none" "none"

            fresh observe
            echo a >a && echo b >b
            verify-gate run -- true 2>/dev/null
            git add a && git commit -q -m "part of the tree"
            expect_trailers "committing part of the verified tree records none" "none"

            fresh observe
            echo a >a && git add a
            verify-gate run -- true 2>/dev/null
            echo more >>base
            verify-gate run -- echo after-edit >/dev/null 2>&1
            git commit -q -a -m "commit -a"
            expect_trailers "commit -a is matched against the tree it commits" "echo after-edit"

            fresh observe
            echo a >a && git add a && git commit -q -m "first"
            verify-gate run -- true 2>/dev/null
            git commit -q --amend --no-edit
            expect_trailers "amend replaces the trailer" "true"
            git commit -q --amend -m "$(git log -1 --format=%B)"
            expect_trailers "amend with the trailer in the message keeps one" "true"

            fresh observe
            printf '%s\n' '#!/bin/sh' 'echo ran >"$(git rev-parse --git-dir)/traditional"' >.git/hooks/commit-msg
            chmod +x .git/hooks/commit-msg
            echo a >a && git add a && git commit -q -m "with a repo hook"
            [[ -f .git/traditional ]] || fail "the repo's own commit-msg hook still runs" ran "not run"
            expect_trailers "the trailer is added next to the repo hook" "none"

            fresh observe
            echo a >a && git add a
            if GIT_EDITOR=true git commit -q 2>/dev/null; then
              fail "an empty message still aborts the commit" "commit refused" "committed: $(git log -1 --format=%B)"
            fi

            fresh enforce
            echo a >a && git add a
            if git commit -q -m "enforce" 2>err; then
              fail "enforce is refused until it exists" "commit refused" "committed"
            elif ! grep -q "enforce is not implemented" err; then
              fail "enforce says what to fix" "not implemented message" "$(cat err)"
            fi

            ((failed == 0)) || exit 1
            touch $out
          '';
    };
}
