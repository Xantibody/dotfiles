# プレビュー系プラグイン: markdown-preview, render-markdown
{ pkgs, ... }:
{
  # Markdown-preview
  markdown-preview = {
    enable = true;
    settings.filetypes = [ "markdown" ];
  };

  # Render-markdown
  render-markdown = {
    enable = true;
    settings = {
      completions = {
        blink.enabled = true;
        lsp.enabled = true;
      };
    };
  };
}
