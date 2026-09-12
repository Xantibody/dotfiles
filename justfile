# Display available recipes
default:
    @just --list

# Switch NixOS configuration for E14Gen6 (ThinkPad)
E14Gen6:
    @echo "Start E14Gen6 nixos-rebuild..."
    sudo nixos-rebuild switch --flake .#E14Gen6 --show-trace
    @echo "Done."

# Switch home-manager configuration for work MacBook Pro M4
work-macbook-pro-m4-attm:
    @echo "Start work-macbook-pro-m4-attm switch..."
    sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#work-macbook-pro-m4-attm --show-trace
    @echo "Done."

# Switch home-manager configuration for private MacBook Pro M3
private-macbook-pro-m3:
    @echo "Start private-macbook-pro-m3 switch..."
    sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#private-macbook-pro-m3 --show-trace
    @echo "Done."

# Create skkserv data
create-JISYO:
    mkdir -p $HOME/.skk/
    yaskkserv2_make_dictionary --dictionary-filename=$HOME/.skk/dictionary.yaskkserv2 ./configs/skk/SKK-JISYO.L
    @echo "Done."

# 構成の characterization test を .ai/profiles/snapshot-<host>.json に落とす
snapshot host:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p .ai/profiles
    # --apply の式は pure eval mode では repo のパスを import できないので、
    # ファイルの中身をそのまま渡す
    nix eval --json --apply "$(cat script/snapshot.nix)" \
        "$(just _config-attr {{ host }})" > .ai/profiles/snapshot-{{ host }}.json
    echo "wrote .ai/profiles/snapshot-{{ host }}.json"

# 評価コストを計測して .ai/profiles/eval-<host>-<label>.* に落とす
eval-profile host label="after":
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p .ai/profiles
    out=.ai/profiles/eval-{{ host }}-{{ label }}
    # eval-cache は同じ flake の 2 回目の評価を丸ごと省くので、計測では必ず切る
    NIX_SHOW_STATS=1 NIX_SHOW_STATS_PATH="$out.stats.json" \
        nix eval --no-eval-cache --eval-profiler flamegraph \
        --eval-profile-file "$out.folded" -vv \
        "$(just _config-attr {{ host }}).system.build.toplevel.drvPath" \
        > "$out.stdout" 2> "$out.log"
    flamegraph.pl "$out.folded" > "$out.svg"
    go run script/foldedshare/main.go "$out.folded" | tee "$out.share.txt"
    echo "evaluating file: $(grep -c 'evaluating file' "$out.log")"

# 同じ flake.lock に同名の input が何コピー入っているかを出す
lock-deps:
    @go run script/lockdeps/main.go

# host 名から評価対象の flake 属性を組み立てる (nixos か darwin かを吸収する)
_config-attr host:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ host }}" in
        E14Gen6) echo ".#nixosConfigurations.{{ host }}.config" ;;
        *) echo ".#darwinConfigurations.{{ host }}.config" ;;
    esac
