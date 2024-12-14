local util = require(lspconfig.util)

return {
  default_config = {
    cmd = { '/Users/usr0200777/.config/test/iccheck', 'lsp' },
    filetypes = { 'yaml' },
    root_dir = util.find_git_ancestor,
    settings = {},
  },
}
