{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.programs.windsurf = {
    enable = mkEnableOption "Enable windsurf program";
  };

  config = mkIf config.programs.windsurf.enable {
    home.packages = [ pkgs.windsurf ];
    # optionally add more config here
  };
}
