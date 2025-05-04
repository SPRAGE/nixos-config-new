# modules/display/windowManager/sway/config.nix
{ osConfig, lib, ... }:

let
  # grab your monitor list from your display module
  inherit (osConfig.modules.display) monitors;

  # turn each monitor name into a sway “output …” line
  outputs = builtins.map (mon: ''
    output ${mon} scale 1 transform normal
  '') monitors;
in
{
  # only append this fragment when sway is turned on
  config = lib.mkIf osConfig.services.wayland.windowManager.sway.enable {
    services.wayland.windowManager.sway.extraConfig = lib.concatStringsSep "\n" [
      # set the $mod key to Mod4
      "set \$mod Mod4"
      # set up each output
      (lib.concatStringsSep "\n" outputs)
      # force integer scaling in Xwayland (if you need it)
      "xwayland disable_fractional_scaling"
    ];
  };
}
