{ pkgs }:
let
  noto = pkgs.google-fonts.override {
    fonts = [ "Noto Sans JP" ];
  };
in
pkgs.runCommand "sc-pdf-fonts"
  {
    nativeBuildInputs = [
      (pkgs.python3.withPackages (ps: [ ps.fonttools ]))
    ];
  }
  ''
    font_dir="$out/share/fonts/truetype"
    mkdir -p "$font_dir"
    # The PDF theme expects separate, static TTF files.
    for weight in Regular:400 Bold:700; do
      python3 -m fontTools.varLib.instancer --update-name-table -q \
        -o "$font_dir/NotoSansJP-''${weight%:*}.ttf" '${noto}/share/fonts/truetype/NotoSansJP[wght].ttf' "wght=''${weight#*:}"
    done
    python3 - "$font_dir" <<'PY'
    import sys
    from pathlib import Path
    from fontTools.ttLib import TTCollection

    output = Path(sys.argv[1])
    source = Path("${pkgs.sarasa-gothic}/share/fonts/truetype")
    for style in ("Regular", "Italic", "Bold", "BoldItalic"):
        collection = TTCollection(source / f"Sarasa-{style}.ttc", lazy=True)
        suffix = "Bold-Italic" if style == "BoldItalic" else style
        name = f"Sarasa-Mono-J-{suffix}"
        matches = [font for font in collection.fonts if font["name"].getDebugName(6) == name]
        if len(matches) != 1:
            raise RuntimeError(f"Expected one {name} face, found {len(matches)}")
        matches[0].save(output / f"SarasaMonoJ-{style}.ttf")
        collection.close()
    PY
  ''
