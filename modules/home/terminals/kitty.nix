{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
  cfg = config.modules.shell.kitty;
in
{
  options.modules.shell.kitty = {
    enable = mkEnableOption "Enable kitty terminal config";

    font = mkOption {
      type = types.str;
      default = "JetBrainsMono Nerd Font";
      description = "Font name used by kitty.";
    };

    sshAlias = mkOption {
      type = types.bool;
      default = true;
      description = "Enable kitty-enhanced SSH alias.";
    };
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      font.name = cfg.font;

      shellIntegration.enableZshIntegration = true;

      settings = {
        confirm_os_window_close = 0;
        placement_strategy = "center";
        enable_audio_bell = false;
      };

      keybindings = {
        "ctrl+tab" = "send_text all \\x1b[9;5u"; # <C-Tab>
        "ctrl+shift+tab" = "send_text all \\x1b[9;6u"; # <C-S-Tab>
      };
    };

    home.shellAliases = mkIf cfg.sshAlias {
      ssh = "kitten ssh --kitten=color_scheme=Dracula";
    };
  };
}
