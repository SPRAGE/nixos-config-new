# TODO: Configure Binary Downloads

## ⚠️ Important: Update Download Configuration

Before using the download script in production, you need to update the download configuration with real URLs and checksums.

### Required Updates in `download-config.env`:

1. **Replace placeholder URLs** with actual download locations:
   ```bash
   # Change these lines:
   PRIMARY_DOWNLOAD_URL="https://github.com/your-org/trading-binaries/releases/download/v${BINARY_VERSION}/trading-x86_64-linux.tar.gz"
   MIRROR_DOWNLOAD_URL="https://releases.example.com/trading/v${BINARY_VERSION}/trading-x86_64-linux.tar.gz"
   
   # To your actual URLs:
   PRIMARY_DOWNLOAD_URL="https://your-actual-domain.com/releases/v${BINARY_VERSION}/trading-x86_64-linux.tar.gz"
   MIRROR_DOWNLOAD_URL="https://backup-server.com/trading/v${BINARY_VERSION}/trading-x86_64-linux.tar.gz"
   ```

2. **Add real SHA256 checksums**:
   ```bash
   # Generate checksum for your actual binary:
   sha256sum downloads/trading-x86_64-linux.tar.gz
   
   # Update this line:
   EXPECTED_SHA256="PUT_ACTUAL_SHA256_HERE"
   # With the actual checksum:
   EXPECTED_SHA256="abc123def456..."
   ```

3. **Update version information**:
   ```bash
   BINARY_VERSION="1.0.0"  # Your actual version
   BINARY_DATE="2025-01-09"  # Release date
   ```

### Security Considerations:

- Use HTTPS URLs only
- Verify checksums for all downloads
- Store binaries in a secure, access-controlled location
- Consider using signed releases if available

### Current Status:

- ✅ Download script is ready to use
- ✅ Makefile targets are configured
- ✅ Binary archive is present and valid
- ⚠️ URLs and checksums need to be updated for production use

### Next Steps:

1. Update `download-config.env` with real URLs
2. Test download with `./download-binaries.sh --dry-run`
3. Verify checksums with `./download-binaries.sh --verify`
4. Document the update process for your team
