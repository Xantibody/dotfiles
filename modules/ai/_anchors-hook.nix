# 編集前に anchor を見せる PreToolUse hook (anchors-hook.sh)。
# 「編集前に anchor を読む」を指示ではなく仕組みにする。anchor を減らす編集は確認を挟み、
# URL の無い HACK と新しい TODO / FIXME は警告する。settings.json が Edit / Write などに名前で登録する。
# checks.anchors-hook が分岐を _hook-check.nix の表で固定する。hook の分岐を足したら行も足す。
#
# claude feature の一部なので `_` 始まりにして import-tree から外し、claude.nix が imports で読む。
{ ... }:
let
  mkAnchorsHook =
    pkgs:
    pkgs.writeShellApplication {
      name = "anchors-hook";
      runtimeInputs = [
        pkgs.jq
        pkgs.ripgrep
      ];
      text = builtins.readFile ./anchors-hook.sh;
    };

  # fixture に書く anchor。リテラルで書くとこのファイル自体が modules/ai の anchor 一覧に載るので分けて組む
  note = "AIDEV" + "-NOTE: keep the order";
  note2 = "AIDEV" + "-NOTE: keep the order, the loader reads it top down";
  hack = "HACK" + "(https://example.com/1): drop after the fix";
  bareHack = "HACK" + "(later): drop the retry";
in
{
  flake.modules.homeManager.anchors-hook =
    { pkgs, ... }:
    {
      home.packages = [ (mkAnchorsHook pkgs) ];
    };

  perSystem =
    { pkgs, ... }:
    let
      # hook は dirname の dir を depth 1 で探すので、子 dir の anchor は親の一覧に出ない
      fixture = pkgs.runCommand "anchors-hook-fixture" { } ''
        mkdir -p $out/anchored/sub $out/plain
        printf '%s\n' 'set -e' '# ${note}' >$out/anchored/a.sh
        printf '%s\n' '{"cells": []}' >$out/anchored/nb.ipynb
        printf '%s\n' '# ${hack}' >$out/anchored/sub/deep.sh
        printf '%s\n' 'echo plain' >$out/plain/b.sh
      '';
      silent = name: input: {
        inherit name input;
        expect = ". == null";
      };
      anchors = name: input: dir: lines: {
        inherit name input;
        expect = ''
          .hookSpecificOutput.hookEventName == "PreToolUse"
          and .hookSpecificOutput.permissionDecision == null
          and .hookSpecificOutput.additionalContext == ${
            builtins.toJSON (
              "Anchors in ${dir} (read before editing; update the one above code you change):\n"
              + builtins.concatStringsSep "\n" lines
            )
          }
        '';
      };
      # anchor の行が減る編集はユーザーに確認させる
      ask = name: input: lost: {
        inherit name input;
        expect = ''
          .hookSpecificOutput.permissionDecision == "ask"
          and (.hookSpecificOutput.permissionDecisionReason | startswith("This edit removes ${toString lost} anchor line"))
        '';
      };
      # URL の無い HACK と足した TODO / FIXME は止めずに警告だけ返す
      warn = name: input: needles: {
        inherit name input;
        expect = ''
          .hookSpecificOutput.permissionDecision == null
          and (.hookSpecificOutput.additionalContext as $c
            | ($c | startswith("Comment warnings (not blocking):"))
            and ${
              builtins.concatStringsSep " and " (map (n: "($c | contains(${builtins.toJSON n}))") needles)
            })
        '';
      };
      a = "${fixture}/anchored/a.sh";
      b = "${fixture}/plain/b.sh";
      anchorsOfA = name: input: anchors name input "${fixture}/anchored" [ "a.sh:2:# ${note}" ];
    in
    {
      checks.anchors-hook = import ./_hook-check.nix pkgs {
        name = "anchors-hook";
        hook = mkAnchorsHook pkgs;
        cases = [
          (silent "no path in the input" { tool_input.command = "ls"; })
          (silent "path that does not exist" { tool_input.file_path = "${fixture}/anchored/new.sh"; })
          (silent "dir without anchors" { tool_input.file_path = "${fixture}/plain/b.sh"; })
          (anchors "Edit in a dir with an anchor" {
            tool_input.file_path = "${fixture}/anchored/a.sh";
          } "${fixture}/anchored" [ "a.sh:2:# ${note}" ])
          (anchors "NotebookEdit in a dir with an anchor" {
            tool_input.notebook_path = "${fixture}/anchored/nb.ipynb";
          } "${fixture}/anchored" [ "a.sh:2:# ${note}" ])
          (anchors "anchor in a subdir stays out of the parent" {
            tool_input.file_path = "${fixture}/anchored/sub/deep.sh";
          } "${fixture}/anchored/sub" [ "deep.sh:1:# ${hack}" ])

          (ask "Edit that drops an anchor" {
            tool_input = {
              file_path = a;
              old_string = "set -e\n# ${note}";
              new_string = "set -e";
            };
          } 1)
          (anchorsOfA "Edit that rewrites an anchor keeps the count" {
            tool_input = {
              file_path = a;
              old_string = "# ${note}";
              new_string = "# ${note2}";
            };
          })
          (ask "MultiEdit whose edits drop an anchor in total" {
            tool_input = {
              file_path = a;
              edits = [
                {
                  old_string = "# ${note}";
                  new_string = "";
                }
                {
                  old_string = "set -e";
                  new_string = "set -eu";
                }
              ];
            };
          } 1)
          (anchorsOfA "MultiEdit that moves an anchor keeps the count" {
            tool_input = {
              file_path = a;
              edits = [
                {
                  old_string = "# ${note}";
                  new_string = "";
                }
                {
                  old_string = "set -e";
                  new_string = "# ${note}\nset -e";
                }
              ];
            };
          })
          (ask "Write over a file is measured against the file on disk" {
            tool_input = {
              file_path = a;
              content = "set -e\n";
            };
          } 1)
          (anchorsOfA "Write that keeps the file's anchor" {
            tool_input = {
              file_path = a;
              content = "set -eu\n# ${note}\n";
            };
          })

          (warn "Edit that adds a HACK without an issue URL" {
            tool_input = {
              file_path = b;
              old_string = "echo plain";
              new_string = "# ${bareHack}\necho plain";
            };
          } [ "without an issue URL: # ${bareHack}" ])
          (silent "Edit that adds a HACK with an issue URL" {
            tool_input = {
              file_path = b;
              old_string = "echo plain";
              new_string = "# ${hack}\necho plain";
            };
          })
          (warn "Write of a new file with a TODO and a FIXME"
            {
              tool_input = {
                file_path = "${fixture}/plain/new.sh";
                content = "# TODO: split this\n# FIXME: quote the path\necho new\n";
              };
            }
            [
              "TODO/FIXME added: # TODO: split this"
              "TODO/FIXME added: # FIXME: quote the path"
            ]
          )
          (silent "Edit that keeps a TODO already there" {
            tool_input = {
              file_path = b;
              old_string = "# TODO: split this\necho plain";
              new_string = "# TODO: split this\necho done";
            };
          })
        ];
      };
    };
}
