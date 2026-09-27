# 1Password のデスクトップアプリ。ブラウザ拡張はこれと native messaging で繋がって初めて
# 解錠でき、指紋や OS のパスワードでの解錠も polkit 経由でこのアプリが受ける。
# macOS は Homebrew cask を手で入れているので nixos だけ持つ。
{
  flake.modules.nixos."1password" =
    { config, ... }:
    {
      programs._1password-gui = {
        enable = true;
        # システム認証 (指紋など) での解錠を許すユーザ
        polkitPolicyOwners = [ config.my.user.name ];
      };
    };
}
