{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./config.nix
    ./binds.nix
    ./startup.nix
  ];
}
