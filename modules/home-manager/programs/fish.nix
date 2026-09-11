{ lib, packages, ... }:
let
  # abbr は { cmd, desc } で持ち、shellAbbrs とパレットを出す `pal` 関数の両方をここから
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
        gq = {
          cmd = "ghq-cd";
          desc = "ghq のリポジトリへ移動（Ctrl+G でも可）";
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
        ccA = {
          cmd = "claude --permission-mode auto";
          desc = "auto mode で起動。権限を自動判断させる";
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

  # 行は "種別:::キー:::コマンド:::説明"。区切りはどの列にも現れない ":::"。
  # 種別はパレットが選択後の動作を決めるのに使う
  abbrRows = lib.concatMap (
    g: lib.mapAttrsToList (k: v: ''"abbr:::${k}:::${v.cmd}:::${v.desc}"'') g.items
  ) abbrGroups;

  # meta.description は fish の "..." の中に置くので、そこで解釈される 3 文字を潰す。
  # 現状どのパッケージも含まないが、パッケージが増えたときに壊れる場所にしたくない
  escape = lib.replaceStrings [ "\\" "\"" "$" ] [ "\\\\" "\\\"" "\\$" ];

  # AIDEV-NOTE: description なしを落とすのは hm-session-vars など home-manager の内部物を消すため
  # ツールにキーはないので、キー列は空にする
  toolRows = map (p: ''"tool:::${""}:::${lib.getName p}:::${escape p.meta.description}"'') (
    lib.filter (p: (p.meta.description or "") != "") packages
  );

  rows = abbrRows ++ toolRows;
in
{
  enable = true;
  shellAbbrs = lib.mapAttrs (_: v: v.cmd) allItems;
  functions = {
    # AIDEV-NOTE: commandline はコマンド実行中には効かないので、pal は Ctrl+P からしか使えない
    pal = {
      description = "キーバインド・abbr・入れたツールを fzf から引く (Ctrl+P)";
      body = ''
        # AIDEV-NOTE: 空のコマンド置換は引数ゼロ個に消えるので、--query には必ず変数をクォートで渡す
        set -l query (string join ' ' -- $argv)
        set -l rows${lib.concatMapStrings (row: " \\\n    ${row}") rows}

        # キーバインドだけは定義を書き写さずに bind から拾う。--preset は fish と vi の
        # 組み込みで数百行あり、-M の行は default 側と同じ内容の重複
        for line in (bind | string match -rv -- '^#|--preset|^bind -M ')
            set -l f (string split -m 2 ' ' -- $line)
            # functions -v -D の 5 行目が description (fish のドキュメントによる)
            set -l detail (functions -v -D $f[3] 2>/dev/null)
            set -l desc $detail[5]
            test "$desc" = n/a; and set desc ""
            set -a rows (string join ':::' key $f[2] $f[3] $desc)
        end

        # 表示列のうしろにタブで種別とコマンドを隠す。fzf は選んだ行をそのまま返すので、
        # --with-nth で見せる列を絞っても隠した側は取り出せる
        set -l picked (
            for row in $rows
                set -l f (string split ':::' -- $row)
                printf '%-4s  %-12s  %-22s  %s\t%s\t%s\n' \
                    $f[1] $f[2] $f[3] $f[4] $f[1] $f[3]
            end | sort | fzf --delimiter \t --with-nth 1 \
                --query "$query" \
                --header 'Enter: キーは実行 / abbr と tool はプロンプトへ'
        )

        if test -z "$picked"
            commandline -f repaint
            return
        end

        set -l field (string split \t -- $picked)
        switch $field[2]
            case key
                commandline -f repaint
                # 引数を取らない widget なのでそのまま呼ぶ
                $field[3]
            case '*'
                # abbr は引数を前提にしているものが多く、tool はパッケージ名とコマンド名が
                # 食い違うことがある (ripgrep -> rg)。どちらも実行せず打ちかけの状態にする
                commandline -r $field[3]
                commandline -f repaint
        end
      '';
    };
    # AIDEV-NOTE: root が private と work の 2 つあるので --full-path。相対パスからは root を戻せない
    ghq-cd = {
      description = "ghq 管理下のリポジトリを fzf で選んで移動する";
      body = ''
        set -l dir (ghq list --full-path | fzf --preview 'eza --icons -1 --color=always {}')
        test -n "$dir"; and cd $dir
        commandline -f repaint
      '';
    };
  };
  interactiveShellInit = ''
    fish_vi_key_bindings

    # fzf 側が insert にも張っているのに合わせ、default モードにも同じキーを置く
    bind \cp pal
    bind -M insert \cp pal
    bind \cg ghq-cd
    bind -M insert \cg ghq-cd

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
