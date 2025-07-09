# Trading System Binary Management

This document explains how to download and manage the trading system binaries required for the NixOS configuration.

## Quick Start

```bash
# Download binaries (first time setup)
./download-binaries.sh

# Or use make
make download-binaries

# Build the dataserver configuration
make build-dataserver

# Check if everything is working
make check-binaries
```

## Download Script Usage

The `download-binaries.sh` script provides several options for downloading and managing the trading system binaries:

### Basic Usage

```bash
# Download with default settings
./download-binaries.sh

# Show help
./download-binaries.sh --help

# Force re-download even if file exists
./download-binaries.sh --force

# Download and verify checksums
./download-binaries.sh --verify

# Use custom URL
./download-binaries.sh --url https://your-custom-url.com/binaries.tar.gz

# Dry run (show what would be done)
./download-binaries.sh --dry-run
```

### Configuration

The download configuration is stored in `download-config.env`. You can edit this file to:

- Set the correct download URLs for your binaries
- Update version information
- Configure expected checksums for verification
- Set retry and timeout parameters

### Expected Binaries

The following binaries should be present in the downloaded archive:

- `analysis-server` - Financial analysis server
- `auth-server` - Authentication server
- `financial-data-consumer` - Kafka consumer for financial data
- `historical-data-updater` - Historical data management
- `index-frontend` - GUI frontend application
- `ingestion-server` - Data ingestion server
- `test-clickhouse` - ClickHouse testing utility
- `ws_manager` - WebSocket manager
- `ws-subscriber` - WebSocket subscriber

## Makefile Targets

The `Makefile` provides convenient targets for common operations:

### Download Operations
- `make download-binaries` - Download trading system binaries
- `make download-force` - Force re-download of binaries
- `make download-verify` - Download and verify with checksums
- `make check-binaries` - Check if binaries are present and valid

### Build Operations
- `make build-dataserver` - Build the dataserver NixOS configuration
- `make build-packages` - Build just the trading packages
- `make build-all` - Build all NixOS configurations

### Development
- `make dev-check` - Run syntax checks and binary verification
- `make dev-build` - Download binaries and build dataserver
- `make dev-shell` - Enter Nix development shell

### Maintenance
- `make clean` - Clean build artifacts
- `make clean-downloads` - Remove downloaded binaries (with confirmation)
- `make format` - Format Nix files with nixpkgs-fmt
- `make update-flake` - Update flake.lock

### Status
- `make status` - Show current system status
- `make help` - Show all available targets

## File Organization

```
nixos-config-new/
├── download-binaries.sh      # Main download script
├── download-config.env       # Download configuration
├── Makefile                  # Build automation
├── downlaods/               # Downloaded binaries directory
│   └── trading-x86_64-linux.tar.gz
└── pkgs/trading-binaries/   # Nix package definition
    └── default.nix
```

## Security Considerations

1. **Checksums**: Always verify checksums when downloading from external sources
2. **URLs**: Use HTTPS URLs and trusted sources
3. **Git Ignore**: The binary files are excluded from git to prevent accidental commits
4. **Access Control**: Ensure binary download sources require proper authentication

## Troubleshooting

### Download Fails
1. Check internet connectivity
2. Verify the download URL in `download-config.env`
3. Check if the remote server is accessible
4. Try using `--force` to re-download

### Binary Verification Fails
1. Check if the downloaded file is corrupted
2. Verify the expected checksums in `download-config.env`
3. Re-download with `--force`

### Build Fails After Download
1. Verify all expected binaries are in the archive: `make check-binaries`
2. Check the tar.gz file integrity: `tar -tzf downlaods/trading-x86_64-linux.tar.gz`
3. Ensure the file permissions are correct

### Missing Dependencies
The download script requires:
- `curl` or `wget` for downloading
- `tar` for archive operations
- `sha256sum` for checksum verification

Install missing dependencies with your system package manager.

## CI/CD Integration

For automated builds and deployments:

```bash
# Prepare environment
make ci-prepare

# Run tests
make ci-test

# Deploy (if tests pass)
make deploy-dataserver
```

## Version Management

Update the version information in `download-config.env` when new binary releases are available:

1. Update `BINARY_VERSION`
2. Update download URLs
3. Update expected checksums
4. Test with `./download-binaries.sh --verify`
