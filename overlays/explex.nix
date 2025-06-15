{
  lib,
  stdenvNoCC,
  fetchzip,
  ...
}:
stdenvNoCC.mkDerivation rec {
    pname = "explex";
    version = "0.0.3";

 src = fetchzip {
      url = "https://github.com/yuru7/Explex/releases/download/v${version}/Explex_v${version}.zip";
      hash = "sha256-OUmzF8GrwVgFAMSEiZLvh85nsOw1a0a7B70u2cRXXO8=";
    };

  installPhase = ''
    runHook preInstall

    install -Dm444 Explex/*.ttf -t $out/share/fonts/truetype/explex
    install -Dm444 Explex35/*.ttf -t $out/share/fonts/truetype/explex-35
    install -Dm444 ExplexConsole/*.ttf -t $out/share/fonts/truetype/explex-console
    install -Dm444 Explex35Console/*.ttf -t $out/share/fonts/truetype/explex-35console

    runHook postInstall
  '';
    meta = with lib; {
      description = "Explex font by yuru7";
      homepage = "https://github.com/yuru7/Explex";
      license = licenses.ofl;
      platforms = platforms.all;
    maintainers = with maintainers; [ r-aizawa ];
    };
}
