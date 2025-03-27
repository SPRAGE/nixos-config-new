{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.modules.roles.work = {
    enable = mkEnableOption "Enable the Work role";
  };
}
