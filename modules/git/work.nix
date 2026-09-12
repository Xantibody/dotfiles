# ~/Repository/work 配下だけ git / gh を会社用の設定に切り替える。
# 会社用アカウントの識別子を public リポジトリに平文で置かないため、
# gitconfig の include 先は sops-nix が復号したファイルを指す。
# gh は 1 つの config ディレクトリに 1 アカウントしか保持できないため、
# direnv で GH_CONFIG_DIR を差し替える方式を取る。
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.darwin.work-git = {
    home-manager.sharedModules = [ hm.work-git ];
  };

  flake.modules.homeManager.work-git =
    { config, ... }:
    let
      workRoot = "${config.home.homeDirectory}/Repository/work";
    in
    {
    sops = {
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      secrets.work-gitconfig = {
        sopsFile = ../../secrets/work-git.yaml;
        key = "gitconfig";
      };
    };
  
    programs.git.includes = [
      {
        condition = "gitdir:${workRoot}/";
        path = config.sops.secrets.work-gitconfig.path;
      }
    ];
  
    # 会社 org は ghq get で自動的に workRoot 配下へ clone させる。
    # ghq は正規化後の URL 文字列で前方一致するため、https と ssh の両形式が要る
    # (`git@github.com:attmcojp/x.git` は `ssh://git@github.com/attmcojp/x.git` になる)。
    # 外れると private 側へ落ち、上の includeIf が効かず個人鍵で 404 になる。
    programs.git.settings.ghq = {
      "https://github.com/attmcojp".root = workRoot;
      "https://github.com/attmcojp-docs".root = workRoot;
      "ssh://git@github.com/attmcojp".root = workRoot;
      "ssh://git@github.com/attmcojp-docs".root = workRoot;
    };
  
    home.file."Repository/work/.envrc".text = ''
      export GH_CONFIG_DIR=${config.xdg.configHome}/gh-work
    '';
  
    # rebuild のたびに .envrc が再生成されても direnv allow を要求されないようにする。
    programs.direnv.config.whitelist.prefix = [ workRoot ];
    };
}
