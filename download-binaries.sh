#!/usr/bin/env bash

# Download script for trading system binaries
# This script downloads the necessary binaries for the trading system

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOADS_DIR="${SCRIPT_DIR}/downloads"
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
    -g, --github    Use GitHub CLI for download (requires --repo and optionally --tag)
    --repo REPO     GitHub repository in format owner/repo
    --tag TAG       Release tag (default: latest)
    --asset ASSET   Asset name pattern (default: trading-x86_64-linux.tar.gz)
    -s, --ssh       Use SSH for download (requires --ssh-host, --ssh-user, --ssh-path)
    --ssh-host HOST SSH hostname or IP address
    --ssh-user USER SSH username
    --ssh-path PATH Remote path to the binary file
    --ssh-key PATH  SSH private key file (optional, uses ssh-agent if not specified)
    -v, --verify    Verify checksums after download
    --dry-run       Show what would be done without actually doing it

Examples:
    $0                              # Download with default settings
    $0 --force                      # Force re-download
    $0 --url https://example.com/trading-binaries.tar.gz
    $0 --verify                     # Download and verify checksums
    $0 --github --repo myorg/trading-binaries
    $0 --github --repo myorg/trading-binaries --tag v1.2.3
    $0 --github --repo myorg/trading-binaries --asset "*linux*.tar.gz"
    $0 --ssh --ssh-host example.com --ssh-user deploy --ssh-path /opt/binaries/trading-x86_64-linux.tar.gz
    $0 --ssh --ssh-host 192.168.1.100 --ssh-user admin --ssh-path /home/admin/trading.tar.gz --ssh-key ~/.ssh/deploy_key

EOF
}

# Default configuration
FORCE_DOWNLOAD=false
VERIFY_CHECKSUMS=false
DRY_RUN=false
DOWNLOAD_URL=""
USE_SSH=false
USE_GITHUB=false
GITHUB_REPO=""
GITHUB_TAG="latest"
GITHUB_ASSET="trading-x86_64-linux.tar.gz"
SSH_HOST=""
SSH_USER=""
SSH_PATH=""
SSH_KEY=""

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
        -g|--github)
            USE_GITHUB=true
            shift
            ;;
        --repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        --tag)
            GITHUB_TAG="$2"
            shift 2
            ;;
        --asset)
            GITHUB_ASSET="$2"
            shift 2
            ;;
        -s|--ssh)
            USE_SSH=true
            shift
            ;;
        --ssh-host)
            SSH_HOST="$2"
            shift 2
            ;;
        --ssh-user)
            SSH_USER="$2"
            shift 2
            ;;
        --ssh-path)
            SSH_PATH="$2"
            shift 2
            ;;
        --ssh-key)
            SSH_KEY="$2"
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
if [[ -z "$DOWNLOAD_URL" && "$USE_SSH" != "true" && "$USE_GITHUB" != "true" ]]; then
    DOWNLOAD_URL="$DEFAULT_DOWNLOAD_URL"
fi

# Validate GitHub parameters
if [[ "$USE_GITHUB" == "true" ]]; then
    if [[ -z "$GITHUB_REPO" ]]; then
        log_error "GitHub download requires --repo parameter (format: owner/repo)"
        exit 1
    fi
    # Validate repo format
    if [[ ! "$GITHUB_REPO" =~ ^[^/]+/[^/]+$ ]]; then
        log_error "Invalid repository format. Use: owner/repo"
        exit 1
    fi
fi

# Validate SSH parameters
if [[ "$USE_SSH" == "true" ]]; then
    if [[ -z "$SSH_HOST" || -z "$SSH_USER" || -z "$SSH_PATH" ]]; then
        log_error "SSH download requires --ssh-host, --ssh-user, and --ssh-path parameters"
        exit 1
    fi
fi

# Ensure only one download method is selected
download_methods=0
[[ "$USE_SSH" == "true" ]] && ((download_methods++))
[[ "$USE_GITHUB" == "true" ]] && ((download_methods++))
[[ -n "$DOWNLOAD_URL" ]] && ((download_methods++))

if [[ $download_methods -gt 1 ]]; then
    log_error "Please specify only one download method: --url, --github, or --ssh"
    exit 1
fi

# Function to check if required tools are available
check_dependencies() {
    local missing_deps=()
    
    if [[ "$USE_SSH" == "true" ]]; then
        for dep in scp ssh sha256sum tar; do
            if ! command -v "$dep" &> /dev/null; then
                missing_deps+=("$dep")
            fi
        done
    elif [[ "$USE_GITHUB" == "true" ]]; then
        for dep in gh sha256sum tar; do
            if ! command -v "$dep" &> /dev/null; then
                missing_deps+=("$dep")
            fi
        done
        
        # Check if gh is authenticated
        if command -v gh &> /dev/null; then
            if ! gh auth status &> /dev/null; then
                log_error "GitHub CLI is not authenticated. Run 'gh auth login' first."
                exit 1
            fi
        fi
    else
        for dep in curl wget sha256sum tar; do
            if ! command -v "$dep" &> /dev/null; then
                missing_deps+=("$dep")
            fi
        done
    fi
    
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
    if [[ "$USE_SSH" == "true" ]]; then
        download_via_ssh
    elif [[ "$USE_GITHUB" == "true" ]]; then
        download_via_github
    else
        download_via_http
    fi
}

