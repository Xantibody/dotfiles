# Telescope ファジーファインダー
{ pkgs, ... }:
{
  plugins.telescope.enable = true;

  # Telescope keymaps
  keymaps = [
    {
      key = "<leader>ff";
      action = "<cmd>lua require('telescope.builtin').find_files()<CR>";
      mode = "n";
      options.desc = "Telescope find files";
    }
    {
      key = "<leader>fg";
      action = "<cmd>lua require('telescope.builtin').live_grep()<CR>";
      mode = "n";
      options.desc = "Telescope live grep";
    }
    {
      key = "<leader>fb";
      action = "<cmd>lua require('telescope.builtin').buffers()<CR>";
      mode = "n";
      options.desc = "Telescope buffers";
    }
    {
      key = "<leader>fh";
      action = "<cmd>lua require('telescope.builtin').help_tags()<CR>";
      mode = "n";
      options.desc = "Telescope help tags";
    }
  ];
}
