# Comment コメントアウト
{ pkgs, ... }:
{
  plugins.comment.enable = true;

  # Comment keymap
  keymaps = [
    {
      key = "<C-/>";
      action = "<cmd>lua require('Comment.api').toggle.linewise.current()<CR><Esc>A";
      mode = [
        "n"
        "i"
      ];
      options.desc = "comment out line";
    }
  ];
}
