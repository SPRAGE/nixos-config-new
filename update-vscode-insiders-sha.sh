#!/usr/bin/env bash

# Script to update VS Code Insiders SHA256 hash in the Nix configuration
# This script fetches the latest VS Code Insiders build and updates the SHA256 hash

set -euo pipefail

# Configuration
VSCODE_CONFIG_FILE="modules/home/shaun/editors/vscode.nix"
VSCODE_INSIDERS_URL="https://code.visualstudio.com/sha/download?build=insider&os=linux-x64"
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Updating VS Code Insiders SHA256 hash...${NC}"

# Check if the config file exists
if [[ ! -f "$VSCODE_CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Configuration file $VSCODE_CONFIG_FILE not found!${NC}"
    echo "Make sure you're running this script from the nixos-config-new directory."
    exit 1
fi

# Function to cleanup temp directory
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Downloading VS Code Insiders to calculate SHA256..."

# Download the VS Code Insiders tarball to temp directory
TARBALL_PATH="$TEMP_DIR/vscode-insiders.tar.gz"
if ! curl -L -o "$TARBALL_PATH" "$VSCODE_INSIDERS_URL"; then
    echo -e "${RED}Error: Failed to download VS Code Insiders!${NC}"
    exit 1
fi

echo "Calculating SHA256 hash..."

# Calculate SHA256 hash
NEW_SHA256=$(sha256sum "$TARBALL_PATH" | cut -d' ' -f1)

echo -e "${GREEN}New SHA256 hash: $NEW_SHA256${NC}"

# Read the current config file
if ! grep -q "sha256.*=" "$VSCODE_CONFIG_FILE"; then
    echo -e "${RED}Error: Could not find sha256 field in $VSCODE_CONFIG_FILE${NC}"
    exit 1
fi

# Create backup
cp "$VSCODE_CONFIG_FILE" "$VSCODE_CONFIG_FILE.backup"
echo "Created backup: $VSCODE_CONFIG_FILE.backup"

# Update the SHA256 in the config file
# This handles both placeholder and actual hash formats
if sed -i "s/sha256 = \"[^\"]*\"/sha256 = \"$NEW_SHA256\"/" "$VSCODE_CONFIG_FILE"; then
    echo -e "${GREEN}Successfully updated SHA256 hash in $VSCODE_CONFIG_FILE${NC}"
    
    # Show the diff
    echo -e "\n${YELLOW}Changes made:${NC}"
    if command -v diff >/dev/null 2>&1; then
        diff -u "$VSCODE_CONFIG_FILE.backup" "$VSCODE_CONFIG_FILE" || true
    fi
    
    echo -e "\n${GREEN}✓ VS Code Insiders SHA256 hash updated successfully!${NC}"
    echo -e "${YELLOW}You can now rebuild your system with: nixos-rebuild switch${NC}"
    echo -e "${YELLOW}Or for home-manager: home-manager switch${NC}"
else
    echo -e "${RED}Error: Failed to update SHA256 hash!${NC}"
    # Restore backup
    mv "$VSCODE_CONFIG_FILE.backup" "$VSCODE_CONFIG_FILE"
    exit 1
fi
