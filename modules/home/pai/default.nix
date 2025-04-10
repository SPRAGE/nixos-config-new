{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    # inputs.spicetify.homeManagerModules.default
    # ./desktop
    ./programs
    ./roles
    ./services
    ./shell
    ./editors

  ];

  home = {
    username = "pai";
    homeDirectory = "/home/${config.home.username}";
    # <https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion>
    # this is and should remain the version on which you have initiated your config
    stateVersion = "24.11";
  };

  manual = {
    # save space
    html.enable = false;
    json.enable = false;
    manpages.enable = true;
  };

  programs.home-manager.enable = true;

  # reload system units when changing configs
  systemd.user.startServices = mkDefault "sd-switch";
}
