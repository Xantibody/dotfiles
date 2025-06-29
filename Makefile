.PHONY:  E14Gen6 
E14Gen6: ## NixOS
	@echo "Start E14Gen6  build..."
	sudo nixos-rebuild switch --flake .#E14Gen6 --show-trace
	@echo "Done."


.PHONY: work-macBook-m2 
work-macBook-m2 : ## home-manager
	@echo "Start work-macBook-m2  build..."
	nix run nixpkgs#home-manager -- switch --flake .#work-macBook-m2 --show-trace
	@echo "Done."
