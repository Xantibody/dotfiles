# ファームウェア更新。ThinkPad の BIOS・EC・指紋センサなどは LVFS から配られる。
# `fwupdmgr refresh && fwupdmgr update` で当てる。
{
  flake.modules.nixos.firmware = {
    services.fwupd.enable = true;
  };
}
