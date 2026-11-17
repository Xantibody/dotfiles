# 編集前に anchor を見せる PreToolUse hook (anchors-hook.sh)。
# 「編集前に anchor を読む」を指示ではなく仕組みにする。settings.json が Edit / Write に名前で登録する。
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
  hack = "HACK" + "(https://example.com/1): drop after the fix";
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
          and .hookSpecificOutput.additionalContext == ${
            builtins.toJSON (
              "Anchors in ${dir} (read before editing; update the one above code you change):\n"
              + builtins.concatStringsSep "\n" lines
            )
          }
        '';
      };
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
        ];
      };
    };
}
