{
  perSystem =
    { pkgs, config, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "nixos-config";
        meta.description = "The default development shell for my NixOS configuration";

        NIX_CONFIG = "extra-experimental-features = nix-command flakes";

        # packages available in the dev shell
        # inputsFrom = [ config.treefmt.build.devShell ];
        #
        packages = [
          # the treefmt command
          config.treefmt.build.wrapper
        ];
        shellHook = ''
          export PS1="\[\e[1;34m\](nixos-config-shell) \[\e[0m\]$PS1"
        '';
      };
    };
}
