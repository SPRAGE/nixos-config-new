{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.editors;
in
{
  imports = [
    ./vscode.nix
    ./neovim.nix
  ];

  options.modules.editors = {
    enable = mkEnableOption "Enable editor configuration";

    vscode.enable = mkEnableOption "Enable VS Code";
    neovim.enable = mkEnableOption "Enable Neovim";
     windsurf.enable = lib.mkEnableOption "Enable Windsurf log viewer";
  };

  config = mkIf cfg.enable {
    # Optional: base config or default tools for all editors
  };
}
