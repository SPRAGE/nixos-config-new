{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.modules.editors.windsurf;
in {
  options.modules.editors.windsurf = {
    enable = mkEnableOption "Enable Windsurf TUI log viewer";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.windsurf ];
  };
}
