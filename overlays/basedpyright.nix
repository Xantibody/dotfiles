final: prev: {
  basedpyright = prev.basedpyright.overrideAttrs (old: {
    nativeBuildInputs =
      (old.nativeBuildInputs or [ ]) ++ prev.lib.optional prev.stdenv.isDarwin prev.clang_20;
  });
}
