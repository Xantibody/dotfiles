{
  enable = true;
  extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="10a5", ATTR{idProduct}=="d805", MODE="0666"
  '';
}