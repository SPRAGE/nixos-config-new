<p align="center"><img src="https://i.imgur.com/X5zKxvp.png" width=300px></p>

<p align="center">
<a href="https://nixos.org/"><img src="https://img.shields.io/badge/NixOS-unstable-informational.svg?style=flat&logo=nixos&logoColor=CAD3F5&colorA=24273A&colorB=8AADF4"></a>

<p align="center"><img src="https://i.imgur.com/NbxQ8MY.png" width=600px></p>

---

- **Window Manager** • [Hyprland](https://github.com/hyprwm/Hyprland)🎨
- **Shell** • [Zsh](https://www.zsh.org) 🐚 with
  [starship](https://github.com/starship/starship)
- **Terminal** • [Kitty](https://sw.kovidgoyal.net/kitty/) 💻
- **Panel** • [Hyprpanel](https://hyprpanel.com/)🍧
- **File Manager** • [yazi](https://yazi-rs.github.io)🔖
- **Neovim** • [Akari](https://github.com/spector700/Akari)

---

![desktop-pic-1](.github/assets/desktop-pic-1.png)
![desktop-pic-2](.github/assets/desktop-pic-2.png)
![desktop-pic-3](.github/assets/desktop-pic-3.png)
<p align="center">Screenshots Circa: 2024-4-9</p>

---

## <samp>INSTALLATION (NixOS)</samp>

- Download ISO.
```bash
wget -O https://channels.nixos.org/nixos-23.05/latest-nixos-minimal-x86_64-linux.iso
```

- Boot Into the Installer.

- Format Partitions with Disko:

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake github:spector700/nixos-config#alfhiem
```

- Install Dotfiles Using Flake

```bash
sudo nixos-install --flake github:spector700/nixos-config#alfhiem --no-write-lock-file
```

- Reboot

---

## 🚀 Quick Start

### Prerequisites

1. **Download Trading Binaries** (required for dataserver):
   ```bash
   # Download required trading system binaries
   ./download-binaries.sh
   
   # Or use make
   make download-binaries
   ```
   
   See [BINARY_MANAGEMENT.md](BINARY_MANAGEMENT.md) for detailed binary management instructions.

2. **Build Configuration**:
   ```bash
   # Build specific host
   nix build .#nixosConfigurations.dataserver.config.system.build.toplevel
   
   # Or use make for convenience
   make build-dataserver
   ```

### Available Hosts

- **dataserver** - Trading system server with Kafka, ClickHouse, Valkey, and trading services
- **laptop** - Mobile workstation setup
- **shaundesk** - Desktop workstation
- **shaunoffice** - Office workstation

### Development

```bash
# Check everything is working
make dev-check

# Enter development shell
make dev-shell

# Show available commands
make help
```

---

## 📊 Trading System

This configuration includes a complete trading system setup on the `dataserver` host:

### Services
- **Authentication Server** - Secure API authentication
- **Analysis Server** - Financial data analysis
- **Ingestion Server** - Data ingestion pipeline
- **WebSocket Services** - Real-time data streaming
- **Financial Data Consumer** - Kafka consumer for market data

### Infrastructure
- **Kafka** - Message streaming (KRaft mode, no Zookeeper)
- **ClickHouse** - Analytics database
- **Valkey** - Redis-compatible in-memory store
- **Docker** - Container runtime

### Frontend
- **Index Frontend** - GUI application for data visualization

---

## 🛠️ Installation

- Clone the repository

```bash
git clone https://github.com/spector700/nixos-config
cd nixos-config
```

- Switch to the desired configuration

```bash
# For example, to switch to the dataserver configuration
git switch dataserver
```

- Build and switch to the new configuration

```bash
sudo nixos-rebuild switch --flake .#dataserver
```

- Reboot into the new system

```bash
sudo reboot
```

---

## 💾 Credits & Inspiration

This configuration is inspired by and builds upon the amazing work of:

- [fufexan/dotfiles](https://github.com/fufexan/dotfiles)
- [linuxmobile/kaku](https://github.com/linuxmobile/kaku)
- [Gerg-L/nixos](https://github.com/Gerg-L/nixos)
- [Misterio77/nix-config](https://github.com/Misterio77/nix-config)

Special thanks to these projects for their contributions to the NixOS and Linux ecosystem.
