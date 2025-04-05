{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.editors.windsurf = {
    enable = mkEnableOption "Enable windsurf program";
  };

  config = mkIf config.editors.windsurf.enable {
    home.packages = [ pkgs.windsurf ];
    # optionally add more config here
  };
}
