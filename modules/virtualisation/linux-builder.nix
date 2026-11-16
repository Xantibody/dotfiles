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
    # builder の名前解決は QEMU の DNS (10.0.2.3) が mac の DNS へ転送する。家のルーターの DNS は
    # EDNS 付きの問い合わせに FORMERR を返し、Go はそれを "server misbehaving" として止まるので、
    # go-modules のようにネットワークを使う derivation が builder で組めない。
    # resolved は FORMERR を受けると EDNS なしで問い合わせ直すので、どのネットワークでも引ける。
    nix.linux-builder.config.services.resolved.enable = true;
  };
}
