{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.modules.roles.server = {
    enable = mkEnableOption "Enable the Server role";
  };
}
