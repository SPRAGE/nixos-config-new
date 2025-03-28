{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.editors;
in
{
  imports = [
    ./vscode.nix
    ./neovim
  ];

  options.modules.editors = {
    enable = mkEnableOption "Enable editor configuration";

    vscode.enable = mkEnableOption "Enable VS Code";
    neovim.enable = mkEnableOption "Enable Neovim";
  };

  config = mkIf cfg.enable {
    # Optional: base config or default tools for all editors
  };
}
