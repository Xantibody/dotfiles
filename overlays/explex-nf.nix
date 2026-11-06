final: prev: {
  # AIDEV-NOTE: Explex's build script puts a space in the PostScript name of
  # the Console NF variants ("ExplexConsole NF-Regular"), which the OpenType
  # spec forbids. CoreText reports it as "ExplexConsole-NF-Regular" while the
  # file says otherwise, so felis cannot match the faces and drops the family.
  # Drop this once yuru7/Explex builds the name without the space.
  explex-nf = prev.explex-nf.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      (final.python3.withPackages (ps: [ ps.fonttools ]))
    ];
    postInstall = (old.postInstall or "") + ''
      chmod u+w $out/share/fonts/truetype/*/*.ttf
      python3 - $out/share/fonts/truetype/*/*.ttf <<'EOF'
      import sys
      from fontTools.ttLib import TTFont

      for path in sys.argv[1:]:
          font = TTFont(path)
          for record in font["name"].names:
              if record.nameID == 6:
                  record.string = record.toUnicode().replace(" ", "")
          font.save(path)
      EOF
      chmod 444 $out/share/fonts/truetype/*/*.ttf
    '';
  });
}
