-- Render markdown (display) configuration
--
-- Read by the plugin/ script on packadd, which attaches to the buffer that
-- triggered the load right away; a setup() call afterwards would come too late
-- for that buffer.
vim.g.render_markdown_config = {
	-- Checkbox and callout completions through an in-process LSP, which
	-- blink.cmp's lsp source picks up without a provider of its own.
	completions = { lsp = { enabled = true } },
}
