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
  cfg = config.modules.services.ws-subscriber;
in
{
  options.modules.services.ws-subscriber = {
    enable = mkEnableOption "Enable ws-subscriber as a user service";

    package = mkOption {
      type = types.package;
      description = "The ws-subscriber package to run.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional TOML config file for ws-subscriber.";
    };

    symbols = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of symbols to subscribe to (e.g., NIFTY, BANKNIFTY).";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable (e.g., debug, info, warn, error).";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.ws-subscriber = {
      Unit = {
        Description = "User-space ws-subscriber service";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/ws-subscriber" ]
          ++ lib.optionals (cfg.configFile != null) [
            "--config"
            "${cfg.configFile}"
          ]
          ++ lib.optionals (cfg.symbols != []) [
            "--symbols"
            (lib.concatStringsSep "," cfg.symbols)
          ]
        );
        Restart = "on-failure";
        Environment = [
          "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
          "RUST_LOG=${cfg.rustLogLevel}"
        ];
      };

      Install = {
        WantedBy = [ "default.target" "multi-user.target" ];
      };
    };
  };
}
