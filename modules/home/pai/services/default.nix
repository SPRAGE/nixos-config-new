{
  imports = [
    ./nextcloud-client.nix
    ./auth-server.nix
    ./valkey
    ./clickhouse
    ./ingestion-server.nix
    ./analysis-server.nix
    ./hist-data.nix

    # ./sops.nix
    ./xdg.nix
  ];
}
