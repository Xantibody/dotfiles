# Markdown-preview マークダウンプレビュー
{
  plugins.markdown-preview = {
    enable = true;
    settings.filetypes = [ "markdown" ];
  };

  # Markdown-preview keymaps
  keymaps = [
    {
      key = "<leader>mp";
      action = "<cmd>MarkdownPreviewToggle<CR>";
      mode = "n";
      options.desc = "Toggle markdown preview";
    }
  ];
}
