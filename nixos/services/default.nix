{
  xserver = {
    enable = true; 
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  printing.enable = true;

  pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

  auto-cpufreq = {
    enable = true;
  };
   xremap = {
     userName = "raizawa";
     serviceMode = "system";
     config = {
       modmap = [
         {
           name = "change CapsLock key to ctl";
           remap = {
             CapsLock = "Ctrl_L";
           };
         }
       ];
       keymap = [
         {
           # Ctrl + HがどのアプリケーションでもBackspaceになるように変更
           name = "Ctrl+H should be enabled on all apps as BackSpace";
           remap = {
             C-h = "Backspace";
           };
           # 一部アプリケーション（ターミナルエミュレータ）を対象から除外
           application = {
             not = ["Alacritty" "Kitty" "Wezterm"];
           };
         }
       ];
      };
    };
  # xremapでキー設定をいい感じに変更
    # fprintd = {
    #   enable = true;
    #   tod = {
    #     enable = true;
    #     # https://ryantm.github.io/nixpkgs/using/overrides/
    #     # passthru.driverPath = "/lib/libfprint-2/tod-1"; をoverriding
    #     # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/li/libfprint-2-tod1-goodix-550a/package.nix#L44
    #     driver = pkgs.libfprint-tod;
    #   };
    # };
    upower = {
      enable = true;
    };
  };
  # power management
}
