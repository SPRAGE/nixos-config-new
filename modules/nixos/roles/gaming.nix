# Gaming
#
# Do not forget to enable Steam capatability for all title in the settings menu
#
{
  pkgs,
  lib,
  config,
  nix-stable,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.modules.roles.gaming;
  user = config.modules.os.mainUser;
in
{
  options.modules.roles.gaming = {
    enable = mkEnableOption "Enable packages required for the device to be gaming-ready";
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      # default on some gaming (SteamOS) and desktop (Fedora) distributions
      # might help with gaming performance
      "vm.max_map_count" = 2147483642;
      "fs.file-max" = 524288;
    };

    # GPU Performance Optimizations
    boot.kernelParams = [
      "amdgpu.ppfeaturemask=0xffffffff"  # Enable all AMD GPU features
      "amdgpu.gpu_recovery=1"            # Enable GPU recovery
      "amdgpu.deep_color=1"              # Enable deep color
    ];

    programs = {
      steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        protontricks.enable = true;
        gamescopeSession.enable = true;   # Enables "SteamOS" session
        # Compatibility tools to install
        extraCompatPackages = with pkgs; [ 
          proton-ge-bin 
          # nix-stable.gamescope
          ];
      };

      gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          general = {
            softrealtime = "auto";
            renice = 15;
          };
          custom = {
            start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
            end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
          };
        };
      };

      gamescope = {
        enable = true;
        package = nix-stable.gamescope;
      };

    };

    # Additional Game packages
    environment.systemPackages = with pkgs; [
      dxvk
      mangohud
      meson
      goverlay  # GUI for MangoHud
      radeontop  # Monitor AMD GPU usage
      amdgpu_top # Better AMD GPU monitoring
      corectrl   # GUI for GPU/CPU control
      #steam-run
      #protonup-qt

      # Lutris
      libgpg-error
      libxml2
      lutris
      freetype
      gnutls
      openldap
      SDL2
      sqlite
      xml2
    ];

    # required since gamemode 1.8 to change CPU governor
    users.users.${user}.extraGroups = [ "gamemode" ];

    # GPU power and performance settings
    systemd.services.gpu-performance = {
      description = "GPU Performance Optimization";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "gpu-performance" ''
          # Set GPU power limit to maximum
          echo "high" > /sys/class/drm/card1/device/power_dpm_force_performance_level
          echo "performance" > /sys/class/drm/card1/device/power_dpm_state
          
          # Enable maximum power states and overclocking
          if [ -f /sys/class/drm/card1/device/pp_sclk_od ]; then
            echo 1 > /sys/class/drm/card1/device/pp_sclk_od
          fi
          if [ -f /sys/class/drm/card1/device/pp_mclk_od ]; then
            echo 1 > /sys/class/drm/card1/device/pp_mclk_od
          fi
          
          # Set power cap to maximum (adjust based on your GPU)
          if [ -f /sys/class/drm/card1/device/hwmon/hwmon*/power1_cap_max ]; then
            MAX_POWER=$(cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_cap_max)
            echo $MAX_POWER > /sys/class/drm/card1/device/hwmon/hwmon*/power1_cap || true
          fi
        '';
      };
    };

    # Environment variables for GPU performance
    environment.variables = {
      # AMD GPU optimizations
      RADV_PERFTEST = "gpl,nggc,sam,rt";
      RADV_DEBUG = "zerovram,nongg";
      AMD_VULKAN_ICD = "RADV";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
      
      # Force GPU to high performance mode
      DRI_PRIME = "1";
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    };

    services.udev = {
      # packages = with pkgs; [
      #   game-devices-udev-rules
      #   # Dualsense touchpad https://wiki.archlinux.org/title/Gamepad#Motion_controls_taking_over_joypad_controls_and/or_causing_unintended_input_with_joypad_controls
      #   (writeTextFile {
      #     name = "51-disable-Dualshock-motion-and-trackpad.rules";
      #     text = ''
      #       SUBSYSTEM=="input", ATTRS{name}=="*Controller Motion Sensors", RUN+="${pkgs.coreutils}/bin/rm %E{DEVNAME}", ENV{ID_INPUT_JOYSTICK}=""
      #       SUBSYSTEM=="input", ATTRS{name}=="*Controller Touchpad", RUN+="${pkgs.coreutils}/bin/rm %E{DEVNAME}", ENV{ID_INPUT_JOYSTICK}=""
      #     '';
      #     destination = "/etc/udev/rules.d/51-disable-Dualshock-motion-and-trackpad.rules";
      #   })
      # ];

      # extraRules = ''KERNEL=="vhba_ctl", MODE="0660", OWNER="root", GROUP="cdrom"'';
    };
  };
}
