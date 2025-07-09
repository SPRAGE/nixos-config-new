#!/usr/bin/env bash

# Download script for trading system binaries
# This script downloads the necessary binaries for the trading system

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOADS_DIR="${SCRIPT_DIR}/downlaods"
BINARY_FILE="trading-x86_64-linux.tar.gz"
BINARY_PATH="${DOWNLOADS_DIR}/${BINARY_FILE}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Download trading system binaries for NixOS configuration.

Options:
    -h, --help      Show this help message
    -f, --force     Force re-download even if file exists
    -u, --url URL   Specify custom download URL
    -v, --verify    Verify checksums after download
    --dry-run       Show what would be done without actually doing it

Examples:
    $0                              # Download with default settings
    $0 --force                      # Force re-download
    $0 --url https://example.com/trading-binaries.tar.gz
    $0 --verify                     # Download and verify checksums

EOF
}

# Default configuration
FORCE_DOWNLOAD=false
VERIFY_CHECKSUMS=false
DRY_RUN=false
DOWNLOAD_URL=""

# You should replace this with the actual download URL
DEFAULT_DOWNLOAD_URL="https://github.com/your-org/trading-binaries/releases/latest/download/trading-x86_64-linux.tar.gz"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -f|--force)
            FORCE_DOWNLOAD=true
            shift
            ;;
        -u|--url)
            DOWNLOAD_URL="$2"
            shift 2
            ;;
        -v|--verify)
            VERIFY_CHECKSUMS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Use default URL if none provided
if [[ -z "$DOWNLOAD_URL" ]]; then
    DOWNLOAD_URL="$DEFAULT_DOWNLOAD_URL"
fi

# Function to check if required tools are available
check_dependencies() {
    local missing_deps=()
    
    for dep in curl wget sha256sum tar; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Function to create downloads directory
ensure_downloads_dir() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would create directory: $DOWNLOADS_DIR"
        return
    fi
    
    if [[ ! -d "$DOWNLOADS_DIR" ]]; then
        log_info "Creating downloads directory: $DOWNLOADS_DIR"
        mkdir -p "$DOWNLOADS_DIR"
    fi
}

# Function to check if file exists and whether to download
should_download() {
    if [[ ! -f "$BINARY_PATH" ]]; then
        log_info "Binary file not found: $BINARY_PATH"
        return 0  # Should download
    fi
    
    if [[ "$FORCE_DOWNLOAD" == "true" ]]; then
        log_info "Force download requested"
        return 0  # Should download
    fi
    
    log_info "Binary file already exists: $BINARY_PATH"
    log_info "Use --force to re-download"
    return 1  # Should not download
}

# Function to download the binary
download_binary() {
    log_info "Downloading from: $DOWNLOAD_URL"
    log_info "Saving to: $BINARY_PATH"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would download binary file"
        return 0
    fi
    
    # Try curl first, then wget
    if command -v curl &> /dev/null; then
        log_info "Using curl for download..."
        if curl -L -o "$BINARY_PATH" "$DOWNLOAD_URL"; then
            log_success "Download completed successfully"
        else
            log_error "Download failed with curl"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        log_info "Using wget for download..."
        if wget -O "$BINARY_PATH" "$DOWNLOAD_URL"; then
            log_success "Download completed successfully"
        else
            log_error "Download failed with wget"
            return 1
        fi
    else
        log_error "Neither curl nor wget is available"
        return 1
    fi
}

# Function to verify the downloaded file
verify_binary() {
    if [[ "$VERIFY_CHECKSUMS" != "true" ]]; then
        return 0
    fi
    
    log_info "Verifying downloaded binary..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would verify binary checksums"
        return 0
    fi
    
    # Check if it's a valid tar.gz file
    if ! tar -tzf "$BINARY_PATH" &> /dev/null; then
        log_error "Downloaded file is not a valid tar.gz archive"
        return 1
    fi
    
    # Calculate and display checksums
    log_info "File checksums:"
    sha256sum "$BINARY_PATH"
    
    log_success "Binary verification completed"
}

# Function to show download information
show_download_info() {
    log_info "Trading Binary Download Information:"
    echo "  Download URL: $DOWNLOAD_URL"
    echo "  Target file:  $BINARY_PATH"
    echo "  Force download: $FORCE_DOWNLOAD"
    echo "  Verify checksums: $VERIFY_CHECKSUMS"
    echo "  Dry run: $DRY_RUN"
    echo
}

# Main execution
main() {
    log_info "Starting trading binary download process..."
    
    show_download_info
    
    # Check dependencies
    check_dependencies
    
    # Ensure downloads directory exists
    ensure_downloads_dir
    
    # Check if we should download
    if should_download; then
        # Download the binary
        if download_binary; then
            # Verify if requested
            verify_binary
            log_success "Trading binary download process completed successfully!"
        else
            log_error "Download process failed"
            exit 1
        fi
    else
        log_info "No download needed"
    fi
    
    # Show final status
    if [[ -f "$BINARY_PATH" && "$DRY_RUN" != "true" ]]; then
        local file_size=$(du -h "$BINARY_PATH" | cut -f1)
        log_success "Binary file ready: $BINARY_PATH ($file_size)"
        
        # List contents of the archive
        log_info "Archive contents:"
        tar -tzf "$BINARY_PATH" | head -20
        if [[ $(tar -tzf "$BINARY_PATH" | wc -l) -gt 20 ]]; then
            echo "  ... and $(( $(tar -tzf "$BINARY_PATH" | wc -l) - 20 )) more files"
        fi
    fi
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 130' INT TERM

# Run main function
main "$@"
