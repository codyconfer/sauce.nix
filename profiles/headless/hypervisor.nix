{ lib, ... }:
{
  sauce.emulators = lib.mkDefault [ "qemu" ];
}
