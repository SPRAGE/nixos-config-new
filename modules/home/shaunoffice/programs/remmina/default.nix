{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.remmina;

  remminaFiles = builtins.readDir cfg.connectionFilesDir;

  connectionFileNames = builtins.filter (f: lib.hasSuffix ".remmina" f) (
    builtins.attrNames remminaFiles
  );

  remminaSourceTargetPairs = map (fileName: {
    src = "${cfg.connectionFilesDir}/${fileName}";
    dest = "${config.home.homeDirectory}/.local/share/remmina/${fileName}";
  }) connectionFileNames;

  prefFile = "${config.xdg.configHome}/remmina/remmina.pref";

  prefText = ''
    [remmina_pref]
    show_toolbar=${toString (!cfg.disableToolbar)}
    tab_mode=${if cfg.disableTabbing then "false" else "true"}
  '';
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

    overwrite = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If true, delete existing connection files and backups before writing new ones.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.remmina ];

    # Just install the pref file declaratively (no conflict here)
    home.file."${prefFile}".text = prefText;

    # Everything else — handle manually in activation
    home.activation.manageRemminaFiles = ''
      echo "Preparing Remmina connection files..."

      mkdir -p "${config.home.homeDirectory}/.local/share/remmina"

      ${lib.concatStringsSep "\n" (
        map (
          pair:
          if cfg.overwrite then
            ''
              echo "Overwriting ${pair.dest}..."
              rm -f "${pair.dest}" "${pair.dest}.backup" || true
              ln -sf "${pair.src}" "${pair.dest}"
            ''
          else
            ''
              if [ ! -e "${pair.dest}" ]; then
                echo "Linking ${pair.src} -> ${pair.dest}"
                ln -s "${pair.src}" "${pair.dest}"
              else
                echo "Skipping ${pair.dest} (already exists)"
              fi
            ''
        ) remminaSourceTargetPairs
      )}
    '';
  };
}
