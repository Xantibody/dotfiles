let
  # fd は TTY に直接吐くときしか着色しないので、パイプで受ける fzf 向けには
  # --color=always が要る。受け手の --ansi は defaultOptions 側に置いてある
  fd = "fd --hidden --exclude .git --color=always";
in
{
  enable = true;
  defaultCommand = "${fd} --type f";
  defaultOptions = [
    "--ansi"
    "--height 40%"
    "--reverse"
    "--border"
  ];

  # dayfox。fish.nix が同じパレットを持つが、あちらは fish のローカル変数で
  # Nix からは参照できない。共有ファイルへの抽出は色を変える時が来てからでよい。
  # bg を省くと端末の背景をそのまま透かす
  colors = {
    fg = "#3d2b5a";
    hl = "#a440b5";
    "fg+" = "#3d2b5a";
    "bg+" = "#e7d2be";
    "hl+" = "#a440b5";
    info = "#837a72";
    prompt = "#287980";
    pointer = "#a5222f";
    marker = "#396847";
    spinner = "#6e33ce";
    header = "#6e33ce";
    border = "#837a72";
  };

  # プレビューも TTY ではないサブシェルで走るため、同じく色を明示する
  fileWidget = {
    command = "${fd} --type f";
    options = [ "--preview 'bat --color=always --style=numbers {}'" ];
  };
  changeDirWidget = {
    command = "${fd} --type d";
    options = [ "--preview 'eza --icons -1 --color=always {}'" ];
  };
}
