neovim:
	@echo "Setting neovim..."
	ln -vsf $(CURDIR)/nvim/ ${HOME}/.config/
	@echo "Done."
