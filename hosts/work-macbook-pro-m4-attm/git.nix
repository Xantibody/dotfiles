# ~/src/work 配下だけ git / gh を会社用の設定に切り替える。
# 会社用アカウントの識別子を public リポジトリに平文で置かないため、
# gitconfig の include 先は sops-nix が復号したファイルを指す。
# gh は 1 つの config ディレクトリに 1 アカウントしか保持できないため、
# direnv で GH_CONFIG_DIR を差し替える方式を取る。
{ config, ... }:
let
  workRoot = "${config.home.homeDirectory}/src/work";
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

  # 会社 org は ghq get で自動的に workRoot 配下へ clone させる
  programs.git.settings.ghq = {
    "https://github.com/attmcojp".root = workRoot;
    "https://github.com/attmcojp-docs".root = workRoot;
  };

  home.file."src/work/.envrc".text = ''
    export GH_CONFIG_DIR=${config.xdg.configHome}/gh-work
  '';

  # direnv は最も近い .envrc を 1 つだけ読むため、workRoot 配下のリポジトリが
  # 自前の .envrc（use flake など）を持つと上の .envrc は読まれず GH_CONFIG_DIR が失われる。
  # direnvrc はどの .envrc よりも先に必ず source されるので、ここで親を辿らせる。
  # 各リポジトリの .envrc に source_up_if_exists を書く方式は書き忘れで破綻するため取らない。
  programs.direnv.stdlib = ''
    source_up_if_exists
  '';

  # rebuild のたびに .envrc が再生成されても direnv allow を要求されないようにする。
  programs.direnv.config.whitelist.prefix = [ workRoot ];
}
