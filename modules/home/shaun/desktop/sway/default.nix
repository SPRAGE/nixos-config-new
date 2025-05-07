# modules/display/windowManager/sway/default.nix
{ pkgs, lib, osConfig, ... }:

let
  inherit (lib) mkDefault mkIf;
in
{
  imports = [
    ./binds.nix
    ./config.nix
    ./startup.nix
  ];

  # enable Sway itself
  services.wayland.windowManager.sway = {
    enable       = true;
    systemd.enable = false;   # we drive it entirely via extraConfig
  };

  # “desktop” helper modules → background, idle, lock
  # modules.desktop = {
  #   swaybg.enable   = mkDefault true;
  #   swayidle.enable = mkDefault false;
  #   swaylock.enable = mkDefault true;
  # };
}
