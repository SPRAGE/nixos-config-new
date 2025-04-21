{
  imports = [
    ./nextcloud-client.nix
    ./auth-server.nix
    ./valkey
    ./clickhouse
    ./ingestion-server.nix
    ./analysis-server.nix
    ./hist-data.nix
    ./kafka-native.nix
    ./kafka-ui.nix
    ./consumers

    # ./sops.nix
    ./xdg.nix
  ];
}
