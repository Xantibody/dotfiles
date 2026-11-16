# aarch64-linux の derivation を mac から組むための NixOS VM。
# nix-darwin が launchd で常駐させ、nix.buildMachines に自分を足すので、
# --system aarch64-linux や linux 向けの flake 出力をそのまま build できる。
{
  flake.modules.darwin.linux-builder = {
    nix.linux-builder.enable = true;
    # 起動のたびに builder のディスクを作り直す。ストアの登録だけ残って実体が消えると、
    # Nix はそのパスを送り直さず、同じ derivation が毎回失敗する。builder には root の ssh
    # でしか入れず手で直しにくいので、再起動で消えるようにする。失うのは builder の
    # キャッシュだけで、ほとんどは binary cache から取り直せる。
    nix.linux-builder.ephemeral = true;
  };
}
