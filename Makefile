# Makefile for NixOS Trading System Configuration
.PHONY: help download-binaries build-dataserver build-all clean check-binaries

# Default target
help: ## Show this help message
	@echo "NixOS Trading System Configuration"
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

download-binaries: ## Download trading system binaries
	@echo "📥 Downloading trading binaries..."
	./download-binaries.sh

download-force: ## Force re-download of binaries
	@echo "📥 Force downloading trading binaries..."
	./download-binaries.sh --force

download-verify: ## Download and verify binaries with checksums
	@echo "📥 Downloading and verifying trading binaries..."
	./download-binaries.sh --verify

check-binaries: ## Check if binaries are present and valid
	@echo "🔍 Checking trading binaries..."
	@if [ -f "downlaods/trading-x86_64-linux.tar.gz" ]; then \
		echo "✅ Binary archive found"; \
		echo "📊 File size: $$(du -h downlaods/trading-x86_64-linux.tar.gz | cut -f1)"; \
		echo "🗂️  Archive contents:"; \
		tar -tzf downlaods/trading-x86_64-linux.tar.gz | grep "bin/" | head -10; \
	else \
		echo "❌ Binary archive not found. Run 'make download-binaries' first."; \
		exit 1; \
	fi

build-dataserver: ## Build the dataserver NixOS configuration
	@echo "🏗️  Building dataserver configuration..."
	nix build .#nixosConfigurations.dataserver.config.system.build.toplevel

build-packages: ## Build just the trading packages
	@echo "🏗️  Building trading packages..."
	nix build .#packages.x86_64-linux.trading-binaries

build-all: ## Build all configurations
	@echo "🏗️  Building all configurations..."
	nix build .#nixosConfigurations.dataserver.config.system.build.toplevel
	nix build .#nixosConfigurations.laptop.config.system.build.toplevel
	nix build .#nixosConfigurations.shaundesk.config.system.build.toplevel
	nix build .#nixosConfigurations.shaunoffice.config.system.build.toplevel

deploy-dataserver: check-binaries build-dataserver ## Deploy to dataserver (requires sudo)
	@echo "🚀 Deploying to dataserver..."
	@echo "⚠️  This will require sudo access"
	sudo nixos-rebuild switch --flake .#dataserver

check-syntax: ## Check Nix syntax for all files
	@echo "🔍 Checking Nix syntax..."
	@find . -name "*.nix" -exec nix-instantiate --parse {} \; > /dev/null
	@echo "✅ All Nix files have valid syntax"

format: ## Format Nix files with nixpkgs-fmt
	@echo "🎨 Formatting Nix files..."
	@if command -v nixpkgs-fmt > /dev/null; then \
		find . -name "*.nix" -exec nixpkgs-fmt {} \; ; \
		echo "✅ Formatting complete"; \
	else \
		echo "❌ nixpkgs-fmt not found. Install it with: nix-env -iA nixpkgs.nixpkgs-fmt"; \
	fi

clean: ## Clean build artifacts and caches
	@echo "🧹 Cleaning build artifacts..."
	rm -rf result*
	@echo "✅ Clean complete"

clean-downloads: ## Remove downloaded binaries (use with caution)
	@echo "🗑️  Removing downloaded binaries..."
	@read -p "Are you sure you want to delete downloaded binaries? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -f downlaods/trading-x86_64-linux.tar.gz; \
		echo "✅ Downloaded binaries removed"; \
	else \
		echo "❌ Cancelled"; \
	fi

update-flake: ## Update flake.lock
	@echo "🔄 Updating flake.lock..."
	nix flake update
	@echo "✅ Flake updated"

dev-shell: ## Enter development shell
	@echo "🐚 Entering development shell..."
	nix develop

# Development targets
dev-check: check-syntax check-binaries ## Run all development checks

dev-build: download-binaries build-dataserver ## Download binaries and build dataserver

# CI/CD targets
ci-prepare: download-binaries ## Prepare for CI/CD
	@echo "🔧 Preparing for CI/CD..."

ci-test: check-syntax build-all ## Run CI/CD tests

# Show current status
status: ## Show current system status
	@echo "📊 NixOS Trading System Status"
	@echo "================================"
	@echo "Flake inputs:"
	@nix flake show --quiet 2>/dev/null | head -10 || echo "Could not show flake info"
	@echo ""
	@echo "Binary status:"
	@make check-binaries 2>/dev/null || echo "❌ Binaries not available"
	@echo ""
	@echo "Git status:"
	@git status --porcelain | head -5 || echo "Not a git repository"
