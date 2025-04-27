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

    # ./sops.nix
    ./xdg.nix
  ];
}
