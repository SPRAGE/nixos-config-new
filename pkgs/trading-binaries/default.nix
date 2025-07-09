{
  lib,
  stdenv,
  autoPatchelfHook,
  glibc,
  gcc-unwrapped,
  # GUI dependencies for index-frontend
  gtk3,
  webkitgtk_4_1,
  cairo,
  gdk-pixbuf,
  libsoup_3,
  glib,
  xdotool,
}:

stdenv.mkDerivation rec {
  pname = "trading-binaries";
  version = "1.0.0";

  src = ../../downloads/trading-x86_64-linux.tar.gz;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    glibc
    gcc-unwrapped.lib
    # GUI dependencies for index-frontend
    gtk3
    webkitgtk_4_1
    cairo
    gdk-pixbuf
    libsoup_3
    glib
    xdotool
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
  passthru = 
    let
      # Common server dependencies
      serverBuildInputs = [ glibc gcc-unwrapped.lib ];
      # GUI frontend dependencies  
      frontendBuildInputs = serverBuildInputs ++ [ 
        gtk3 webkitgtk_4_1 cairo gdk-pixbuf libsoup_3 glib xdotool 
      ];
      
      mkServerBinary = name: binaryName: stdenv.mkDerivation {
        inherit pname version src;
        name = "${name}-${version}";
        installPhase = ''
          mkdir -p $out/bin
          tar -xzf $src
          cp trading-x86_64-linux/bin/${binaryName} $out/bin/
          chmod +x $out/bin/${binaryName}
        '';
        nativeBuildInputs = [ autoPatchelfHook ];
        buildInputs = serverBuildInputs;
      };
      
      mkFrontendBinary = name: binaryName: stdenv.mkDerivation {
        inherit pname version src;
        name = "${name}-${version}";
        installPhase = ''
          mkdir -p $out/bin
          tar -xzf $src
          cp trading-x86_64-linux/bin/${binaryName} $out/bin/
          chmod +x $out/bin/${binaryName}
        '';
        nativeBuildInputs = [ autoPatchelfHook ];
        buildInputs = frontendBuildInputs;
      };
    in {
    auth_server = mkServerBinary "auth-server" "auth-server";
    analysis_server = mkServerBinary "analysis-server" "analysis-server";
    financial_data_consumer = mkServerBinary "financial-data-consumer" "financial-data-consumer";
    historical_data_updater = mkServerBinary "historical-data-updater" "historical-data-updater";
    ingestion_server = mkServerBinary "ingestion-server" "ingestion-server";
    ws_manager = mkServerBinary "ws-manager" "ws_manager";
    ws_subscriber = mkServerBinary "ws-subscriber" "ws-subscriber";
    test_clickhouse = mkServerBinary "test-clickhouse" "test-clickhouse";
    
    # Frontend with GUI dependencies
    index_frontend = mkFrontendBinary "index-frontend" "index-frontend";
  };

  meta = with lib; {
    description = "Pre-compiled trading system binaries";
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
