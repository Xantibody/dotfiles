{ inputs }:

with inputs;
[
  (final: _prev: {
    arto = arto.packages.${final.system}.default;
  })
]
