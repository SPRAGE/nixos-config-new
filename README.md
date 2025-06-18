# NixOS Configuration Fork

This repository is a personal fork of [spector700/nixos-config](https://github.com/spector700/nixos-config). It contains my own tweaks and machine profiles while keeping most of the original structure.

## Components

- **Window Manager** — [Hyprland](https://github.com/hyprwm/Hyprland)
- **Shell** — [Zsh](https://www.zsh.org) with [starship](https://github.com/starship/starship)
- **Terminal** — [Kitty](https://sw.kovidgoyal.net/kitty/)
- **Panel** — [Hyprpanel](https://hyprpanel.com/)
- **File Manager** — [yazi](https://yazi-rs.github.io)
- **Neovim** — [Akari](https://github.com/spector700/Akari)

## Installation

1. Download the latest minimal ISO:
   ```bash
   wget -O nixos.iso https://channels.nixos.org/nixos-23.05/latest-nixos-minimal-x86_64-linux.iso
   ```
2. Boot the installer and partition the drive with Disko:
   ```bash
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake github:<your-user>/nixos-config-new#shaundesk
   ```
3. Install the system using this flake:
   ```bash
   sudo nixos-install --flake github:<your-user>/nixos-config-new#shaundesk --no-write-lock-file
   ```
4. Reboot.

## Credits

Inspired by and based on the work of:

- [fufexan/dotfiles](https://github.com/fufexan/dotfiles)
- [linuxmobile/kaku](https://github.com/linuxmobile/kaku)
- [Gerg-L/nixos](https://github.com/Gerg-L/nixos)
- [Misterio77/nix-config](https://github.com/Misterio77/nix-config)
