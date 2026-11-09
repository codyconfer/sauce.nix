{ config, lib, ... }:
{
  sauce.remoteAccess = lib.mkDefault true;

  users.users.${config.sauce.system.user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5IwK4/OtEvb+ow8I0ooM04LVh/lcQ5dCBjXZULCeNM codyconfer@odin"
  ];
}
