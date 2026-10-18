# Karabiner-Elements。macOS のキーの読み替えはここに集める。CapsLock を Control に、
# 左 Control を Hyper (ctrl+alt+shift+cmd) にする。
# Hyper は skhd (Hyper+Q / Hyper+F) と OmniWM (Hyper+C) が受ける。
# AIDEV-NOTE: Hyper は以前 OmniWM の systemHyperTrigger で作っていた。それだと
# OmniWM が古い世代のまま残ったり止まったりしただけで、WM と関係ない skhd の
# ホットキーまで死ぬので、キーの読み替えは WM から切り離してここに置く。
# hidutil (system.keyboard.userKeyMapping) は 1 キーを 1 キーにしか読み替えられず、
# 修飾キー 4 つは作れない
{ config, ... }:
let
  hm = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.karabiner =
    { lib, ... }:
    {
      # AIDEV-NOTE: Karabiner は symlink の付け替えに気づかない (ファイル単位でも
      # ディレクトリごとでも)。なので activation で console_user_server を起こし直して
      # karabiner.json を読ませる
      home.activation.reloadKarabiner = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if /bin/launchctl print "gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server" >/dev/null 2>&1; then
          run /bin/launchctl kickstart -k "gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server"
        fi
      '';

      xdg.configFile."karabiner/karabiner.json".text = builtins.toJSON {
        profiles = [
          {
            name = "Default";
            selected = true;
            virtual_hid_keyboard.keyboard_type_v2 = "ansi";
            # CapsLock は右 Control にする。simple_modifications の出力は
            # complex_modifications に流れるので、左 Control にすると Hyper に化ける。
            # MacBook に右 Control は無いのでぶつかるキーもない
            simple_modifications = [
              {
                from.key_code = "caps_lock";
                to = [ { key_code = "right_control"; } ];
              }
            ];
            complex_modifications.rules = [
              {
                description = "Left Control to Hyper";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "left_control";
                      modifiers.optional = [ "any" ];
                    };
                    to = [
                      {
                        key_code = "left_shift";
                        modifiers = [
                          "left_control"
                          "left_option"
                          "left_command"
                        ];
                      }
                    ];
                  }
                ];
              }
            ];
          }
        ];
      };
    };

  flake.modules.darwin.karabiner =
    { pkgs, ... }:
    {
      services.karabiner-elements = {
        enable = true;
        # HACK(https://github.com/nix-darwin/nix-darwin/issues/1041): nix-darwin の
        # module は 14 系の launchd 構成のままで、15 系 (SMAppService) では起動できない。
        # 直ったら nixpkgs の版に戻す
        package = pkgs.karabiner-elements.overrideAttrs {
          version = "14.13.0";
          src = pkgs.fetchurl {
            url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
            hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
          };
        };
      };

      home-manager.sharedModules = [ hm.karabiner ];
    };
}
