-- nixCats main configuration
-- Migration from nixvim

-- Cache compiled Lua modules under stdpath('cache'); the config lives in
-- the Nix store so the cache is invalidated whenever the path changes.
vim.loader.enable()

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
opt.foldexpr = "v:lua.require'config.fold'.expr()"
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

-- oil replaces netrw; it used to set these itself, but it is now loaded on
-- demand, after the point where netrw would already have been sourced.
if nixCats("core") then
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1
end

-- lualine is loaded after the first frame; hide the stock statusline until
-- then so the screen does not flip from one to the other. lualine sets 2.
if nixCats("display") then
	opt.laststatus = 0
end

require("config.utils")
require("config.ui")
require("config.plugins")
