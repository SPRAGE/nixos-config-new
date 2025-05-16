{ config, pkgs, ... }:
{
  imports = [
    ../../modules/home
  ];

  # Example: set wallpaper using a reusable module
  # You can add more host-specific home-manager config here
  home.file.wallpaper = {
    source = ../../modules/home/shaun/theming/wallpaper;
    target = ".config/wallpaper.png";
  };
} 