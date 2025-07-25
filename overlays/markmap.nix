{
  lib,
  pnpm_9,
  fetchFromGitHub,
  stdenv,
  makeWrapper,
  nodejs_22,
}:

let
  nodejs = nodejs_22;
  pnpm = pnpm_9.override { inherit nodejs; };
in
stdenv.mkDerivation rec {
  pname = "markmap-cli";
  version = "latest";

  src = fetchFromGitHub {
    owner = "markmap";
    repo = "markmap";
    rev = "master";
    hash = "sha256-X6ZGN1kZbN9I2EduuEB46SLEDrpOubaQ9eh8WygIFA0=";
  };

  pnpmDeps = pnpm.fetchDeps {
    inherit pname version src;
    hash = "sha256-cZ2G83DMnQH7AXDwLiXp/aYPWeeWb9tPsqQu5eQzk8s=";
  };

  nativeBuildInputs = [
    nodejs
    makeWrapper
    pnpm.configHook
  ];

  buildPhase = ''
    runHook preBuild
    cd packages/markmap-cli
    pnpm build
    pnpm prune --prod --ignore-scripts
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cd packages/markmap-cli
    mkdir -p $out/lib/node_modules/markmap-cli
    cp -r -t $out/lib/node_modules/markmap-cli dist node_modules package.json
    mkdir -p $out/bin
    makeWrapper '${nodejs}/bin/node' "$out/bin/markmap" \
      --add-flags "$out/lib/node_modules/markmap-cli/dist/cli.js" \
      --chdir "$out/lib/node_modules/markmap-cli" \
      --set NODE_ENV production
    runHook postInstall
  '';

  meta = with lib; {
    description = "Command-line tool for generating interactive mindmaps from Markdown";
    homepage = "https://markmap.js.org";
    license = licenses.mit;
    maintainers = [ "you" ];
    platforms = platforms.linux;
    mainProgram = "markmap";
  };
}