# Function to download via GitHub CLI
download_via_github() {
    log_info "Downloading via GitHub CLI from: ${GITHUB_REPO}"
    log_info "Release tag: ${GITHUB_TAG}"
    log_info "Asset pattern: ${GITHUB_ASSET}"
    log_info "Saving to: $BINARY_PATH"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would download binary file via GitHub CLI"
        return 0
    fi
    
    # First, let's check if the release exists
    log_info "Checking release information..."
    if [[ "$GITHUB_TAG" == "latest" ]]; then
        if ! gh release view --repo "$GITHUB_REPO" latest &> /dev/null; then
            log_error "No releases found in repository $GITHUB_REPO"
            return 1
        fi
    else
        if ! gh release view --repo "$GITHUB_REPO" "$GITHUB_TAG" &> /dev/null; then
            log_error "Release tag '$GITHUB_TAG' not found in repository $GITHUB_REPO"
            return 1
        fi
    fi
    
    # List available assets to help with debugging
    log_info "Available assets for this release:"
    if [[ "$GITHUB_TAG" == "latest" ]]; then
        gh release view --repo "$GITHUB_REPO" latest --json assets --jq '.assets[].name' | sed 's/^/  /'
    else
        gh release view --repo "$GITHUB_REPO" "$GITHUB_TAG" --json assets --jq '.assets[].name' | sed 's/^/  /'
    fi
    
    # Download the asset
    log_info "Downloading asset..."
    local download_dir
    download_dir="$(dirname "$BINARY_PATH")"
    
    if [[ "$GITHUB_TAG" == "latest" ]]; then
        if gh release download --repo "$GITHUB_REPO" --pattern "$GITHUB_ASSET" --dir "$download_dir" latest; then
            # Check if the downloaded file has the expected name
            if [[ ! -f "$BINARY_PATH" ]]; then
                # Find the downloaded file and rename it if necessary
                local downloaded_file
                downloaded_file=$(find "$download_dir" -name "$GITHUB_ASSET" -o -name "${GITHUB_ASSET//\*/\*}" | head -1)
                if [[ -n "$downloaded_file" && -f "$downloaded_file" ]]; then
                    if [[ "$downloaded_file" != "$BINARY_PATH" ]]; then
                        log_info "Renaming downloaded file to expected name..."
                        mv "$downloaded_file" "$BINARY_PATH"
                    fi
                else
                    log_error "Downloaded asset not found. Check the asset pattern."
                    return 1
                fi
            fi
            log_success "GitHub download completed successfully"
        else
            log_error "GitHub download failed"
            return 1
        fi
    else
        if gh release download --repo "$GITHUB_REPO" --pattern "$GITHUB_ASSET" --dir "$download_dir" "$GITHUB_TAG"; then
            # Check if the downloaded file has the expected name
            if [[ ! -f "$BINARY_PATH" ]]; then
                # Find the downloaded file and rename it if necessary
                local downloaded_file
                downloaded_file=$(find "$download_dir" -name "$GITHUB_ASSET" -o -name "${GITHUB_ASSET//\*/\*}" | head -1)
                if [[ -n "$downloaded_file" && -f "$downloaded_file" ]]; then
                    if [[ "$downloaded_file" != "$BINARY_PATH" ]]; then
                        log_info "Renaming downloaded file to expected name..."
                        mv "$downloaded_file" "$BINARY_PATH"
                    fi
                else
                    log_error "Downloaded asset not found. Check the asset pattern."
                    return 1
                fi
            fi
            log_success "GitHub download completed successfully"
        else
            log_error "GitHub download failed"
            return 1
        fi
    fi
}

# Function to download via SSH
download_via_ssh() {
    log_info "Downloading via SSH from: ${SSH_USER}@${SSH_HOST}:${SSH_PATH}"
    log_info "Saving to: $BINARY_PATH"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would download binary file via SSH"
        return 0
    fi
    
    # Build SSH command
    local ssh_opts=()
    if [[ -n "$SSH_KEY" ]]; then
        if [[ ! -f "$SSH_KEY" ]]; then
            log_error "SSH key file not found: $SSH_KEY"
            return 1
        fi
        ssh_opts+=("-i" "$SSH_KEY")
    fi
    
    # Add common SSH options
    ssh_opts+=("-o" "StrictHostKeyChecking=ask")
    ssh_opts+=("-o" "ConnectTimeout=30")
    
    log_info "Using scp for download..."
    if scp "${ssh_opts[@]}" "${SSH_USER}@${SSH_HOST}:${SSH_PATH}" "$BINARY_PATH"; then
        log_success "SSH download completed successfully"
    else
        log_error "SSH download failed"
        return 1
    fi
}

# Function to download via HTTP/HTTPS
download_via_http() {
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
    if [[ "$USE_SSH" == "true" ]]; then
        echo "  Download method: SSH"
        echo "  SSH host: $SSH_HOST"
        echo "  SSH user: $SSH_USER"
        echo "  Remote path: $SSH_PATH"
        if [[ -n "$SSH_KEY" ]]; then
            echo "  SSH key: $SSH_KEY"
        else
            echo "  SSH key: Using ssh-agent or default"
        fi
    elif [[ "$USE_GITHUB" == "true" ]]; then
        echo "  Download method: GitHub CLI"
        echo "  Repository: $GITHUB_REPO"
        echo "  Release tag: $GITHUB_TAG"
        echo "  Asset pattern: $GITHUB_ASSET"
    else
        echo "  Download method: HTTP/HTTPS"
        echo "  Download URL: $DOWNLOAD_URL"
    fi
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
