{ inputs, config, ... }:
let
  accent = "#${config.lib.stylix.colors.base0D}";
  accent-alt = "#${config.lib.stylix.colors.base03}";
  background = "#${config.lib.stylix.colors.base00}";
  background-alt = "#${config.lib.stylix.colors.base01}";
  foreground = "#${config.lib.stylix.colors.base05}";
  rounding = 18;
in
{
  imports = [
    inputs.hyprpanel.homeManagerModules.hyprpanel
  ];

  programs.hyprpanel = {
    overlay.enable = true;
    enable = true;
    # systemd.enable = true;
    hyprland.enable = true;
    overwrite.enable = true;
    layout = {
      "bar.layouts" = {
        "0" = {
          "left" = [
            "dashboard"
            "workspaces"
            "windowtitle"
          ];
          "middle" = [ ]; # Add this line
          "right" = [
            "clock"
          ];
        };

        "1" = {
          "left" = [
            "dashboard"
            "workspaces"
            "windowtitle"
          ];
          "middle" = [
            "clock"
            "media"
          ];
          "right" = [
            "volume"
            "bluetooth"
            "network"
            "systray"
            "notifications"
          ];
        };
      };
    };

    override = {
      tear = true; # Screen Tearing
      scalingPriority = "hyprland";
      bar = {
        customModules.updates.pollingInterval = 1440000;
        launcher.icon = "";
        workspaces = {
          showAllActive = false;
          workspaces = 1;
          monitorSpecific = false;
          hideUnoccupied = true;
          showApplicationIcons = true;
          showWsIcons = true;
          ignored = "98";
        };
        windowtitle.label = false;
        clock.format = "%a %d-%m-%Y  %k:%M:%S";
        clock.showIcon = false;
        volume.label = true;
        bluetooth.label = false;
        network.label = true;
        media.show_active_only = true;
      };
      menus.clock.weather.enable = false;
      wallpaper.enable = false;
    };
    theme = {
      # === Fonts ===
      font.size = "1rem";

      # === Bar Layout ===
      bar = {
        outer_spacing = "1rem";
        dropdownGap = "3.3em";

        background = background;
        buttons = {
          monochrome = true;
          text = foreground;
          radius = "${toString rounding}px";
          background = background-alt;
          icon = accent;
          hover = background;

          workspaces = {
            hover = accent-alt;
            active = accent;
            available = accent-alt;
          };

          notifications = {
            background = background-alt;
            hover = background;
            total = accent;
            icon = accent;
          };
        };

        menus = {
          monochrome = true;

          background = background;
          cards = background-alt;
          card_radius = "${toString rounding}px";
          border = {
            color = accent;
            radius = "${toString rounding}px";
          };
          label = foreground;
          text = foreground;

          popover = {
            text = foreground;
            background = background-alt;
          };

          listitems.active = accent;
          icons.active = accent;
          switch.enabled = accent;

          buttons = {
            default = accent;
            active = accent;
          };

          iconbuttons.active = accent;

          progressbar.foreground = accent;
          slider.primary = accent;

          tooltip = {
            background = background-alt;
            text = foreground;
          };

          dropdownmenu = {
            background = background-alt;
            text = foreground;
          };

          menu.media = {
            background.color = background-alt;
            card.color = background-alt;
            card.tint = 90;
          };
        };
      };

      # === Notifications ===
      notification = {
        background = background-alt;
        border = background-alt;
        border_radius = "${toString rounding}px";
        label = accent;
        labelicon = accent;
        text = foreground;

        actions = {
          background = accent;
          text = foreground;
        };
      };

      # === OSD (On-screen Display) ===
      osd = {
        bar_color = accent;
        bar_overflow_color = accent-alt;
        icon = background;
        icon_container = accent;
        label = accent;
        bar_container = background-alt;
      };
    };

  };
}
