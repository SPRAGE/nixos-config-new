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

    #github
    gh

    #home
    home-manager

    #tailscale
    tailscale

    #grpc
    grpcurl


  ];
}
