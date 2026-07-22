# 自作ツール (github:Xantibody/*) をpkgsに載せるoverlay
{ inputs }:

with inputs;
(final: _prev: {
  ichigyo-ls = ichigyo-ls.packages.${final.system}.default;
  c4 = c4.packages.${final.system}.default;
})
