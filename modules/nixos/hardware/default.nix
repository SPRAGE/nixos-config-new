{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  imports = [
    ./cpu
    ./gpu
    ./rgb
    ./bluetooth.nix
    ./printing.nix
    ./sound.nix
    ./mounts.nix
  ];

  options.modules.hardware = {
    # the type of cpu your system has - vm and regular cpus currently do not differ
    cpu = {
      type = mkOption {
        type =
          with types;
          nullOr (enum [
            "pi"
            "intel"
            "vm-intel"
            "amd"
            "vm-amd"
          ]);
        default = null;
        description = ''
          The manufacturer/type of the primary system CPU.

          Determines which ucode services will be enabled and provides additional kernel packages
        '';
      };

      amd = {
        pstate.enable = mkEnableOption "AMD P-State Driver";
      };
    };

    gpu = {
      type = mkOption {
        type =
          with types;
          nullOr (enum [
            "pi"
            "amd"
            "intel"
            "nvidia"
            "hybrid-nv"
            "hybrid-amd"
          ]);
        default = null;
        description = ''
          The manufacturer/type of the primary system GPU.
        '';
      };
    };
  };
}
