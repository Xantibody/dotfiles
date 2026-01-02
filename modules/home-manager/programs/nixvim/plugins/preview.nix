# プレビュー系プラグイン: markdown-preview, render-markdown
{ pkgs, ... }:
{
  # Markdown-preview
  plugins.markdown-preview = {
    enable = true;
    settings.filetypes = [ "markdown" ];
  };

  # Render-markdown
  plugins.render-markdown = {
    enable = true;
    settings = {
      completions = {
        blink.enabled = true;
        lsp.enabled = true;
      };
    };
  };
}
