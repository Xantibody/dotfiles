# nix daemon そのものの設定。
let
  # 上流の flake が publish しているキャッシュ。自前ビルドを避けるためだけの設定。
  # substituters ではなく extra- を使うのは cache.nixos.org のデフォルトを潰さないため。
  caches = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
in
{
  flake.modules.darwin.nix =
    { config, pkgs, ... }:
    let
      # 世代を 30 日残す。nixos 側の 3 日より長いのは、macOS は業務で使っていて
      # 壊れたときに戻れる幅が要るため。
      keep = "30d";

      # GC は 3 段を 1 本のスクリプトに閉じ込める。nix.gc.automatic は root の
      # nix-collect-garbage を撃つだけで前後に何も挟めず、下の 2 つの回避策を
      # 順番どおりに通せないので使っていない。
      garbageCollect = pkgs.writeShellApplication {
        name = "nix-gc-darwin";
        runtimeInputs = [ config.nix.package ];
        text = ''
          user="${config.my.user.name}"
          home="${config.my.user.home}"

          # HACK(https://github.com/NixOS/nix/issues/8508): root の nix-collect-garbage は
          # XDG 配下 (~/.local/state/nix/profiles) の home-manager 世代を掃除しない。
          # 残った世代が GC root になって GUI アプリを掴み続けるので user で 1 度走らせる。
          #
          # sudo に HOME=... を直接渡さないのは env_reset に弾かれるため。PATH も
          # secure_path に差し替わるので、渡す側の nix は絶対パスで指す。
          #
          # 目的は世代の削除だけ。続けて走る GC は下の macl 回避策を経ていないので
          # 止まりうるが、世代は GC より先に消えているので失敗させて先へ進む。
          /usr/bin/sudo -u "$user" env HOME="$home" \
            ${config.nix.package}/bin/nix-collect-garbage --delete-older-than ${keep} || true

          # HACK(https://github.com/NixOS/nix/issues/6765): Finder から起動した .app には
          # com.apple.macl が付き、root でも chmod できないため GC が最初の 1 件で止まる。
          # unlink は通るので、GC が消そうとしている dead path だけ先に rm しておく。
          dead=$(mktemp)
          trap 'rm -f "$dead"' EXIT
          nix-store --gc --print-dead > "$dead"

          while IFS= read -r path; do
            # rm -rf に渡す前に、store path であることと dead であることを二重に確かめる
            case "$path" in
              /nix/store/*) ;;
              *) continue ;;
            esac
            if [ ! -d "$path/Applications" ]; then continue; fi

            for app in "$path"/Applications/*.app; do
              if [ ! -e "$app" ]; then continue; fi
              # darwin-system や system-applications は symlink ツリーで、
              # 実体を指しているだけなので chmod は要らない。消す対象は実体だけ。
              if [ -L "$app" ]; then continue; fi
              if /usr/bin/xattr "$app" 2>/dev/null | grep -q com.apple.macl; then
                echo "pruning macl-locked path: $path"
                rm -rf "$path"
                break
              fi
            done
          done < "$dead"

          nix-collect-garbage --delete-older-than ${keep}
        '';
      };
    in
    {
      # nix-darwin が作る nixbld グループの gid。既存インストールに合わせて固定してある
      ids.gids.nixbld = 350;

      nix = {
        optimise.automatic = true;
        settings = {
          experimental-features = "nix-command flakes";
          max-jobs = 8;
        }
        // caches;
      };

      launchd.daemons.nix-gc-darwin.serviceConfig = {
        ProgramArguments = [ "${garbageCollect}/bin/nix-gc-darwin" ];
        # nix.gc.interval の既定と同じ毎週日曜 3:15。--print-dead が store 全体を
        # 舐めるので数分かかる。日次で回すほどの量は出ない。
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 15;
            Weekday = 7;
          }
        ];
        StandardOutPath = "/var/log/nix-gc-darwin.log";
        StandardErrorPath = "/var/log/nix-gc-darwin.err";
      };
    };

  flake.modules.nixos.nix = {
    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      }
      // caches;
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 3d";
      };
    };
  };
}
