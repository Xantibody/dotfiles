{
  lib,
  stdenvNoCC,
  fetchzip,
  ...
}:
stdenvNoCC.mkDerivation rec {
    pname = "explex-nf";
    version = "0.0.3";

 src = fetchzip {
      url = "https://github.com/yuru7/Explex/releases/download/v${version}/Explex_NF_v${version}.zip";
      hash = "sha256-X4CnYT5B7IyG1Z5Ex6CXCfX7Hz3vNb5bP+vq1Vjx8XI=";
    };

  installPhase = ''
    runHook preInstall

    install -Dm444 ExplexConsole_NF/*.ttf -t $out/share/fonts/truetype/explex-nf-console
    install -Dm444 Explex35Console_NF/*.ttf -t $out/share/fonts/truetype/explex-nf-35console

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
