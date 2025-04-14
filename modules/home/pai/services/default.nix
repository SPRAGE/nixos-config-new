{
  imports = [
    ./nextcloud-client.nix
    ./auth-server.nix
    ./valkey
    ./clickhouse
    # ./sops.nix
    ./xdg.nix
  ];
}
