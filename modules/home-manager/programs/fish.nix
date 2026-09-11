{ lib, ... }:
let
  # abbr は { cmd, desc } で持ち、shellAbbrs と一覧を出す `abbrs` 関数の両方をここから
  # 生成する。一覧を別に手書きすると必ずずれるので、定義はこのリストひとつに寄せている。
  # グループの並びは表示順なので attrset ではなくリスト。
  abbrGroups = [
    {
      name = "基本";
      items = {
        n = {
          cmd = "nvim";
          desc = "エディタを開く";
        };
        ll = {
          cmd = "eza --icons -lahF";
          desc = "隠しファイル込みの詳細一覧";
        };
      };
    }
    {
      name = "git";
      items = {
        g = {
          cmd = "git";
          desc = "git 本体";
        };
        ga = {
          cmd = "git add";
          desc = "変更をステージ";
        };
        gc = {
          cmd = "git commit";
          desc = "コミット";
        };
        gp = {
          cmd = "git pull";
          desc = "リモートを取り込む";
        };
        gP = {
          cmd = "git push";
          desc = "リモートへ送る（大文字は取り消しにくい操作の印）";
        };
        gs = {
          cmd = "git status";
          desc = "作業ツリーの状態";
        };
      };
    }
    {
      name = "AI エージェント";
      items = {
        cc = {
          cmd = "claude";
          desc = "Claude Code";
        };
        ccp = {
          cmd = "claude --permission-mode plan";
          desc = "plan mode で起動";
        };
        ccD = {
          cmd = "claude --dangerously-skip-permissions";
          desc = "権限確認をすべて飛ばす（危険）";
        };

        # codex には plan mode がないので ccp 相当は置いていない。--sandbox read-only は
        # 「書けない」だけで計画を出す挙動ではなく、同じ p を当てると cc 側と誤解を生む
        cx = {
          cmd = "codex";
          desc = "Codex CLI";
        };
        cxr = {
          cmd = "codex resume";
          desc = "セッション再開。引数なしはピッカー、--last で直近";
        };
        cxD = {
          cmd = "codex --dangerously-bypass-approvals-and-sandbox";
          desc = "承認とサンドボックスを飛ばす（危険）";
        };
      };
    }
    {
      # abbr は CLI のサブコマンドをそのまま略したもので、
      # 引数を足す余地を残すため -m や --last は畳み込んでいない
      name = "magical-merchant";
      items = {
        mm = {
          cmd = "magical-merchant";
          desc = "ジャーナル本体";
        };
        mml = {
          cmd = "magical-merchant list";
          desc = "ノートを新しい順に一覧";
        };
        mmn = {
          cmd = "magical-merchant new";
          desc = "ノートを作る";
        };
        mme = {
          cmd = "magical-merchant edit";
          desc = "ノートを編集";
        };
        mms = {
          cmd = "magical-merchant show";
          desc = "ノートの本文を表示";
        };
        mmta = {
          cmd = "magical-merchant timeline add";
          desc = "今日のタイムラインに追記";
        };
        mmts = {
          cmd = "magical-merchant timeline show";
          desc = "ある日のタイムラインを表示";
        };
        mmtd = {
          cmd = "magical-merchant timeline dates";
          desc = "記録のある日を新しい順に一覧";
        };
      };
    }
  ];

  allItems = lib.foldl' (acc: g: acc // g.items) { } abbrGroups;

  widest = f: lib.foldl' (w: v: lib.max w (lib.stringLength v)) 0 (lib.mapAttrsToList f allItems);
  nameWidth = widest (k: _: k);
  cmdWidth = widest (_: v: v.cmd);

  # 行はグループ名から始める。区切りは cmd にも desc にも現れない ":::"
  rows = lib.concatMap (
    g: lib.mapAttrsToList (k: v: ''"${g.name}:::${k}:::${v.cmd}:::${v.desc}"'') g.items
  ) abbrGroups;
in
{
  enable = true;
  shellAbbrs = lib.mapAttrs (_: v: v.cmd) allItems;
  functions = {
    abbrs = {
      description = "定義済みの abbr を説明つきで一覧する";
      body = ''
        set -l query (string join ' ' -- $argv)
        set -l rows${lib.concatMapStrings (row: " \\\n    ${row}") rows}

        set -l shown_group ""
        for row in $rows
            set -l field (string split ':::' -- $row)
            if test -n "$query"; and not string match -qi -- "*$query*" $row
                continue
            end
            if test "$field[1]" != "$shown_group"
                set shown_group $field[1]
                set_color --bold
                echo -n $shown_group
                set_color normal
                echo
            end
            printf '  %-${toString nameWidth}s  %-${toString cmdWidth}s  %s\n' \
                $field[2] $field[3] $field[4]
        end
      '';
    };
  };
  interactiveShellInit = ''
    fish_vi_key_bindings

    # Nightfox Color Palette
    # Style: dayfox
    # Upstream: https://github.com/edeneast/nightfox.nvim/raw/main/extra/dayfox/dayfox.fish
    set -l foreground 3d2b5a
    set -l selection e7d2be
    set -l comment 837a72
    set -l red a5222f
    set -l orange 955f61
    set -l yellow ac5402
    set -l green 396847
    set -l purple 6e33ce
    set -l cyan 287980
    set -l pink a440b5

    # Syntax Highlighting Colors
    set -g fish_color_normal $foreground
    set -g fish_color_command $cyan
    set -g fish_color_keyword $pink
    set -g fish_color_quote $yellow
    set -g fish_color_redirection $foreground
    set -g fish_color_end $orange
    set -g fish_color_error $red
    set -g fish_color_param $purple
    set -g fish_color_comment $comment
    set -g fish_color_selection --background=$selection
    set -g fish_color_search_match --background=$selection
    set -g fish_color_operator $green
    set -g fish_color_escape $pink
    set -g fish_color_autosuggestion $comment

    # Completion Pager Colors
    set -g fish_pager_color_progress $comment
    set -g fish_pager_color_prefix $cyan
    set -g fish_pager_color_completion $foreground
    set -g fish_pager_color_description $comment
  '';
}
