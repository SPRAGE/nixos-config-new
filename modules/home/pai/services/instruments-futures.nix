{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types;

  cfg = config.modules.services.grpcInvoker;

  # build a tiny wrapper that calls both date and grpcurl by absolute path
  invokeBin = pkgs.writeShellScriptBin "grpc-invoke" ''
    #!/usr/bin/env bash
    set -euo pipefail

    DATE_CMD=${pkgs.coreutils}/bin/date
    GRPCURL=${pkgs.grpcurl}/bin/grpcurl

    TARGET_IP="${cfg.targetIp}"
    INSTRUMENT_METHOD="${cfg.instrumentMethod}"
    FUTURES_METHOD="${cfg.futuresMethod}"
    PAYLOAD=${cfg.payload}

    echo "[$($DATE_CMD)] → calling Instrument at $TARGET_IP → $INSTRUMENT_METHOD"
    $GRPCURL -plaintext -d "$PAYLOAD" "$TARGET_IP" "$INSTRUMENT_METHOD"

    echo "[$($DATE_CMD)] → calling Futures  at $TARGET_IP → $FUTURES_METHOD"
    $GRPCURL -plaintext -d "$PAYLOAD" "$TARGET_IP" "$FUTURES_METHOD"
  '';

in {
  options.modules.services.grpcInvoker = {
    enable = mkEnableOption "Enable periodic gRPC invoker";
    targetIp = mkOption { type = types.str; default = "127.0.0.1:50051"; };
    instrumentMethod = mkOption { type = types.str; default = "your.package.InstrumentService/InstrumentMethod"; };
    futuresMethod = mkOption { type = types.str; default = "your.package.FuturesService/FuturesMethod"; };
    payload = mkOption { type = types.nullOr types.str; default = "{}"; };
  };

  config = mkIf cfg.enable {
    # we don’t actually need to pull grpcurl or coreutils into the user PATH
    # because we call them by absolute path in the script.

    systemd.user.services."grpc-invoke" = {
      Unit = {
        Description = "Invoke Instrument & Futures gRPC calls";
        After       = [ "network.target" ];
        Wants       = [ "network.target" ];
      };
      Service = {
        Type      = "oneshot";
        # point at the script’s bin directory
        ExecStart = "${invokeBin}/bin/grpc-invoke";
        Restart   = "no";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    systemd.user.timers."grpc-invoke" = {
      Unit = { Description = "Timer: run grpc-invoke.service every 2h"; };
      Timer = {
        OnUnitActiveSec = "2h";
        Persistent      = true;
      };
      Install = { WantedBy = [ "timers.target" ]; };
    };
  };
}
