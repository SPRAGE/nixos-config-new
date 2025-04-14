{
  imports = [
    ./nextcloud-client.nix
    ./auth-server.nix
    ./valkey

    # ./sops.nix
    ./xdg.nix
  ];
}
