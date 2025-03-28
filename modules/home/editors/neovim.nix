# Neovim
#
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf;
in
{
  config = mkIf config.modules.editors.neovim.enable {
    home.packages = with pkgs; [ inputs.nvix.packages.${pkgs.system}.default ];
  };
}
