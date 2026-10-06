# キーリピートと CapsLock。macOS 側の入力まわりの既定値。
{
  flake.modules.darwin.keyboard = {
    system.keyboard = {
      enableKeyMapping = true;
      # CapsLock は右 Control に送る。remapCapsLockToControl は左 Control に送るので、
      # 物理の左 Control と OS 上で区別がつかず、左 Control だけを OmniWM の Hyper
      # トリガーに使えない。MacBook に右 Control は無いのでぶつかるキーもない
      userKeyMapping = [
        {
          HIDKeyboardModifierMappingSrc = 30064771129; # 0x700000039 CapsLock
          HIDKeyboardModifierMappingDst = 30064771300; # 0x7000000E4 右 Control
        }
      ];
    };
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSWindowShouldDragOnGesture = true;
    };
  };
}
