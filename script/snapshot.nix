# 構成の characterization test。
#
#   nix eval --json --apply 'import ./script/snapshot.nix' \
#     .#darwinConfigurations.<host>.config
#
# 構造変更のステップは、この JSON の diff が空であることを合格条件にする。
# lib を使わず builtins だけで書いてあるのは、darwin と nixos のどちらの config でも
# 同じ式を通すため (lib は config から安定して取れない)。
config:
let
  sortStr = builtins.sort (a: b: a < b);
  pkgNames = ps: sortStr (map (p: p.name) ps);
  has = name: builtins.hasAttr name config;

  # system.defaults には mkRemovedOptionModule で throw する枝が混ざっていて、
  # 素で読むと設定していない項目のせいで評価が止まる。読める枝だけを残す。
  readable =
    set:
    builtins.listToAttrs (
      builtins.concatMap (
        name:
        let
          value = set.${name};
        in
        if (builtins.tryEval (builtins.toJSON value)).success then [ { inherit name value; } ] else [ ]
      ) (builtins.attrNames set)
    );

  homeOf = user: {
    packages = pkgNames user.home.packages;
    files = builtins.mapAttrs (_: f: {
      inherit (f) target executable recursive;
      source = "${f.source}";
    }) user.home.file;
    inherit (user.home) sessionVariables sessionPath;
    activation = sortStr (builtins.attrNames user.home.activation);
  };

  darwin = {
    launchdAgents = builtins.mapAttrs (_: a: a.serviceConfig) config.launchd.user.agents;
    systemDefaults = readable config.system.defaults;
    primaryUser = config.system.primaryUser;
  };

  nixos = {
    systemdServices = sortStr (builtins.attrNames config.systemd.services);
    etc = sortStr (builtins.attrNames config.environment.etc);
  };
in
{
  # 構造変更なら drvPath まで完全一致するはずなので、これが本命の判定材料。
  # 残りの欄は一致しなかったときに場所を特定するためにある。
  drvPath = config.system.build.toplevel.drvPath;
  systemPackages = pkgNames config.environment.systemPackages;
  nixSettings = config.nix.settings;
  users = builtins.mapAttrs (_: u: {
    inherit (u) home;
    shell = if u.shell == null then null else "${u.shell}";
  }) config.users.users;
  home = builtins.mapAttrs (_: homeOf) config.home-manager.users;
}
// (if has "launchd" then darwin else nixos)
