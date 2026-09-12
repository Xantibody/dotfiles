# Dock。常駐 pin するアプリは機能側のファイルが my.dock.apps に足す。
# 並び順は見た目そのものなので、寄せる側が lib.mkOrder で位置を明示する。
# この option を宣言しているのはこのファイルなので、pin を足す機能を載せる host は
# dock も載せる必要がある (外すと option が無いというエラーで気づける)。
{
  flake.modules.darwin.dock =
    { config, lib, ... }:
    {
      options.my.dock.apps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Dock に常駐 pin するアプリのパス";
      };

      config.system.defaults.dock = {
        show-recents = false;
        autohide = true;
        persistent-apps = map (app: { inherit app; }) config.my.dock.apps ++ [
          # 常駐 pin と「起動中なだけの app」の境目。show-recents = false だと
          # macOS は両者の間に区切り線を描かないので、spacer tile を末尾に
          # 置いて自前で区切る。
          {
            spacer = {
              small = true;
            };
          }
        ];
      };
    };
}
