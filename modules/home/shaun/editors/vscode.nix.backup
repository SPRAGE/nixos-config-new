{ pkgs, ... }:
{
  programs = {
    vscode = {
      enable = true;
      package = (pkgs.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
        src = (builtins.fetchTarball {
          url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
          sha256 = "099vnvh9j163n9yfsqiasy2aq6jhh77ls964017mph1a84njmz7v";
        });
        version = "latest";
        
        # Add runtime dependencies for extensions
        runtimeDependencies = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          openssl
          curl
          krb5
          libsecret
          xorg.libxkbfile
          xorg.libX11
          xorg.libxshmfence
          alsa-lib
          pulseaudio
          libpulseaudio
          glibc
          util-linux
        ];
        
        # Wrap the executable to set LD_LIBRARY_PATH
        postInstall = (oldAttrs.postInstall or "") + ''
          wrapProgram $out/bin/code-insiders \
            --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath (with pkgs; [
              stdenv.cc.cc.lib
              zlib
              openssl
              curl
              krb5
              libsecret
              xorg.libxkbfile
              xorg.libX11
              xorg.libxshmfence
              alsa-lib
              pulseaudio
              libpulseaudio
              glibc
              util-linux
            ])}"
        '';
        
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
      });
    };
  };
  stylix.targets.vscode.enable = false;
}
