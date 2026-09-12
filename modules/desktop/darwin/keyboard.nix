# キーリピートと CapsLock。macOS 側の入力まわりの既定値。
{
  flake.modules.darwin.keyboard = {
    system.keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSWindowShouldDragOnGesture = true;
    };
  };
}
