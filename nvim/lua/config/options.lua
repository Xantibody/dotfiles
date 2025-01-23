local options = {
  modifiable = true,
  encoding = "utf-8",
  fileencoding = "utf-8",
  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  relativenumber = true,
  number = true,
  clipboard = "unnamedplus",
  termguicolors = true,
  spell = true,
  spelllang = { "en_us" },
  foldtext = "v:lua.vim.treesitter.foldtext()",
  foldmethod = "expr",
  foldexpr = "v:lua.vim.treesitter.foldexpr()",
  foldlevel = 1
}

-- this loop config setting
for k, v in pairs(options) do
  vim.opt[k] = v
end
