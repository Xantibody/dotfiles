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

      nixpkgs.overlays = [
        (final: _prev: {
          magical-merchant = inputs.magical-merchant.packages.${final.stdenv.hostPlatform.system}.default;
        })
      ];

      services.magical-merchant = {
        enable = true;
        cli.enable = true;
        workersUrl = "https://magical-merchant.sync.r-aizawa.com";
      };

      my.dock.apps = lib.mkOrder 300 [ "${pkgs.magical-merchant}/Applications/Magical Merchant.app" ];

      home-manager.sharedModules = [ hm.magical-merchant ];
    };
}
