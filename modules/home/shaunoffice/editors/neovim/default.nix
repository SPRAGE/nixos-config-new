# Neovim
#
{ inputs, pkgs, ... }:
{

  home.packages = with pkgs; [
    # inputs.nvix.packages.${system}.default
    inputs.nvix.packages.${pkgs.system}.full

  ];
}
