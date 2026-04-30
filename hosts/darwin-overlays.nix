{ inputs }:

with inputs;
[
  (final: _prev: {
    arto = arto.packages.${final.system}.default;
    magical-merchant = magical-merchant.packages.${final.system}.default;
  })
]
