{
  imports = [
    ./nextcloud-client.nix
    ./auth-server.nix
    ./valkey
    ./clickhouse
    ./analysis-server.nix
    # ./sops.nix
    ./xdg.nix
  ];
}
