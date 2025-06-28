.PHONY:  E14Gen6 

E14Gen6: ## home manager
	@echo "Start E14Gen6  build..."
	sudo nixos-rebuild switch --flake .#E14Gen6 --show-trace
	@echo "Done."
