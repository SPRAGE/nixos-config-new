{ config, lib, ... }:

{
  config = {
    users.groups.plugdev = { };
    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="plugdev", TAG+="uaccess"
    '';
  };

}