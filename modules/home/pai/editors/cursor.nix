{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options.editors.cursor = {
    enable = mkEnableOption "Enable cursor program";
  };

  config = mkIf config.editors.cursor.enable {
    home.packages = [ pkgs.code-cursor ];
    # optionally add more config here
  };
}
