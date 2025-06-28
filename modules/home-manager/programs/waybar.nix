{ isLinux }:
{
  enable = isLinux;
  settings = {
    # theme https://github.com/sejjy/mechabar
    #  ─────────────────────────────────────────────────────────────┤ header ├───
    mainBar = {
      "layer" = "top";
      "position" = "top";
      "mode" = "dock";
      "reload_style_on_change" = true;
      "gtk-layer-shell" = true;

      #  ──────────────────────────────────────────────────────────┤ positions ├───

      "modules-left" = [
        "custom/theme" # theme switcher
        "custom/left1"

        "hyprland/workspaces" # workspaces
        "custom/right1"

        "custom/paddw"
        "hyprland/window" # window title
      ];

      "modules-center" = [
        "custom/paddc"
        "custom/left2"
        "custom/temperature" # temperature

        "custom/left3"
        "memory" # memory

        "custom/left4"
        "cpu" # cpu
        "custom/leftin1"

        "custom/left5"
        "custom/distro" # distro icon
        "custom/right2"

        "custom/rightin1"
        "idle_inhibitor" # idle inhibitor
        "clock#time" # time
        "custom/right3"

        "clock#date" # date
        "custom/right4"

        "custom/wifi" # wi-fi
        "bluetooth" # bluetooth
        "custom/update" # system update
        "custom/right5"
      ];

      "modules-right" = [
        "mpris" # media info

        "custom/left6"
        "pulseaudio" # output device

        "custom/left7"
        "backlight" # brightness

        "custom/left8"
        "battery" # battery

        "custom/leftin2"
        "custom/power" # power button
      ];

      #  ─────────────────────────────────────────────────────┤ theme switcher ├───

      "custom/theme" = {
        "exec" = "~/.config/waybar/scripts/current-theme.sh";
        "return-type" = "json";
        "format" = "󰤕 ";
        "on-click" = "~/.config/waybar/scripts/theme-switcher.sh";
        "min-length" = 3;
        "max-length" = 3;
      };

      #  ─────────────────────────────────────────────────────────┤ workspaces ├───

      "hyprland/workspaces" = {
        "on-scroll-up" = "hyprctl dispatch workspace -1";
        "on-scroll-down" = "hyprctl dispatch workspace +1";
        "persistent-workspaces" = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
        };
      };

      #  ─────────────────────────────────────────────────────────────┤ window ├───

      "hyprland/window" = {
        "format" = "{}";
        "tooltip" = false;
        "min-length" = 5;

        "rewrite" = {
          #  ────────────────────────────────────────────────────────── desktop ───
          "" = "<span foreground='#458588'> </span> Hyprland";

          #  ───────────────────────────────────────────────────────── terminal ───

          "~" = "  Terminal";
          "zsh" = "  Terminal";
          "kitty" = "  Terminal";

          "tmux(.*)" = "<span foreground='#98971a'> </span> Tmux";

          #  ────────────────────────────────────────────────────────── browser ───

          "(.*)Mozilla Firefox" = "<span foreground='#cc241d'>󰈹 </span> Firefox";
          "(.*) — Mozilla Firefox" = "<span foreground='#cc241d'>󰈹 </span> $1";

          "(.*)Zen Browser" = "<span foreground='#d65d0e'>󰺕 </span> Zen Browser";
          "(.*) — Zen Browser" = "<span foreground='#d65d0e'>󰺕 </span> $1";

          #  ────────────────────────────────────────────────────── development ───

          "(.*) - Visual Studio Code" = "<span foreground='#458588'>󰨞 </span> $1";
          "(.*)Visual Studio Code" = "<span foreground='#458588'>󰨞 </span> Visual Studio Code";

          "nvim" = "<span foreground='#98971a'> </span> Neovim";
          "nvim (.*)" = "<span foreground='#98971a'> </span> $1";

          "vim" = "<span foreground='#98971a'> </span> Vim";
          "vim (.*)" = "<span foreground='#98971a'> </span> $1";

          #  ──────────────────────────────────────────────────────────── media ───

          "(.*)Spotify" = "<span foreground='#98971a'> </span> Spotify";
          "(.*)Spotify Premium" = "<span foreground='#98971a'> </span> Spotify Premium";

          "OBS(.*)" = "<span foreground='#d5c4a1'>󰻃 </span> OBS Studio";

          "VLC media player" = "<span foreground='#d65d0e'>󰕼 </span> VLC Media Player";
          "(.*) - VLC media player" = "<span foreground='#d65d0e'>󰕼 </span> $1";

          "(.*) - mpv" = "<span foreground='#b16286'> </span> $1";

          "qView" = "󰋩  qView";

          "(.*).jpg" = "󰋩  $1.jpg";
          "(.*).png" = "󰋩  $1.png";
          "(.*).svg" = "󰋩  $1.svg";

          #  ─────────────────────────────────────────────────────────── social ───

          "• Discord(.*)" = "Discord$1";
          "(.*)Discord(.*)" = "<span foreground='#458588'> </span> $1Discord$2";

          "vesktop" = "<span foreground='#458588'> </span> Discord";

          #  ──────────────────────────────────────────────────────── documents ───

          "ONLYOFFICE Desktop Editors" = "<span foreground='#cc241d'> </span> OnlyOffice Desktop";

          "(.*).docx" = "<span foreground='#458588'>󰈭 </span> $1.docx";
          "(.*).xlsx" = "<span foreground='#98971a'>󰈜 </span> $1.xlsx";
          "(.*).pptx" = "<span foreground='#d65d0e'>󰈨 </span> $1.pptx";
          "(.*).pdf" = "<span foreground='#cc241d'> </span> $1.pdf";

          #  ─────────────────────────────────────────────────────────── system ───
          "Authenticate" = "  Authenticate";
        };
      };

      #  ────────────────────────────────────────────────────────┤ temperature ├───

      "custom/temperature" = {
        "exec" = "~/.config/waybar/scripts/cpu-temp.sh";
        "return-type" = "json";
        "format" = "{}";
        "interval" = 5;
        "min-length" = 8;
        "max-length" = 8;
      };

      #  ─────────────────────────────────────────────────────────────┤ memory ├───

      "memory" = {
        "states" = {
          "warning" = 75;
          "critical" = 90;
        };

        "format" = "󰘚 {percentage}%";
        "format-critical" = "󰀦 {percentage}%";
        "tooltip" = false;
        #  "tooltip-format"= "Memory Used= {used:0.1f} GB / {total:0.1f} GB";
        "interval" = 5;
        "min-length" = 7;
        "max-length" = 7;
      };

      #  ────────────────────────────────────────────────────────────────┤ cpu ├───

      "cpu" = {
        "format" = "󰍛 {usage}%";
        "tooltip" = false;
        "interval" = 5;
        "min-length" = 6;
        "max-length" = 6;
      };

      #  ─────────────────────────────────────────────────────────────┤ distro ├───

      "custom/distro" = {
        "format" = " ";
        "tooltip" = false;
      };

      #  ─────────────────────────────────────────────────────┤ idle inhibitor ├───

      "idle_inhibitor" = {
        "format" = "{icon}";

        "format-icons" = {
          "activated" = "󰈈 ";
          "deactivated" = "󰈉 ";
        };

        "tooltip-format-activated" = "Presentation Mode";
        "tooltip-format-deactivated" = "Idle Mode";
        "start-activated" = false;
      };

      #  ───────────────────────────────────────────────────────────────┤ time ├───

      "clock#time" = {
        "format" = "{:%H:%M}";
        "tooltip" = false;
        #  "tooltip-format"= "Standard Time= {:%I:%M %p}";
        "min-length" = 6;
        "max-length" = 6;
      };

      #  ───────────────────────────────────────────────────────────────┤ date ├───

      "clock#date" = {
        "format" = "󰸗 {:%m-%d}";
        "tooltip-format" = "<tt>{calendar}</tt>";

        "calendar" = {
          "mode" = "month";
          "mode-mon-col" = 6;
          "on-click-right" = "mode";

          "format" = {
            "months" = "<span color='#928374'><b>{}</b></span>";
            "weekdays" = "<span color='#d5c4a1' font='7'>{}</span>";
            "today" = "<span color='#cc241d'><b>{}</b></span>";
          };
        };

        "actions" = {
          "on-click" = "mode";
          "on-click-right" = "mode";
        };

        "min-length" = 8;
        "max-length" = 8;
      };

      #  ──────────────────────────────────────────────────────────────┤ wi-fi ├───

      "custom/wifi" = {
        "exec" = "~/.config/waybar/scripts/wifi-status.sh";
        "return-type" = "json";
        "format" = "{}";
        "on-click" = "~/.config/waybar/scripts/wifi-menu.sh";
        "on-click-right" = "kitty --title '󰤨  Network Manager TUI' bash -c nmtui";
        "interval" = 1;
        "min-length" = 1;
        "max-length" = 1;
      };

      #  ──────────────────────────────────────────────────────────┤ bluetooth ├───

      "bluetooth" = {
        "format" = "󰂰";
        "format-disabled" = "󰂲";
        "format-connected" = "󰂱";
        "format-connected-battery" = "󰂱";

        "tooltip-format" = "{num_connections} connected";
        "tooltip-format-disabled" = "Bluetooth Disabled";
        "tooltip-format-connected" = "{device_enumerate}";
        "tooltip-format-enumerate-connected" = "{device_alias}";
        "tooltip-format-enumerate-connected-battery" = ":= {device_alias}= 󱊣 {device_battery_percentage}%";

        "on-click" = "~/.config/waybar/scripts/bluetooth-menu.sh";
        "on-click-right" = "kitty --title '󰂯  Bluetooth TUI' bash -c bluetui";
        "interval" = 1;
        "min-length" = 1;
        "max-length" = 1;
      };

      #  ──────────────────────────────────────────────────────┤ system update ├───

      "custom/update" = {
        "exec" = "~/.config/waybar/scripts/system-update.sh";
        "return-type" = "json";
        "format" = "{}";
        "on-click" = "~/.config/waybar/scripts/system-update.sh up";
        "interval" = 30;
        "min-length" = 1;
        "max-length" = 1;
      };

      #  ─────────────────────────────────────────────────────────┤ media info ├───

      "mpris" = {
        "format" = "{player_icon} {title} - {artist}";
        "format-paused" = "{status_icon} {title} - {artist}";

        "player-icons" = {
          "default" = "󰝚 ";
          "spotify" = "<span foreground='#98971a'>󰓇 </span>";
          "firefox" = "<span foreground='#cc241d'>󰗃 </span>";
        };
        "status-icons" = {
          "paused" = "<span color='#928374'>u200Au200A󰏤u2009u2009</span>";
        };

        "tooltip-format" = "Playing= {title} - {artist}";
        "tooltip-format-paused" = "Paused= {title} - {artist}";
        "min-length" = 5;
        "max-length" = 35;
      };

      #  ──────────────────────────────────────────────────────┤ output device ├───

      "pulseaudio" = {
        "format" = "{icon} {volume}%";
        "format-muted" = "󰝟 {volume}%";

        "format-icons" = {
          "default" = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          "headphone" = "󰋋";
          "headset" = "󰋋";
        };

        "tooltip-format" = "Device= {desc}";
        "on-click" = "~/.config/waybar/scripts/volume-control.sh -o m";
        "on-scroll-up" = "~/.config/waybar/scripts/volume-control.sh -o i";
        "on-scroll-down" = "~/.config/waybar/scripts/volume-control.sh -o d";
        "min-length" = 6;
        "max-length" = 6;
      };

      #  ─────────────────────────────────────────────────────────┤ brightness ├───

      "backlight" = {
        "format" = "{icon} {percent}%";
        "format-icons" = [
          ""
          ""
          ""
          ""
          ""
          ""
          ""
          ""
          ""
        ];
        "tooltip" = false;
        "on-scroll-up" = "~/.config/waybar/scripts/brightness-control.sh -o i";
        "on-scroll-down" = "~/.config/waybar/scripts/brightness-control.sh -o d";
        "min-length" = 6;
        "max-length" = 6;
      };

      #  ────────────────────────────────────────────────────────────┤ battery ├───

      "battery" = {
        "states" = {
          "warning" = 20;
          "critical" = 10;
        };

        "format" = "{icon} {capacity}%";
        "format-icons" = [
          "󰂎"
          "󰁻"
          "󰁼"
          "󰁽"
          "󰁾"
          "󰁿"
          "󰂀"
          "󰂁"
          "󰂂"
          "󰁹"
        ];
        "format-charging" = " {capacity}%";

        "tooltip-format" = "Discharging= {time}";
        "tooltip-format-charging" = "Charging= {time}";
        "interval" = 1;
        "min-length" = 6;
        "max-length" = 6;
      };

      #  ───────────────────────────────────────────────────────┤ power button ├───

      "custom/power" = {
        "format" = " ";
        "tooltip" = false;
        #  "tooltip-format"= "Power Menu";
        "on-click" = "~/.config/waybar/scripts/power-menu.sh";
      };

      #  ────────────────────────────────────────────────────────────┤ padding ├───

      "custom/paddw" = {
        "format" = " ";
        "tooltip" = false;
      };

      "custom/paddc" = {
        "format" = " ";
        "tooltip" = false;
      };

      #  ────────────────────────────────────────────────────────┤ left arrows ├───

      "custom/left1" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/left2" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/left3" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/left4" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/left5" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/left6" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/left7" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/left8" = {
        "format" = "";
        "tooltip" = false;
      };

      #  ───────────────────────────────────────────────────────┤ right arrows ├───

      "custom/right1" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/right2" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/right3" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/right4" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/right5" = {
        "format" = "";
        "tooltip" = false;
      };

      #  ───────────────────────────────────────────────────────┤ left inverse ├───

      "custom/leftin1" = {
        "format" = "";
        "tooltip" = false;
      };
      "custom/leftin2" = {
        "format" = "";
        "tooltip" = false;
      };

      #  ──────────────────────────────────────────────────────┤ right inverse ├───

      "custom/rightin1" = {
        "format" = "";
        "tooltip" = false;
      };
    };
  };
  style = ''
            /* theme */
            /* Gruvbox Dark */

            @define-color bg0_h           #1d2021;
            @define-color bg0             #282828;
            @define-color bg1             #3c3836;
            @define-color bg2             #504945;
            @define-color bg3             #665c54;
            @define-color bg4             #7c6f64;
            @define-color gray            #928374;
            @define-color fg4             #a89984;
            @define-color fg3             #bdae93;
            @define-color fg2             #d5c4a1;
            @define-color fg1             #ebdbb2;
            @define-color fg0             #fbf1c7;
            @define-color red             #cc241d;
            @define-color bright_red      #fb4934;
            @define-color green           #98971a;
            @define-color bright_green    #b8bb26;
            @define-color yellow          #d79921;
            @define-color bright_yellow   #fabd2f;
            @define-color blue            #458588;
            @define-color bright_blue     #83a598;
            @define-color purple          #b16286;
            @define-color bright_purple   #d3869b;
            @define-color aqua            #689d6a;
            @define-color bright_aqua     #8ec07c;
            @define-color orange          #d65d0e;
            @define-color bright_orange   #fe8019;

            @define-color white           #ffffff;
            @define-color black           #000000;

            /* 
              bg - background
              fg - foreground
              br - border
            */

            /* Main Colors */

            @define-color shadow          shade(@bg0_h, 0.5);
            @define-color main-fg         @fg0;
            @define-color main-bg         @bg0_h;
            @define-color main-br         @fg0;

            @define-color active-bg       @yellow;
            @define-color active-fg       @bg0_h;

            @define-color hover-bg        @bg2;
            @define-color hover-fg        alpha(@fg0, 0.75);

            /* Module Colors */

            @define-color module-fg       @fg0;
            @define-color workspaces      @bg0;

            @define-color temperature     @bg0;
            @define-color memory          @bg1;
            @define-color cpu             @bg2;
            @define-color distro-fg       @black;
            @define-color distro-bg       @yellow;
            @define-color time            @bg2;
            @define-color date            @bg1;
            @define-color tray            @bg0;

            @define-color pulseaudio      @bg0;
            @define-color backlight       @bg1;
            @define-color battery         @bg2;
            @define-color power           @yellow;

            /* State Colors */

            @define-color warning         @bright_orange;
            @define-color critical        @bright_red;
            @define-color charging        @fg0;


        /* style */
        /* ───────────────────────────────────────────────────────────────┤ global ├───
        */
        * {
          min-height: 0;
          border: none;
          margin: 0;
          padding: 0;
        }

        /* ──────────────────────────────────────────────────────────┤ drop shadow ├───
        */
        window#waybar {
          background: @shadow;
        }

        /* ───────────────────────────────────────────────────────────┤ background ├───
        */
        window#waybar > box {
          background: @main-bg;
          margin: 2px;
        }

        /* ─────────────────────────────────────────────────────────────┤ tooltips ├───
        */
        tooltip {
          background: @main-bg;
          border: 1.5px solid @main-br;
          border-radius: 8px;
        }

        tooltip label {
          color: @main-fg;
          margin: -1.5px 3px;
        }

        /* ──────────────────────────────────────────────────────────────┤ general ├───
        */
        #custom-theme,
        #workspaces,
        #window,
        #custom-temperature,
        #memory,
        #cpu,
        #idle_inhibitor,
        #clock,
        #custom-wifi,
        #bluetooth,
        #custom-update,
        #mpris,
        #pulseaudio,
        #backlight,
        #battery,
        #custom-power {
          opacity: 1;
          color: @module-fg;
          padding: 0 4px;
        }

        #custom-left1,
        #custom-left2,
        #custom-left3,
        #custom-left4,
        #custom-left5,
        #custom-left6,
        #custom-left7,
        #custom-left8 {
          margin-bottom: 0;
          text-shadow: -2px 0 2px rgba(0, 0, 0, 0.5);
        }

        #custom-right1,
        #custom-right2,
        #custom-right3,
        #custom-right4,
        #custom-right5 {
          margin-bottom: 0;
          padding-right: 3px;
          text-shadow: 2px 0 2px rgba(0, 0, 0, 0.5);
        }

        /* ───────────────────────────────────────────────────────┤ theme switcher ├───
        */
        #custom-theme {
          background: @main-bg;
        }

        #custom-theme:hover {
          color: @hover-fg;
        }

        /* ───────────────────────────────────────────────────────────┤ workspaces ├───
        */
        #custom-left1 {
          color: @workspaces;
          background: @main-bg;
          margin-bottom: 0;
          padding-left: 2px;
        }

        #workspaces {
          background: @workspaces;
        }

        #workspaces button {
          color: @module-fg;
          border-radius: 8px;
          box-shadow: none;
          margin: 2px 0;
          padding: 0 2px;
          transition: none;
        }

        #workspaces button:hover {
          color: @hover-fg;
          background: @hover-bg;
          text-shadow: none;
        }

        #workspaces button.active {
          color: @active-fg;
          background: @active-bg;
          text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
          box-shadow: 0 0 2px 1px rgba(0, 0, 0, 0.4);
          margin: 2px;
          padding: 0 6px;
        }

        #custom-right1 {
          color: @workspaces;
          background: @main-bg;
          text-shadow: 3px 0 2px rgba(0, 0, 0, 0.4);
          margin-bottom: 0;
        }

        /* ──────────────────────────────────────────────────────────┤ temperature ├───
        */
        #custom-paddc {
          padding-right: 22px;
        }

        #custom-left2 {
          color: @temperature;
          background: @main-bg;
          padding-left: 3px;
        }

        #custom-temperature {
          background: @temperature;
          padding: 0 0 0 1px;
        }

        /* ───────────────────────────────────────────────────────────────┤ memory ├───
        */
        #custom-left3 {
          color: @memory;
          background: @temperature;
          padding-left: 3px;
        }

        #memory {
          background: @memory;
          padding: 0 0 0 1px;
        }

        #memory.warning {
          color: @warning;
        }

        #memory.critical {
          color: @critical;
        }

        /* ──────────────────────────────────────────────────────────────────┤ cpu ├───
        */
        #custom-left4 {
          color: @cpu;
          background: @memory;
          padding-left: 3px;
        }

        #cpu {
          background: @cpu;
        }

        #custom-leftin1 {
          color: @cpu;
          margin-bottom: -1px;
        }

        /* ──────────────────────────────────────────────────────────┤ distro icon ├───
        */
        #custom-left5 {
          color: @distro-bg;
          background: @main-bg;
          text-shadow: none;
          margin-bottom: -2px;
          padding-left: 3px;
        }

        #custom-distro {
          color: @distro-fg;
          background: @distro-bg;
          margin: 0 -1px -2px 0;
          padding: 0 0 0 3px;
          text-shadow: 0 0 1.5px rgba(0, 0, 0, 1);
        }

        #custom-right2 {
          color: @distro-bg;
          background: @main-bg;
          text-shadow: none;
          margin-bottom: -2px;
        }

        /* ─────────────────────────────────────────────────────────────────┤ time ├───
        */
        #custom-rightin1 {
          color: @time;
          margin-bottom: -1px;
        }

        #idle_inhibitor {
          background: @time;
          padding: 0 0 0 7px;
        }

        #idle_inhibitor:hover {
          color: @hover-fg;
        }

        #clock.time {
          background: @time;
          margin-left: -2px;
          padding: 0 3px 0 0;
        }

        #custom-right3 {
          color: @time;
          background: @date;
        }

        /* ─────────────────────────────────────────────────────────────────┤ date ├───
        */
        #clock.date {
          background: @date;
        }

        #clock.date:hover {
          color: @hover-fg;
        }

        #custom-right4 {
          color: @date;
          background: @tray;
        }

        /* ────────────────────────────────────────────────────────────────┤ wi-fi ├───
        */
        #custom-wifi {
          background: @tray;
          padding: 0 8px 0 5px;
        }

        #custom-wifi:hover {
          color: @hover-fg;
        }

        /* ────────────────────────────────────────────────────────────┤ bluetooth ├───
        */
        #bluetooth {
          background: @tray;
          padding-right: 5px;
        }

        #bluetooth:hover {
          color: @hover-fg;
        }

        /* ────────────────────────────────────────────────────────┤ system update ├───
        */
        #custom-update {
          padding-right: 8px;
          background: @tray;
        }

        #custom-update:hover {
          color: @hover-fg;
        }

        #custom-right5 {
          color: @tray;
          background: @main-bg;
        }

        /* ───────────────────────────────────────────────────────────┤ media info ├───
        */
        #mpris {
          background: @main-bg;
          padding: 0 8px 0;
        }

        #mpris:hover {
          color: @hover-fg;
        }

        /* ────────────────────────────────────────────────────────┤ output device ├───
        */
        #custom-left6 {
          color: @pulseaudio;
          background: @main-bg;
          padding-left: 3px;
        }

        #pulseaudio {
          background: @pulseaudio;
        }

        #pulseaudio:hover {
          color: @hover-fg;
        }

        /* ───────────────────────────────────────────────────────────┤ brightness ├───
        */
        #custom-left7 {
          color: @backlight;
          background: @pulseaudio;
          padding-left: 2px;
        }

        #backlight {
          background: @backlight;
        }

        /* ──────────────────────────────────────────────────────────────┤ battery ├───
        */
        #custom-left8 {
          color: @battery;
          background: @backlight;
          padding-left: 2px;
        }

        #battery {
          color: @module-fg;
          background: @battery;
        }

        #battery.warning {
          color: @warning;
        }

        #battery.critical {
          color: @critical;
        }

        #battery.charging {
          color: @charging;
        }

        /* ─────────────────────────────────────────────────────────┤ power button ├───
        */
        #custom-leftin2 {
          color: @battery;
          background: @main-bg;
          margin-bottom: -1px;
        }

        #custom-power {
          color: @main-bg;
          background: @power;
          text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
          box-shadow: 0 0 2px 1px rgba(0, 0, 0, 0.6);
          border-radius: 10px;
          margin: 2px 4px 2px 0;
          padding: 0 6px 0 9px;
        }

        #custom-power:hover {
          color: @hover-fg;
          background: @hover-bg;
          text-shadow: none;
          box-shadow: none;
        }

        /* ───────────────────────────────────────────────────────────┤ font sizes ├───
        */
        /*
          NOTE: Be careful when changing font sizes, as they can affect alignment.

          Try adjusting whole numbers first, then refine with decimals.

          If you increase or decrease a value, make the same change to all properties
          in this section to keep the layout consistent.
        */

        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 10px;
          font-weight: bold;
        }

        tooltip label,
        #window label,
        #mpris {
          font-weight: normal;
        }

        /* ──────────────────────────────────────────────────┤ left & right arrows ├───
        */
        #custom-left1,
        #custom-left2,
        #custom-left3,
        #custom-left4,
        #custom-left5,
        #custom-left6,
        #custom-left7,
        #custom-left8,
        #custom-right1,
        #custom-right2,
        #custom-right3,
        #custom-right4,
        #custom-right5 {
          font-size: 14.68px;
        }

        /* ─────────────────────────────────────────────────┤ left & right inverse ├───
        */
        #custom-leftin1,
        #custom-leftin2,
        #custom-rightin1 {
          font-size: 15.5px;
        }

        /* ──────────────────────────────────────────────────────────┤ distro icon ├───
        */
        #custom-distro {
          font-size: 14.6px;
        }

        #custom-left5,
        #custom-right2 {
          font-size: 15.68px;
        }

        /*
          Adjust these properties as well to keep the design consistent.
        */

        /* ───────────────────────────────────────────────────────────┤ workspaces ├───
        */
        #workspaces button {
          border-radius: 8px;
          padding: 0 2px;
        }

        #workspaces button.active {
          padding: 0 6px;
        }

        /* ─────────────────────────────────────────────────────────┤ power button ├───
        */
        #custom-power {
          border-radius: 10px;
          padding: 0 6px 0 9px;
        }

        /*
          NOTE: If your changes don’t take effect, they might be overridden by
          `animation.css`.

          To fix this, copy your updated font sizes from this file and paste them into
          the corresponding `*_expand` keyframes.

          For example, if you change the font size of the distro icon, update it in
          `distro_expand`.

          - distro icon → `distro_expand` (line 137)
          - power button → `power_expand` (line 152)
          - all other modules → `module_expand` (line 166)
        */

    /*
      NOTE: Restart Waybar to apply changes.
    */

    /* ──────────────────────────────────────────────────────────────┤ phase 1 ├───
    */
    #custom-ws {
      color: transparent;
      text-shadow: none;
      animation: module_in 0.25s ease-in 0.5s forwards;
    }

    #custom-distro {
      color: transparent;
      font-size: 0;
      text-shadow: none;
      animation: distro_expand 0.25s ease-in 0.25s forwards,
        distro_in 0.25s ease-in 0.5s forwards;
    }

    #custom-power {
      font-size: 0;
      text-shadow: none;
      animation: power_expand 0.25s ease-in 0.25s forwards,
        power_in 0.25s ease-in 0.5s forwards;
    }

    /* ──────────────────────────────────────────────────────────────┤ phase 2 ├───
    */
    #workspaces label {
      opacity: 0;
      animation: hoverable_in 0.25s ease-in 1s forwards;
    }

    #cpu,
    #clock.time {
      font-size: 0;
      text-shadow: none;
      color: transparent;
      animation: module_expand 0.25s ease-in 0.75s forwards,
        module_in 0.25s ease-in 1s forwards;
    }

    #idle_inhibitor {
      font-size: 0;
      text-shadow: none;
      animation: module_expand 0.25s ease-in 0.75s forwards,
        hoverable_in 0.25s ease-in 1s forwards;
    }

    #battery {
      color: transparent;
      font-size: 0;
      text-shadow: none;
      animation: module_expand 0.25s ease-in 0.75s forwards,
        battery_in 0.25s ease-in 1s forwards;
    }

    #battery.warning {
      color: transparent;
      animation: module_expand 0.25s ease-in 0.75s forwards,
        state_warning_in 0.25s ease-in 1s forwards;
    }

    #battery.critical {
      color: transparent;
      animation: module_expand 0.25s ease-in 0.75s forwards,
        state_critical_in 0.25s ease-in 1s forwards;
    }

    #battery.charging {
      color: transparent;
      animation: module_expand 0.25s ease-in 0.75s forwards,
        state_charging_in 0.25s ease-in 1s forwards;
    }

    /* ──────────────────────────────────────────────────────────────┤ phase 3 ├───
    */
    #memory,
    #backlight {
      color: transparent;
      font-size: 0;
      text-shadow: none;
      animation: module_expand 0.25s ease-in 1.15s forwards,
        module_in 0.25s ease-in 1.4s forwards;
    }

    #memory.warning {
      color: transparent;
      animation: module_expand 0.25s ease-in 1.15s forwards,
        state_warning_in 0.25s ease-in 1.4s forwards;
    }

    #memory.critical {
      color: transparent;
      animation: module_expand 0.25s ease-in 1.15s forwards,
        state_critical_in 0.25s ease-in 1.4s forwards;
    }

    #clock.date {
      font-size: 0;
      animation: module_expand 0.25s ease-in 1.15s forwards,
        hoverable_in 0.25s ease-in 1.4s forwards;
    }

    /* ──────────────────────────────────────────────────────────────┤ phase 4 ├───
    */
    #window,
    #mpris {
      opacity: 0;
      animation: hoverable_in 0.25s ease-in 1.75s forwards;
    }

    #custom-wifi,
    #bluetooth,
    #custom-update,
    #pulseaudio {
      font-size: 0;
      animation: module_expand 0.25s ease-in 1.5s forwards,
        hoverable_in 0.25s ease-in 1.75s forwards;
    }

    #custom-temperature {
      font-size: 0;
      color: transparent;
      animation: module_expand 0.25s ease-in 1.5s forwards,
        module_in 0.25s ease-in 1.75s forwards;
    }

    /* ────────────────────────────────────────────────────────────┤ keyframes ├───
    */

    /* ──────────────────────────────────────────────────────────── distro icon ───
    */
    @keyframes distro_expand {
      to {
        font-size: 14.6px;
      }
    }

    @keyframes distro_in {
      to {
        color: @distro-fg;
        text-shadow: 0 0 1.5px rgba(0, 0, 0, 1);
      }
    }

    /* ─────────────────────────────────────────────────────────── power button ───
    */
    @keyframes power_expand {
      to {
        font-size: 10px;
      }
    }

    @keyframes power_in {
      to {
        text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
      }
    }

    /* ──────────────────────────────────────────────────────────────── modules ───
    */
    @keyframes module_expand {
      to {
        font-size: 10px;
      }
    }

    @keyframes module_in {
      to {
        color: @module-fg;
        text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
      }
    }

    /* ────────────────────────────────────────────────────────────────┤ fixes ├───
    */

    /* ───────────────────────────────────────────────────────────── hoverables ───
    */
    @keyframes hoverable_in {
      to {
        opacity: 1;
      }
    }

    /* ──────────────────────────────────────────────────────────────── battery ───
    */
    @keyframes battery_in {
      to {
        color: @module-fg;
        text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
      }
    }

    /* ───────────────────────────────────────────────────────────────── states ───
    */
    @keyframes state_warning_in {
      to {
        color: @warning;
        text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
      }
    }

    @keyframes state_critical_in {
      to {
        color: @critical;
        text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
      }
    }

    @keyframes state_charging_in {
      to {
        color: @charging;
        text-shadow: 0 0 2px rgba(0, 0, 0, 0.6);
      }
    }


  '';
}
