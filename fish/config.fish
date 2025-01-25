fish_vi_key_bindings

function dpnvim
    set -gx NVIM_APPNAME "darkpawered"
    nvim
    set -e NVIM_APPNAME  # 終了後に環境変数を削除
end

