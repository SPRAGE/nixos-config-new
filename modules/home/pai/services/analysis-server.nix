{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.modules.services.analysis-server;
in
{
  options.modules.services.analysis-server = {
    enable = mkEnableOption "Enable Rust-based Analysis Server as a user service";

    package = mkOption {
      type = types.package;
      description = "The analysis-server package to run.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional TOML config file for analysis-server.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.analysis-server = {
      Unit = {
        Description = "User-space Rust Analysis Server";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/analysis-server" ]
          ++ lib.optionals (cfg.configFile != null) [
            "--config"
            "${cfg.configFile}"
          ]
        );
        Restart = "on-failure";
        Environment = [
          "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
          "RUST_LOG=info"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
