# Display available recipes
default:
    @just --list

# Switch NixOS configuration for E14Gen6 (ThinkPad)
E14Gen6:
    @echo "Start E14Gen6 nixos-rebuild..."
    sudo nixos-rebuild switch --flake .#E14Gen6 --show-trace
    @echo "Done."

# Switch home-manager configuration for work MacBook Pro M4
work-macBook-m4:
    @echo "Start work-macBook-m4 switch..."
    sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#work-macBook-m4 --show-trace
    @echo "Done."

# Switch home-manager configuration for private MacBook Pro M3
private-macbook-pro-m3:
    @echo "Start private-macbook-pro-m3 switch..."
    sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#private-macbook-pro-m3 --show-trace
    @echo "Done."

# Create skkserv data
create-JISYO:
    mkdir -p $HOME/.skk/
    yaskkserv2_make_dictionary --dictionary-filename=$HOME/.skk/dictionary.yaskkserv2 ./configs/skk/SKK-JISYO.emoji.utf8 ./configs/skk/SKK-JISYO.L
    @echo "Done."
