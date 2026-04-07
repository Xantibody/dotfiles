# overlays/yaskkserv2.nix
final: prev: {
  yaskkserv2 = prev.rustPlatform.buildRustPackage {
    pname = "yaskkserv2";
    version = "unstable-2025-10-12"; # 任意

    src = prev.fetchFromGitHub {
      owner = "wachikun";
      repo = "yaskkserv2";
      rev = "master"; # 固定したい場合はコミットSHAに
      hash = "sha256-6XE/ujU+B/gTd+S4LWQRFk9JbZz1z9SR+Nr7cARqLtY=";
    };

    cargoHash = "sha256-uetEHSv1HMU7KfAPwki1EiaR6zmgRehJL2OGQ/KC/Xc=";

    nativeBuildInputs = [ prev.pkg-config ];
    buildInputs = [ prev.openssl ];

    doCheck = false;
  };
}
