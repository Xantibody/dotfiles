# SKK 日本語入力。辞書サーバ (yaskkserv2) とその辞書、常駐の設定をまとめる。
#
# 辞書は nixpkgs の SKK-JISYO.L から derivation の中で作る。以前は 4.3 MB の
# SKK-JISYO.L を repo に入れ、`just create-JISYO` を手で叩いて ~/.skk/ に変換結果を
# 置く手順だった。手元にファイルが無ければ常駐が黙って失敗し、更新の手段も無い。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;

  # nixpkgs に yaskkserv2 が無いので自前で組む
  overlay = _final: prev: {
    yaskkserv2 = prev.rustPlatform.buildRustPackage {
      pname = "yaskkserv2";
      version = "unstable-2025-10-12";

      src = prev.fetchFromGitHub {
        owner = "wachikun";
        repo = "yaskkserv2";
        rev = "master";
        hash = "sha256-6XE/ujU+B/gTd+S4LWQRFk9JbZz1z9SR+Nr7cARqLtY=";
      };

      cargoHash = "sha256-uetEHSv1HMU7KfAPwki1EiaR6zmgRehJL2OGQ/KC/Xc=";

      nativeBuildInputs = [ prev.pkg-config ];
      buildInputs = [ prev.openssl ];

      doCheck = false;
    };
  };

  dictionaryOf =
    pkgs:
    pkgs.runCommand "dictionary.yaskkserv2" { } ''
      ${pkgs.yaskkserv2}/bin/yaskkserv2_make_dictionary \
        --dictionary-filename=$out \
        ${pkgs.skkDictionaries.l}/share/skk/SKK-JISYO.L
    '';
in
{
  flake.modules.homeManager.skk =
    { config, lib, pkgs, ... }:
    {
      options.my.skk.dictionary = lib.mkOption {
        type = lib.types.package;
        description = "yaskkserv2 が読む変換済み辞書。常駐の起動行がこれを指す";
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

  flake.modules.nixos.skk = {
    nixpkgs.overlays = [ overlay ];
    home-manager.sharedModules = [ hm.skk ];
  };
}
