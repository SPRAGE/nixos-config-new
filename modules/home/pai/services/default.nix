{
  imports = [
    ./auth-server.nix
    ./valkey
    ./clickhouse
    ./ingestion-server.nix
    ./analysis-server.nix
    ./hist-data.nix
    ./kafka-native.nix
    ./kafka-ui.nix
    ./consumers
    ./ws-manager.nix
    ./internal-ws.nix

    # ./sops.nix
    ./xdg.nix
  ];
}
