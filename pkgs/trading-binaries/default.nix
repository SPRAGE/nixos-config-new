{
  lib,
  stdenv,
  autoPatchelfHook,
  glibc,
  gcc-unwrapped,
}:

stdenv.mkDerivation rec {
  pname = "trading-binaries";
  version = "1.0.0";

  src = /home/shaunoffice/codes/nixos-config-new/downlaods/trading-x86_64-linux.tar.gz;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    glibc
    gcc-unwrapped.lib
  ];

  sourceRoot = "trading-x86_64-linux";

  installPhase = ''
    runHook preInstall

    # Create output directories
    mkdir -p $out/bin
    mkdir -p $out/share/trading/config
    mkdir -p $out/share/trading/docs

    # Install binaries
    cp -r bin/* $out/bin/
    
    # Make binaries executable
    chmod +x $out/bin/*

    # Install config and docs
    cp -r config/* $out/share/trading/config/
    cp -r docs/* $out/share/trading/docs/
    cp README.md $out/share/trading/
    
    runHook postInstall
  '';

  # Create individual packages for each binary
  passthru = {
    auth_server = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/auth-server $out/bin/
        chmod +x $out/bin/auth-server
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    analysis_server = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/analysis-server $out/bin/
        chmod +x $out/bin/analysis-server
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    financial_data_consumer = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/financial-data-consumer $out/bin/
        chmod +x $out/bin/financial-data-consumer
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    historical_data_updater = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/historical-data-updater $out/bin/
        chmod +x $out/bin/historical-data-updater
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    index_frontend = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/index-frontend $out/bin/
        chmod +x $out/bin/index-frontend
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    ingestion_server = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/ingestion-server $out/bin/
        chmod +x $out/bin/ingestion-server
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    ws_manager = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/ws_manager $out/bin/
        chmod +x $out/bin/ws_manager
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    ws_subscriber = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/ws-subscriber $out/bin/
        chmod +x $out/bin/ws-subscriber
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };

    test_clickhouse = stdenv.mkDerivation {
      inherit pname version src;
      installPhase = ''
        mkdir -p $out/bin
        tar -xzf $src
        cp trading-x86_64-linux/bin/test-clickhouse $out/bin/
        chmod +x $out/bin/test-clickhouse
      '';
      nativeBuildInputs = [ autoPatchelfHook ];
      buildInputs = [ glibc gcc-unwrapped.lib ];
    };
  };

  meta = with lib; {
    description = "Pre-compiled trading system binaries";
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
