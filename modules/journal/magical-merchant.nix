# 自作のジャーナル (github:Xantibody/magical-merchant)。
# アプリと CLI、同期設定は darwin / nixos module 側が持っている。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
  service = {
    enable = true;
    cli.enable = true;
    workersUrl = "https://magical-merchant.sync.r-aizawa.com";
  };
  # CI が main ごとに置く .app と cli。flake.nix 側で nixpkgs を
  # follows させていないのは、この cache に当てるため
  cache = {
    extra-substituters = [ "https://magical-merchant.cachix.org" ];
    extra-trusted-public-keys = [
      "magical-merchant.cachix.org-1:r8cvPKg3xGAINHclAor7fWiS7YK5pZ1Bxs4XjGnyvp0="
    ];
  };
in
{
  flake.modules.homeManager.magical-merchant = {
    # abbr は CLI のサブコマンドをそのまま略したもので、
    # 引数を足す余地を残すため -m や --last は畳み込んでいない
    # AIDEV-NOTE: scrawl は mms* 。mms (show) と紛らわしいが、旧名の mmt* を残すと t が何の頭文字でもなくなる
    my.shell.abbr = {
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
      mmsa = {
        cmd = "magical-merchant scrawl add";
        desc = "今日の Scrawl に追記";
      };
      mmss = {
        cmd = "magical-merchant scrawl show";
        desc = "ある日の Scrawl を表示";
      };
      mmsd = {
        cmd = "magical-merchant scrawl dates";
        desc = "記録のある日を新しい順に一覧";
      };
    };
  };

  flake.modules.darwin.magical-merchant =
    { lib, pkgs, ... }:
    {
      imports = [ inputs.magical-merchant.darwinModules.default ];

      # stabilizeApp は下の cachix から来た .app を再署名するだけで、組み直しはしない。
      # 素の ad-hoc 署名だと通知などの許可が rebuild ごとに飛ぶ
      nixpkgs.overlays = [
        (final: _prev: {
          magical-merchant =
            (final.callPackage inputs.nix-mac-app-identity { }).stabilizeApp
              inputs.magical-merchant.packages.${final.stdenv.hostPlatform.system}.default;
        })
      ];

      services.magical-merchant = service;

      nix.settings = cache;

      my.dock.apps = lib.mkOrder 300 [ "${pkgs.magical-merchant}/Applications/Magical Merchant.app" ];

      home-manager.sharedModules = [ hm.magical-merchant ];
    };

  flake.modules.nixos.magical-merchant =
    { config, ... }:
    {
      imports = [ inputs.magical-merchant.nixosModules.default ];

      # NixOS には console user が決まらないので、sync-config.json を置く先を名指しする
      services.magical-merchant = service // {
        user = config.my.user.name;
      };

      # Linux 版はログインのトークンを Secret Service に置くので、それを提供する daemon が要る
      services.gnome.gnome-keyring.enable = true;
      # keyring が既定で連れてくる SSH agent は networking の programs.ssh.startAgent と共存できない
      services.gnome.gcr-ssh-agent.enable = false;

      nix.settings = cache;

      home-manager.sharedModules = [ hm.magical-merchant ];
    };
}
