# SKK 日本語入力。辞書サーバ (yaskkserv2) とその辞書、常駐の設定をまとめる。
#
# 辞書は nixpkgs の skkDictionaries から derivation の中で作る。以前は 4.3 MB の
# SKK-JISYO.L を repo に入れ、`just create-JISYO` を手で叩いて ~/.skk/ に変換結果を
# 置く手順だった。手元にファイルが無ければ常駐が黙って失敗し、更新の手段も無い。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;

  # nixpkgs に yaskkserv2 が無いので自前で組む
  overlay = _final: prev: {
    yaskkserv2 = prev.rustPlatform.buildRustPackage {
      pname = "yaskkserv2";
      version = "unstable-2026-03-20";

      src = prev.fetchFromGitHub {
        owner = "wachikun";
        repo = "yaskkserv2";
        # AIDEV-NOTE: rev は commit に固定する。"master" だと upstream が進んだ時点で hash mismatch で落ちる
        rev = "f5bc4590c798c591e9861e02ea2e12d227a047ed";
        hash = "sha256-6XE/ujU+B/gTd+S4LWQRFk9JbZz1z9SR+Nr7cARqLtY=";
      };

      cargoHash = "sha256-uetEHSv1HMU7KfAPwki1EiaR6zmgRehJL2OGQ/KC/Xc=";

      nativeBuildInputs = [ prev.pkg-config ];
      buildInputs = [ prev.openssl ];

      doCheck = false;
    };
  };

  # AIDEV-NOTE: skkDictionaries を全部は入れない。s/m は L の部分集合、jis*・itaiji*・
  # mazegaki は読みから稀な漢字を大量に候補へ出し、pinyin・china_taiwan・edict・assoc は
  # 日本語変換とは用途が違う。
  jisyoOf =
    pkgs:
    pkgs.lib.attrVals [
      "l"
      "emoji"
      "jinmei"
      "fullname"
      "geo"
      "station"
      "propernoun"
      "zipcode"
      "law"
      "okinawa"
    ] pkgs.skkDictionaries;

  # EUC-JP では絵文字を表せないので UTF-8 で作る。応答も UTF-8 になる
  dictionaryOf =
    pkgs:
    pkgs.runCommand "dictionary.yaskkserv2" { } ''
      ${pkgs.yaskkserv2}/bin/yaskkserv2_make_dictionary \
        --utf8 \
        --dictionary-filename=$out \
        ${pkgs.lib.concatMapStringsSep " " (d: "${d}/share/skk/*") (jisyoOf pkgs)}
    '';
in
{
  flake.modules.homeManager.skk =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.skk.dictionary = lib.mkOption {
        type = lib.types.package;
        description = "yaskkserv2 が読む変換済み辞書。Linux の常駐 (skk-linux) がこれを指す";
      };

      config = {
        my.skk.dictionary = dictionaryOf pkgs;
        home.packages = [ pkgs.yaskkserv2 ];
      };
    };

  flake.modules.darwin.skk =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ overlay ];
      home-manager.sharedModules = [ hm.skk ];

      launchd.user.agents.yaskkserv2.serviceConfig = {
        Program = "${pkgs.yaskkserv2}/bin/yaskkserv2";
        ProgramArguments = [
          "${pkgs.yaskkserv2}/bin/yaskkserv2"
          # 既定では fork して親が exit 0 するため、KeepAlive の launchd が
          # 「終了した」と見なして 10 秒ごとに再スポーンし、新しい方は
          # ポート 1178 が使用中で即終了する無限ループになる (実測 82 回/5 分)。
          "--no-daemonize"
          "${dictionaryOf pkgs}"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/tmp/yaskkserv2.log";
        StandardErrorPath = "/tmp/yaskkserv2.err";
      };
    };

  # darwin の launchd agent と同じ常駐を systemd の user service で張る
  flake.modules.homeManager.skk-linux =
    { config, pkgs, ... }:
    {
      systemd.user.services.yaskkserv2 = {
        Unit.Description = "yaskkserv2 SKK dictionary server";
        Service = {
          # 既定の fork だと親が即 exit して systemd が終了と見なすので、前面で動かす
          ExecStart = "${pkgs.yaskkserv2}/bin/yaskkserv2 --no-daemonize ${config.my.skk.dictionary}";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };

  flake.modules.nixos.skk = {
    nixpkgs.overlays = [ overlay ];
    home-manager.sharedModules = [
      hm.skk
      hm.skk-linux
    ];
  };
}
