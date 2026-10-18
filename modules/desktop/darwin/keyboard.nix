# キーリピート。macOS 側の入力まわりの既定値。
# キーの読み替え (CapsLock, Hyper) は karabiner.nix にまとめている。
{
  flake.modules.darwin.keyboard = {
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSWindowShouldDragOnGesture = true;
    };
  };
}
