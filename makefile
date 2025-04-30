.PHONY:  home-manager nix-os E14Gen6 

home-manager: ## home manager
	@echo "Start home-manager..."
	nix run nixpkgs#home-manager -- switch --flake .#raizawa
	@echo "Done."


nix-os: ## home manager
	@echo "Start Nix OS build..."
	sudo nixos-rebuild switch --flake .
	@echo "Done."

E14Gen6: ## home manager
	@echo "Start E14Gen6  build..."
	sudo nixos-rebuild switch --flake .#E14Gen6 --show-trace
	@echo "Done."
