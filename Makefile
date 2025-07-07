.DEFAULT_GOAL := help

.PHONY: E14Gen6
E14Gen6: ## Switch NixOS configuration for E14Gen6(ThinkPad)
	@echo "Start E14Gen6 nixos-rebuild..."
	sudo nixos-rebuild switch --flake .#E14Gen6 --show-trace
	@echo "Done."

.PHONY: work-macBook-m2
work-macBook-m2: ## Switch home-manager configuration for work MacBook Pro M2
	@echo "Start work-macBook-m2  switch..."
	nix run nixpkgs#home-manager -- switch --flake .#work-macBook-m2 --show-trace
	@echo "Done."

.PHONY: fmt
fmt: ## Apply nix fmt
	nix fmt

.PHONY: help
help: ## Display Help
	@grep -E '^[[:alnum:]_-]+:[[:space:]]*## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
