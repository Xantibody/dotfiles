# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ 
  inputs,
  config, 
  pkgs, 
  ... 
}:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # <home-manager/nixos>
    ]

   # 環境に応じてインポートするモジュールを変更してください
  ++ (with inputs.nixos-hardware.nixosModules; [
     common-cpu-amd
     common-gpu-amd
     common-pc-ssd
     # <nixos-hardware/lenovo/thinkpad/e14/amd> 多分これ
   ])
   # xremapのNixOS modulesを使えるようにする
   ++ [
     inputs.xremap.nixosModules.default
   ];

  programs = {
    git = {
      enable = true;
    };
    neovim = {
      enable = true;
      defaultEditor = true; # $EDITOR=nvimに設定
      viAlias = true;
      vimAlias = true;
    };
    starship = {
      enable = true;
    };
    fish = {
      enable = true;
     };
  }; 


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-skk
      fcitx5-gtk
      libsForQt5.fcitx5-qt
      ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.raizawa = {
    isNormalUser = true;
    description = "r-aizawa";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
    shell = pkgs.fish;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty

    neovim
    unzip

    git
    tmux
    tmuxPlugins.sensible

    fish
    fishPlugins.z

    slack
    docker
    mise
    deno
    xsel
    fzf
    tree-sitter
    gcc
    clang
    zig
    starship

  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?


  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix-550a;
  # security.pam.services.login.fprintAuth = true;

fonts.packages = with pkgs; [
  hackgen-nf-font
];


  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true; # Nix store optimise
    };
   # garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # xremapでキー設定をいい感じに変更
 services.xremap = {
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

}
