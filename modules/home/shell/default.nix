{ inputs, ... }:
{
  imports = [
    ./tools
    ./yazi
    ./zellij
    ./gpg.nix
    ./starship.nix
    ./zsh.nix

    inputs.nix-index-database.hmModules.nix-index
    { programs.nix-index-database.comma.enable = true; }
  ];
}
