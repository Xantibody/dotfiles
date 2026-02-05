final: prev: {
  brewCasks = prev.brewCasks // {
    google-chrome = prev.brewCasks.google-chrome.overrideAttrs (oldAttrs: {
      src = final.fetchurl {
        url = builtins.head oldAttrs.src.urls;
        hash = "sha256-P1TxSLJRp8hmnHWPk3dLR4frHTWS9JOS+kAVxVEyaWA=";
      };
    });
  };
}
