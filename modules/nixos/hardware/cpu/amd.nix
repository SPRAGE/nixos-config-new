{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    versionOlder
    versionAtLeast
    ;
  dev = config.modules.hardware;

  kver = config.boot.kernelPackages.kernel.version;
  inherit (dev.cpu.amd) pstate;
in
{
  config =
    mkIf
      (builtins.elem dev.cpu.type [
        "amd"
        "vm-amd"
      ])
      {

        hardware.cpu.amd.updateMicrocode = true;

        boot = mkMerge [
          {
            kernelModules = [
              "kvm-amd" # AMD virtualization
              "amd-pstate" # load pstate module
              "msr" # x86 CPU MSR access device
            ];
            # Removed: extraModulePackages = [ config.boot.kernelPackages.zenpower ];
          }

          (mkIf (pstate.enable && (versionAtLeast kver "5.17") && (versionOlder kver "6.1")) {
            kernelParams = [ "initcall_blacklist=acpi_cpufreq_init" ];
            kernelModules = [ "amd-pstate" ];
          })

          (mkIf (pstate.enable && (versionAtLeast kver "6.1") && (versionOlder kver "6.3")) {
            kernelParams = [ "amd_pstate=passive" ];
          })

          (mkIf (pstate.enable && (versionAtLeast kver "6.3")) {
            kernelParams = [ "amd_pstate=active" ];
          })
        ];

        # Removed: zenstates service
      };
}
