-- nixCats main configuration
-- Migration from nixvim

-- Add config directory to Lua path
local script_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = script_path .. "?.lua;" .. script_path .. "?/init.lua;" .. package.path

-- Global settings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.barbar_auto_setup = false
vim.g.arto_path = nixCats.extra("arto_path")

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

-- Load modules (order matches nixvim)
require("config.utils")
require("config.ui")

-- Load Japanese input if enabled
if nixCats("japanese") then
	require("config.skkeleton")
end

-- Load display modules
if nixCats("display") then
	require("config.hlslens")
end

-- Load plugins (after skkeleton and hlslens)
require("config.plugins")

-- Load alpha
if nixCats("display") then
	require("config.alpha")
end

-- Load LSP if edit category is enabled
if nixCats("edit") then
	require("config.lsp")
end
