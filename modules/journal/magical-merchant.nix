# 自作のジャーナル (github:Xantibody/magical-merchant)。
# CLI とノートを同期する常駐サービスを darwin module 側が持っている。
{ inputs, config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.magical-merchant = {
    # abbr は CLI のサブコマンドをそのまま略したもので、
    # 引数を足す余地を残すため -m や --last は畳み込んでいない
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

      services.magical-merchant = {
        enable = true;
        cli.enable = true;
        workersUrl = "https://magical-merchant.sync.r-aizawa.com";
      };

      # CI が main ごとに置く aarch64-darwin の .app と cli。flake.nix 側で nixpkgs を
      # follows させていないのは、この cache に当てるため
      nix.settings = {
        extra-substituters = [ "https://magical-merchant.cachix.org" ];
        extra-trusted-public-keys = [
          "magical-merchant.cachix.org-1:r8cvPKg3xGAINHclAor7fWiS7YK5pZ1Bxs4XjGnyvp0="
        ];
      };

      my.dock.apps = lib.mkOrder 300 [ "${pkgs.magical-merchant}/Applications/Magical Merchant.app" ];

      home-manager.sharedModules = [ hm.magical-merchant ];
    };
}
