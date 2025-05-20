{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf types;

  cfg = config.services.grpcInvoker;
  invokeBin = pkgs.writeShellScriptBin "invoke-grpc" ''
    #!/usr/bin/env bash
    set -euo pipefail

    TARGET_IP="${cfg.targetIp}"
    INSTRUMENT_METHOD="${cfg.instrumentMethod}"
    FUTURES_METHOD="${cfg.futuresMethod}"

    PAYLOAD=$(cat <<EOF
        ${cfg.payload}
        EOF
        )

    echo "[$(date)] → calling Instrument at $TARGET_IP → $INSTRUMENT_METHOD"
    grpcurl -plaintext -d "$PAYLOAD" "$TARGET_IP" "$INSTRUMENT_METHOD"

    echo "[$(date)] → calling Futures  at $TARGET_IP → $FUTURES_METHOD"
    grpcurl -plaintext -d "$PAYLOAD" "$TARGET_IP" "$FUTURES_METHOD"
  '';
in
{
  options.services.grpcInvoker = {
    enable = mkEnableOption "Enable periodic gRPC invoker";
    targetIp = mkOption {
      type = types.str;
      default = "127.0.0.1:50051";
      description = "host:port of both instrument & futures service";
    };
    instrumentMethod = mkOption {
      type = types.str;
      default = "your.package.InstrumentService/InstrumentMethod";
      description = "gRPC method for instrument call";
    };
    futuresMethod = mkOption {
      type = types.str;
      default = "your.package.FuturesService/FuturesMethod";
      description = "gRPC method for futures call";
    };
    payload = mkOption {
      type = types.str;
      default = "{}";
      description = "JSON request body to send";
    };
  };

  config = mkIf cfg.enable {
    # run once per invocation
    systemd.services.grpc-invoke = {
      description = "Invoke instrument → futures gRPC calls";
      after = [ "network.target" ];
      wants = [ "network.target" ];
      serviceConfig = {
        Type      = "oneshot";
        ExecStart = "${invokeBin} ${cfg.targetIp} ${cfg.instrumentMethod} ${cfg.futuresMethod}";
      };
      install.WantedBy = [ "multi-user.target" ];
    };

    # every 2 hours
    systemd.timers.grpc-invoke = {
      description = "Run grpc-invoke.service every 2 hours";
      wants = [ "grpc-invoke.service" ];
      timerConfig = {
        OnUnitActiveSec = "2h";
        Persistent      = true;
      };
      install.WantedBy = [ "timers.target" ];
    };
  };
}
