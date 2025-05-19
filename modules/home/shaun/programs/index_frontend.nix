{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types;

  cfg = config.modules.programs.index-frontend;
in
{
  options.modules.programs.index-frontend = {
    enable = mkEnableOption "Install the Rust GUI Index Frontend application";

    package = mkOption {
      type = types.package;
      default = inputs.index-frontend.packages.${pkgs.system}.default;
      description = "The index-frontend package to install.";
    };

    desktopFile = mkOption {
      type = types.str;
      default = ''
        [Desktop Entry]
        Name=Index Frontend
        Comment=Rust-based GUI for Financial Index Visualization
        Exec=${cfg.package}/bin/index-frontend
        Icon=utilities-terminal
        Terminal=false
        Type=Application
        Categories=Utility;
      '';
      description = "The content of the .desktop file.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ];

    xdg.desktopEntries.index-frontend = {
      name = "Index Frontend";
      comment = "Rust-based GUI for Financial Index Visualization";
      exec = "${cfg.package}/bin/index-frontend";
      icon = "utilities-terminal"; # you can replace with a custom icon later
      terminal = false;
      categories = [ "Utility" ];
    };
  };
}
