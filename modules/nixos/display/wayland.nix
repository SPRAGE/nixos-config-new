{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge mkIf;

  cfg = config.modules.display.desktop;
in
{
  config = mkMerge [
    (mkIf cfg.isWayland {

      environment.variables = {
        NIXOS_OZONE_WL = "1";
        _JAVA_AWT_WM_NONEREPARENTING = "1";
        ANKI_WAYLAND = "1";
        WLR_DRM_NO_ATOMIC = "1";
      };
    })

    # Session for greetd
    (mkIf cfg.hyprland.enable {
      programs.hyprland = {
        enable = true;
        # needed for setting the wayland environment variables
        withUWSM = true;
      };
      

      xdg.portal = {
        enable = true;
        # xdgOpenUsePortal = true;
        # config.common = {
        #   "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        #   "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        #   "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        #   "org.freedesktop.portal.FileChooser" = [ "xdg-desktop-portal-gtk" ];
        # };

        extraPortals = with pkgs; [
          # xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };

      # allow wayland lockers to unlock the screen
      security.pam.services.hyprlock.text = "auth include login";

      



    })

    # Session for greetd
    (mkIf cfg.sway.enable {
      programs.sway = {
        enable = true;
        extraPackages = with pkgs; [ brightnessctl foot grim pulseaudio swayidle swaylock wmenu waybar ];
      };

      programs.waybar.enable = true;

      xdg.portal = {
        enable = true;
        # xdgOpenUsePortal = true;
        # config.common = {
        #   "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        #   "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        #   "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        #   "org.freedesktop.portal.FileChooser" = [ "xdg-desktop-portal-gtk" ];
        # };

        extraPortals = with pkgs; [
          # xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };

      # allow wayland lockers to unlock the screen
      security.pam.services.hyprlock.text = "auth include login";

    })

    




  ];
}
