{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.programs.remmina;

  remminaFiles = builtins.readDir cfg.connectionFilesDir;

  remminaFileNames = builtins.filter (f: lib.hasSuffix ".remmina" f) (
    builtins.attrNames remminaFiles
  );

  remminaFileAttrs = builtins.listToAttrs (
    map (fileName: {
      name = "remmina/${fileName}";
      value.source = cfg.connectionFilesDir + "/${fileName}";
    }) remminaFileNames
  );
in
{
  options.modules.programs.remmina = {
    enable = lib.mkEnableOption "Enable Remmina and optionally configure connection files";

    connectionFilesDir = lib.mkOption {
      type = lib.types.path;
      default = ./connections;
      description = "Directory containing .remmina connection files";
    };

    disableToolbar = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable the visibility of the toolbar in Remmina.";
    };

    disableTabbing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable tabbing in Remmina.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ remmina ];

    xdg.dataFile = remminaFileAttrs;

    home.file."${config.xdg.configHome}/remmina/remmina.pref".text = lib.mkIf (!builtins.pathExists "${config.xdg.configHome}/remmina/remmina.pref") ''
      [remmina_pref]
      show_toolbar=${toString (!cfg.disableToolbar)}
      tab_mode=${if cfg.disableTabbing then "false" else "true"}
    '';
  };
}
