-- nixCats main configuration
-- Migration from nixvim

-- Global settings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.barbar_auto_setup = false

-- Editor options
local opt = vim.opt
opt.clipboard = "unnamedplus"
opt.colorcolumn = "80,100,120"
opt.encoding = "utf-8"
opt.expandtab = true
opt.fileencoding = "utf-8"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldmethod = "expr"
opt.foldtext = "v:lua.vim.treesitter.foldtext()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.guifont = "Explex Console NF"
opt.list = true
opt.modifiable = true
opt.number = true
opt.relativenumber = true
opt.scrolloff = 5
opt.shiftwidth = 2
opt.sidescrolloff = 8
opt.spell = true
opt.spelllang = { "en_us" }
opt.tabstop = 2
opt.termguicolors = true
opt.timeout = true
opt.timeoutlen = 300
opt.wrap = false

-- Listchars
opt.listchars:append({ space = "･", eol = "↵" })

-- Load colorscheme
if nixCats("colorscheme") then
  vim.cmd.colorscheme("dayfox")
end

-- Load modules
require("config.utils")
require("config.ui")
require("config.plugins")
require("config.keymaps")

-- Load Japanese input if enabled
if nixCats("japanese") then
  require("config.skkeleton")
end

-- Load display modules
if nixCats("display") then
  require("config.hlslens")
  require("config.alpha")
end
