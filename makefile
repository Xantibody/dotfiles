.PHONY:  home-manager nix-os

home-manager: ## home manager
	@echo "Start home-manager..."
	nix run nixpkgs#home-manager -- switch --flake .#raizawa
	@echo "Done."


nix-os: ## home manager
	@echo "Start Nix OS build..."
	sudo nixos-rebuild switch --flake .
	@echo "Done."

