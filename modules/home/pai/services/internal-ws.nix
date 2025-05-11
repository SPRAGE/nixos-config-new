{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalString;

  cfg = config.modules.services.internal-websocket;
in
{
  options.modules.services.internal-websocket = {
    enable = mkEnableOption "Enable the internal-websocket server as a user service";

    package = mkOption {
      type = types.package;
      description = "The internal-websocket package to run.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to the TOML config file used by internal-websocket.";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable (e.g., debug, info, warn, error).";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.internal-websocket = {
      Unit = {
        Description = "User-space Rust Internal WebSocket service";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/internal-websocket" ]
          ++ lib.optionals (cfg.configFile != null) [
               "--config" "${cfg.configFile}"
             ]
        );
        Restart     = "on-failure";
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
