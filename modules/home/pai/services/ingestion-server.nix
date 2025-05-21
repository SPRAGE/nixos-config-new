{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types;

  # Grab the user’s settings once your module is imported:
  cfg = config.services.grpcInvoker;

  # Build a tiny wrapper script that does the two grpcurl calls:
  invokeBin = pkgs.writeShellScriptBin "grpc-invoke" ''
    #!/usr/bin/env bash
    set -euo pipefail

    TARGET_IP="${cfg.targetIp}"
    INSTRUMENT_METHOD="${cfg.instrumentMethod}"
    FUTURES_METHOD="${cfg.futuresMethod}"
    PAYLOAD=${cfg.payload}

    echo "[$(date)] → calling Instrument at $TARGET_IP → $INSTRUMENT_METHOD"
    grpcurl -plaintext -d "$PAYLOAD" "$TARGET_IP" "$INSTRUMENT_METHOD"

    echo "[$(date)] → calling Futures  at $TARGET_IP → $FUTURES_METHOD"
    grpcurl -plaintext -d "$PAYLOAD" "$TARGET_IP" "$FUTURES_METHOD"
  '';
in
{
  ##############################################################################
  # 1) Option definitions
  ##############################################################################
  options.services.grpcInvoker = {
    enable = mkEnableOption "Enable periodic gRPC invoker";

    targetIp = mkOption {
      type        = types.str;
      default     = "127.0.0.1:50051";
      description = "host:port of both instrument & futures service";
    };

    instrumentMethod = mkOption {
      type        = types.str;
      default     = "your.package.InstrumentService/InstrumentMethod";
      description = "gRPC method for instrument call";
    };

    futuresMethod = mkOption {
      type        = types.str;
      default     = "your.package.FuturesService/FuturesMethod";
      description = "gRPC method for futures call";
    };

    payload = mkOption {
      type        = types.nullOr types.str;
      default     = "{}";
      description = "JSON request body to send (as a single-line string)";
    };
  };

  ##############################################################################
  # 2) When enabled, inject the script, grpcurl, and the two systemd units
  ##############################################################################
  config = mkIf cfg.enable {
    # Ensure grpcurl is in your PATH
    home.packages = [ pkgs.grpcurl ];

    systemd.user.services."grpc-invoke" = {
      Unit = {
        Description = "Invoke Instrument & Futures gRPC calls";
        After       = [ "network.target" ];
        Wants       = [ "network.target" ];
      };

      Service = {
        Type      = "oneshot";
        ExecStart = invokeBin;
        Restart   = "no";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    systemd.user.timers."grpc-invoke" = {
      Unit = {
        Description = "Timer: run grpc-invoke.service every 2h";
      };

      Timer = {
        OnUnitActiveSec = "2h";
        Persistent      = true;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
