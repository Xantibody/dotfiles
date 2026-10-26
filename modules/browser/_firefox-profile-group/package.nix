# main.mts を tsrs で型チェックし、Node の型剥がし実行で動かすラッパーを作る。
{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  nodejs_24,
}:
let
  # 2 週間以上前の版に固定する。0.16.0 で npm のスコープが @ts-rs から @tsrs に、
  # リポジトリが maschwenk/tsrs から oxc-project/tsrs に移ったので、これより古い版は @ts-rs にある
  version = "0.13.0-ts7.1.0-dev.20260929";
  binaries = {
    aarch64-darwin = {
      url = "https://registry.npmjs.org/@ts-rs/darwin-arm64/-/darwin-arm64-${version}.tgz";
      hash = "sha512-tB7r4s5tcdmOYhvf/fMLlJgRqHPW7RCWrusZg61kPLR0GLx+QINZtWZ3arFHN0SgQNTpcrajf+TviUevF/xsEw==";
    };
    x86_64-linux = {
      url = "https://registry.npmjs.org/@ts-rs/linux-x64/-/linux-x64-${version}.tgz";
      hash = "sha512-kx/KvATWJ++fW5wlsd9/mVaMWe30+JRDTLMBSPR/Kz9g4IGgmWXdQUASdK1nBd8iDjOSkKhYhOT+n7L3tNQeLQ==";
    };
  };

  tsrs = stdenvNoCC.mkDerivation {
    pname = "tsrs";
    inherit version;
    src = fetchurl binaries.${stdenvNoCC.hostPlatform.system};
    nativeBuildInputs = lib.optional stdenvNoCC.hostPlatform.isLinux autoPatchelfHook;
    buildInputs = lib.optional stdenvNoCC.hostPlatform.isLinux stdenv.cc.cc.lib;
    installPhase = "install -Dm755 tsrs $out/bin/tsrs";
  };

  # node:sqlite の型のため。@types/node は undici-types に依存する
  typesNode = fetchurl {
    url = "https://registry.npmjs.org/@types/node/-/node-24.13.6.tgz";
    hash = "sha512-SGrw/h3KPFshy3OE6ZL53LMBG5vGQQ8/gIpiqz/kRZhPJ7HgwCEs8LBuNtWLa8dvGZVpSF7+Bf+c11HUrCb/yg==";
  };
  undiciTypes = fetchurl {
    url = "https://registry.npmjs.org/undici-types/-/undici-types-7.18.2.tgz";
    hash = "sha512-AsuCzffGHJybSaRrmr5eHr81mwJU3kjw6M+uprWvCXiNeN9SOGwQ3Jn8jb8m3Z6izVgknn1R0FTCEAP2QrLY/w==";
  };
in
stdenvNoCC.mkDerivation {
  name = "firefox-profile-group";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./main.mts
      ./tsconfig.json
    ];
  };
  nativeBuildInputs = [
    tsrs
    makeWrapper
  ];

  buildPhase = ''
    mkdir -p node_modules/@types/node node_modules/undici-types
    tar xzf ${typesNode} -C node_modules/@types/node --strip-components=1
    tar xzf ${undiciTypes} -C node_modules/undici-types --strip-components=1
    tsrs -p tsconfig.json
  '';

  # node:sqlite と型剥がしはどちらも ExperimentalWarning を出すので黙らせる
  installPhase = ''
    install -Dm644 main.mts $out/share/firefox-profile-group/main.mts
    makeWrapper ${lib.getExe nodejs_24} $out/bin/firefox-profile-group \
      --add-flags --disable-warning=ExperimentalWarning \
      --add-flags $out/share/firefox-profile-group/main.mts
  '';

  meta.mainProgram = "firefox-profile-group";
}
