# プレビュー系プラグイン: markdown-preview, render-markdown
{ pkgs, ... }:
{
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
