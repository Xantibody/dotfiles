#!/usr/bin/zsh

vim-startuptime -vimpath nvim >"./startuptime/$(date +"%FT%H%M").log"
