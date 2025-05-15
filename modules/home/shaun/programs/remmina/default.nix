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
    show_toolbar=${toString cfg.showToolbar}
    tab_mode=${toString cfg.tabMode}
    group_by_group=${toString cfg.groupByGroup}
    hide_toolbar=${toString cfg.hideToolbar}
    dark_theme=${toString cfg.darkTheme}
    save_view_mode=${toString cfg.saveViewMode}
    confirm_close=${toString cfg.confirmClose}
  '';
in
{
  options.modules.programs.remmina = {
    enable = lib.mkEnableOption "Enable Remmina and configure global preferences.";

    connectionFilesDir = lib.mkOption {
      type = lib.types.path;
      default = ./connections;
      description = "Directory containing .remmina connection files.";
    };

    overwrite = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If true, delete existing connection files and backups before writing new ones.";
    };

    showToolbar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show the top Remmina toolbar (show_toolbar).";
    };

    tabMode = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = ''
        Tab grouping mode (tab_mode):
        0 = by group, 1 = by protocol, 2 = by connection, 3 = none.
      '';
    };

    groupByGroup = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Group connections by group in tabs (group_by_group).";
    };

    hideToolbar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hide the left-side toolbar/sidebar in connection windows (hide_toolbar).";
    };

    darkTheme = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use dark theme (dark_theme).";
    };

    saveViewMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Save the last view mode (save_view_mode).";
    };

    confirmClose = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Confirm before closing multiple tabs (confirm_close).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.remmina ];

    home.file."${prefFile}".text = prefText;

    home.activation.manageRemminaFiles = ''
      echo "[remmina] Preparing connection files..."

      mkdir -p "${config.home.homeDirectory}/.local/share/remmina"
      mkdir -p "${config.xdg.configHome}/remmina"

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
