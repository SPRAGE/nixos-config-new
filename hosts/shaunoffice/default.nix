{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    (import ../disks/lvm-btrfs.nix {
      disks = [ "/dev/sda" ];
      swapSize = "8G";
    })
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "shaunoffice";
    # interfaces.enp8s0.wakeOnLan.enable = true;
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # home-manager modules
  home-manager.users.${config.modules.os.mainUser}.config.modules = {
    theme.wallpaper = ../../modules/home/shaun/theming/wallpaper;
  };

  modules = {

    roles = {
      desktop.enable = true;
      development.enable = true;
      work.enable = true;
    };

    hardware = {
      cpu.type = "intel";
      sound.enable = true;

    };

    display = {
      gpuAcceleration.enable = true;
      desktop = {
        enable = true;
        defaultWindowManager = "sway";
        sway.enable = true;
        # hyprland.enable = true;
      };
      monitors = [
        {
          name = "HDMI-2";
          resolution = "1920x1080";
          position = "0x0";
          refreshRate = 60;
          scale = "1";
          primary = true;
          workspaces = [
            2
            4
            6
            8
            10
          ];
        }
        {
          name = "DP-1";
          resolution = "1920x1080";
          scale = "1";
          refreshRate = 60;
          position = "1920x0";
          workspaces = [
            1
            3
            5
            7
            9
          ];
        }
      ];
    };

    programs = {
      thunar.enable = true;
      tailscale.enable = true;
    };

    os = {
      mainUser = "shaunoffice";
      users = [ "shaunoffice" ];
      autoLogin = true;
    };

    # networking.optomizeTcp = true;

    boot = {
      enableKernelTweaks = true;
      impermanence.enable = false;
    };
  };

  hardware = {
    # Udev rules for vial
    keyboard.qmk.enable = true;

  };

}
