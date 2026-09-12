# 音。pipewire と、リアルタイム優先度を取るための rtkit。
{
  flake.modules.nixos.audio =
    { pkgs, ... }:
    {
      services.pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
      };
      security.rtkit.enable = true;
      environment.systemPackages = with pkgs; [
        pulseaudio
        wireplumber
      ];
    };
}
