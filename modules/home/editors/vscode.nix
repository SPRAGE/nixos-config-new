{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
in
{
  config = mkIf config.modules.editors.vscode.enable {
    programs.vscode.enable = true;

    # Disable stylix theming if you want
    stylix.targets.vscode.enable = false;
  };
}
