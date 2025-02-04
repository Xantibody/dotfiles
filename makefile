.PHONY: neovim alacritty tmux fish

neovim: ## Init neovim
	@echo "Setting neovim..."
	ln -vsf $(CURDIR)/nvim/ ${HOME}/.config/
	@echo "Done."

tmux: ## Init tmux
	@echo "Setting tmux..."
	test -L ${HOME}/.config/$@/tmux.conf || rm -rf ${HOME}/.config/$@/tmux.conf
	ln -vsf $(CURDIR)/tmux/tmux.conf ${HOME}/.config/tmux/tmux.conf
	@echo "Done."

alacritty: ## Init alacritty
	@echo "Setting alacritty..."
	test -L ${HOME}/.config/$@/alacritty.toml || rm -rf ${HOME}/.config/$@/$@.toml
	ln -vsf $(CURDIR)/$@/alacritty.toml ${HOME}/.config/$@/alacritty.toml
	@echo "Done."

fish: ## Init fish
	@echo "Setting fish..."
	test -L ${HOME}/.config/$@/config.fish || rm -rf ${HOME}/.config/$@/config.fish
	ln -vsf $(CURDIR)/$@/config.fish ${HOME}/.config/$@/config.fish
	@echo "Done."

