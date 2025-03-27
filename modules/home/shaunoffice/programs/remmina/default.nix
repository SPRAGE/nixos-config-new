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
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ remmina ];

    xdg.dataFile = remminaFileAttrs;
  };
}
