{ pkgs, config, lib, inputs, ... }:
let
  inherit (lib) mkIf mkEnableOption;
in {
  options.modules.programs.nvim = {
    enable = mkEnableOption "Enable nvim";
  };

  config = mkIf config.modules.programs.nvim.enable {
    # Install the nvim package
    environment.systemPackages = [
     inputs.nvix.packages.${pkgs.system}.default
    ];
  };
}