# Barbar タブライン・バッファ管理
{ pkgs, ... }:
{
  plugins.barbar.enable = true;

  # Barbar keymaps
  keymaps = [
    {
      key = "<A-,>";
      action = "<Cmd>BufferPrevious<CR>";
      mode = "n";
      options.desc = "Previous buffer";
    }
    {
      key = "<A-.>";
      action = "<Cmd>BufferNext<CR>";
      mode = "n";
      options.desc = "Next buffer";
    }
    {
      key = "<A-<>";
      action = "<Cmd>BufferMovePrevious<CR>";
      mode = "n";
      options.desc = "Move buffer previous";
    }
    {
      key = "<A->>";
      action = "<Cmd>BufferMoveNext<CR>";
      mode = "n";
      options.desc = "Move buffer next";
    }
    {
      key = "<A-1>";
      action = "<Cmd>BufferGoto 1<CR>";
      mode = "n";
      options.desc = "Go to buffer 1";
    }
    {
      key = "<A-2>";
      action = "<Cmd>BufferGoto 2<CR>";
      mode = "n";
      options.desc = "Go to buffer 2";
    }
    {
      key = "<A-3>";
      action = "<Cmd>BufferGoto 3<CR>";
      mode = "n";
      options.desc = "Go to buffer 3";
    }
    {
      key = "<A-4>";
      action = "<Cmd>BufferGoto 4<CR>";
      mode = "n";
      options.desc = "Go to buffer 4";
    }
    {
      key = "<A-5>";
      action = "<Cmd>BufferGoto 5<CR>";
      mode = "n";
      options.desc = "Go to buffer 5";
    }
    {
      key = "<A-6>";
      action = "<Cmd>BufferGoto 6<CR>";
      mode = "n";
      options.desc = "Go to buffer 6";
    }
    {
      key = "<A-7>";
      action = "<Cmd>BufferGoto 7<CR>";
      mode = "n";
      options.desc = "Go to buffer 7";
    }
    {
      key = "<A-8>";
      action = "<Cmd>BufferGoto 8<CR>";
      mode = "n";
      options.desc = "Go to buffer 8";
    }
    {
      key = "<A-9>";
      action = "<Cmd>BufferGoto 9<CR>";
      mode = "n";
      options.desc = "Go to buffer 9";
    }
    {
      key = "<A-0>";
      action = "<Cmd>BufferLast<CR>";
      mode = "n";
      options.desc = "Go to last buffer";
    }
    {
      key = "<A-p>";
      action = "<Cmd>BufferPin<CR>";
      mode = "n";
      options.desc = "Pin/unpin buffer";
    }
    {
      key = "<A-c>";
      action = "<Cmd>BufferClose<CR>";
      mode = "n";
      options.desc = "Close buffer";
    }
    {
      key = "<C-p>";
      action = "<Cmd>BufferPick<CR>";
      mode = "n";
      options.desc = "Pick buffer";
    }
    {
      key = "<Space>bb";
      action = "<Cmd>BufferOrderByBufferNumber<CR>";
      mode = "n";
      options.desc = "Order by buffer number";
    }
    {
      key = "<Space>bn";
      action = "<Cmd>BufferOrderByName<CR>";
      mode = "n";
      options.desc = "Order by name";
    }
    {
      key = "<Space>bd";
      action = "<Cmd>BufferOrderByDirectory<CR>";
      mode = "n";
      options.desc = "Order by directory";
    }
    {
      key = "<Space>bl";
      action = "<Cmd>BufferOrderByLanguage<CR>";
      mode = "n";
      options.desc = "Order by language";
    }
    {
      key = "<Space>bw";
      action = "<Cmd>BufferOrderByWindowNumber<CR>";
      mode = "n";
      options.desc = "Order by window number";
    }
  ];
}
