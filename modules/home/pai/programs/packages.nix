{
  inputs,
  pkgs,
  ...
}:
let
  orca-slicer-beta = pkgs.callPackage ../../../../pkgs/orca-slicer-appimage.nix { };
in
{
  home.packages = with pkgs; [
    # Terminal Utils
    fastfetch

    # Video/Audio
    pwvucontrol

    #office
    libreoffice
    galculator

    #github
    gh

    #home
    home-manager

    #ntfs
    ntfs-3g

  ];
}
