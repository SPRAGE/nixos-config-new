{
  config,
  pkgs,
  lib,
  ...
}:

let
  mod = "Mod4"; # SUPER
  terminal = "${pkgs.kitty}/bin/kitty";
  fileManager = "${pkgs.xfce.thunar}/bin/thunar";
  launcher = "${pkgs.rofi}/bin/rofi -show drun";
  cliphist = "${pkgs.cliphist}/bin/cliphist";
in
{
  wayland.windowManager.sway = {
    enable = true;

    config = {
      modifier = mod;
      terminal = terminal;

      startup = [
        {
          command = "wl-paste --watch ${cliphist} store";
          always = true;
        }
        { command = "${pkgs.wlsunset}/bin/wlsunset -l 32.7 -L -96.9"; }
        { command = "swaymsg workspace 1"; }
      ];

      input = {
        "*" = {
          tap = "enabled";
          accel_profile = "flat";
        };
      };

      output = {
        "*" = {
          bg = "${config.home.homeDirectory}/.background-image fill";
        };
      };

      keybindings =
        lib.mkOptionDefault {
          # App Launchers
          "${mod}+Return" = "exec ${terminal}";
          "${mod}+e" = "exec ${terminal} -e yazi";
          "${mod}+d" = "exec ${launcher}";
          "${mod}+Shift+e" = "exec ${fileManager}";
          "${mod}+v" = "exec ${cliphist} list | ${launcher} | ${cliphist} decode | wl-copy";
          "Ctrl+Shift+Escape" = "exec ${terminal} -e btop";

          # Window management
          "${mod}+q" = "kill";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+g" = "floating toggle";
          "${mod}+Shift+r" = "reload";

          # Movement
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";

          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";

          # Workspaces
          # $mod+[1..9] for switch, Shift+$mod+[1..9] for move
        }
        // lib.listToAttrs (
          builtins.concatMap (
            i:
            let
              num = builtins.toString (i + 1);
            in
            [
              {
                name = "${mod}+${num}";
                value = "workspace number ${num}";
              }
              {
                name = "${mod}+Shift+${num}";
                value = "move container to workspace number ${num}";
              }
            ]
          ) (lib.range 0 9)
        );

      floating = {
        titlebar = true;
      };

      # Optional: assign apps to workspaces (Sway equivalent of windowrules)
      assigns = {
        "8" = [
          { app_id = "steam"; }
          { app_id = "lutris"; }
        ];
        "4" = [ { title = ".*(Discord|ArmC|WebCord).*"; } ];
      };
    };
  };

  home.packages = with pkgs; [
    grimblast
    wl-clipboard
    wlsunset
    cliphist
  ];
}
