# overlays/yaskkserv2.nix
final: prev: {
  yaskkserv2 = prev.rustPlatform.buildRustPackage {
    pname = "yaskkserv2";
    version = "unstable-2025-10-12"; # 任意

    src = prev.fetchFromGitHub {
      owner = "wachikun";
      repo = "yaskkserv2";
      rev = "master"; # 固定したい場合はコミットSHAに
      hash = "sha256-d037sMzr/9fa0Osl0ciQJT6FjdGlxqE7F/K+Iu+HJlw=";
    };

    cargoHash = "sha256-pj08zWyaXTeg6hffFzQo0cH8k1/A8npxwdLtgHnxUpE=";

    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [ prev.openssl ];

    doCheck = false;
  };
}
