# 自作のジャーナル (github:Xantibody/magical-merchant)。
# CLI とノートを同期する常駐サービスを darwin module 側が持っている。
{ inputs, ... }:
{
  flake.modules.darwin.magical-merchant = {
    imports = [ inputs.magical-merchant.darwinModules.default ];
    services.magical-merchant = {
      enable = true;
      cli.enable = true;
      workersUrl = "https://magical-merchant.sync.r-aizawa.com";
    };
  };
}
