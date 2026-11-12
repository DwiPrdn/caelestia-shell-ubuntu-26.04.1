# Caelestia Shell on Ubuntu 26.04.1 LTS

[![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04.1_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Hyprland](https://img.shields.io/badge/Hyprland-0.53.3-58E1FF?style=for-the-badge&logo=wayland&logoColor=black)](https://hyprland.org/)
[![Ghostty](https://img.shields.io/badge/Ghostty-Terminal-FFA500?style=for-the-badge)](https://ghostty.org/)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge)](LICENSE)

An end-to-end, battle-tested installation and configuration setup for running **[Caelestia Shell](https://github.com/caelestia-dots/shell)** (a modern Quickshell desktop shell designed for Hyprland) on **Ubuntu 26.04.1 LTS (Resolute Raccoon)**.

Caelestia Shell targets Arch Linux and AUR dependencies by default. This repository provides the complete pipeline, build patches, hardware integration fixes, login manager themes, and preconfigured shell/terminal dots to make it run flawlessly on Ubuntu 26.04.1 LTS.

---

## Table of Contents

- [Quick Start](#quick-start)
- [What Has Changed & Improved](#what-has-changed--improved)
  - [1. Hyprland & UWSM Native Integration](#1-hyprland--uwsm-native-integration)
  - [2. Qt 6.10 Compatibility Patch](#2-qt-610-compatibility-patch)
  - [3. M3Shapes & libcava Build Pipelines](#3-m3shapes--libcava-build-pipelines)
  - [4. Modern Ghostty + Zsh + Starship Terminal Stack](#4-modern-ghostty--zsh--starship-terminal-stack)
  - [5. SDDM Pixie Theme & Display Setup Fixes](#5-sddm-pixie-theme--display-setup-fixes)
  - [6. Clean UWSM Logout (No Hangs)](#6-clean-uwsm-logout-no-hangs)
  - [7. Hardware Brightness Without Sudo](#7-hardware-brightness-without-sudo)
  - [8. Screen Recording with AAC Audio (Telegram / FAgram Fix)](#8-screen-recording-with-aac-audio-telegram--fagram-fix)
  - [9. Systemd User Supervision & Waybar Masking](#9-systemd-user-supervision--waybar-masking)
- [Repository Structure](#repository-structure)
- [Troubleshooting & Common Problems](#troubleshooting--common-problems)
- [Credits & Acknowledgments](#credits--acknowledgments)
- [License](#license)

---

## Quick Start

### Automated Installation on Ubuntu 26.04.1 LTS

```bash
git clone https://github.com/dwiprdn/caelestia-shell-ubuntu.git
cd caelestia-shell-ubuntu
chmod +x install-26.04.sh
./install-26.04.sh
```

Once the installation script finishes, log out and select **Hyprland (uwsm-managed)** or **Hyprland** at the SDDM login screen.

> [!NOTE]
> For a complete step-by-step breakdown of every build step and dependency on Ubuntu 26.04.1 LTS, see the in-depth manual guide in **[docs/ubuntu-26.04.md](docs/ubuntu-26.04.md)**.

---

## What Has Changed & Improved

This repository expands upon the initial Ubuntu 26.04 port with full everyday desktop usability fixes:

### 1. Hyprland & UWSM Native Integration
- Uses Ubuntu 26.04.1's native `hyprland` package (0.53.3) and ecosystem (`hypridle`, `hyprlock`, `hyprpaper`, `hyprpicker`, `hyprpolkitagent`).
- Integrated with `uwsm` (Universal Wayland Session Manager) to provide proper systemd unit containment and clean lifecycle management.
- Fixed Hyprland 0.53 syntax deprecations (removed legacy `windowrule =` and `gestures {}` blocks).
- Natural workspace scrolling with `$mod + mouse_scroll` and single-key launcher on `SUPER_L`.

### 2. Qt 6.10 Compatibility Patch
- **The Problem:** Ubuntu 26.04.1 packages **Qt 6.10.2**, whereas current Caelestia Shell requires **Qt 6.11**. Without intervention, build and runtime fail due to missing QML components and strict type changes.
- **The Solution:** Included [`patches/qt6.10-compat.patch`](patches/qt6.10-compat.patch) which fixes:
  1. `DoubleSpinBox`: Replaces the Qt 6.11-only type with a custom `StyledSpinBox` component.
  2. `ListModel.setProperty`: Explicitly casts string arguments to numbers for integer properties.
  3. Lockscreen `InputField.qml`: Renames delegate item id from `char` to `charItem` to prevent scope collision with Qt Quick's internal type identifier.

### 3. M3Shapes & libcava Build Pipelines
- Automatically builds and installs `soramanew/m3shapes` into `/usr/lib/qt6/qml/M3Shapes/` for Material Design 3 shape rendering.
- Builds `libcava` from LukashonakV's fork and exports proper pkg-config paths (`/usr/local/lib/x86_64-linux-gnu/pkgconfig`) for Caelestia's audio visualizer.

### 4. Modern Ghostty + Zsh + Starship Terminal Stack
- Default terminal set to **[Ghostty](https://ghostty.org/)** with:
  - Catppuccin Mocha colors and semi-transparent background blur.
  - Native tabs (`Ctrl+T`, `Ctrl+W`, `Alt+1..5`) and split panes (`Ctrl+Shift+D`, `Ctrl+Shift+-`).
  - JetBrainsMono Nerd Font.
- Shell configured with **Zsh**, **Oh-My-Zsh**, syntax highlighting, autosuggestions, and modern replacements: `lsd`, `bat`, `fzf`, and `zoxide`.
- Fast, rich **Starship** prompt preconfigured in [`config/26.04/starship.toml`](config/26.04/starship.toml).

### 5. SDDM Pixie Theme & Display Setup Fixes
- Preconfigures the minimal Material Design 3 **Pixie SDDM theme** ([xCaptaiN09/pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm)).
- Bundles custom background artwork at [`config/26.04/sddm/background.jpg`](config/26.04/sddm/background.jpg).
- Disables the intrusive virtual keyboard popup by overriding `InputMethod=` in [`config/26.04/sddm/99-theme.conf`](config/26.04/sddm/99-theme.conf).
- Preserves `/usr/libexec/budgie-sddm-display-setup` under `[X11]` to prevent display flickering, black-screen cycles, and input-driver hangs after session logout on Ubuntu 26.04.1.

### 6. Clean UWSM Logout (No Hangs)
- **The Problem:** The stock Caelestia configuration invokes `loginctl terminate-user ""`. On UWSM-managed Hyprland sessions, passing an empty username causes loginctl to fail or hang the compositor indefinitely.
- **The Solution:** Rewired Caelestia's logout command in [`config/26.04/shell.json`](config/26.04/shell.json) to `["uwsm", "stop"]`, cleanly tearing down the Wayland session and returning to SDDM instantaneously.

### 7. Hardware Brightness Without Sudo
- Configures `/usr/bin/brightnessctl` with setuid permissions (`chmod u+s`).
- Deploys udev rules in `/etc/udev/rules.d/90-backlight.rules` granting the `video` group write access to `/sys/class/backlight/*/brightness`.
- The brightness slider in the Caelestia Control Center operates smoothly without root prompts.

### 8. Screen Recording with AAC Audio (Telegram / FAgram Fix)
- Compiles `gpu-screen-recorder` with hardware acceleration enabled.
- Adds [`config/26.04/cli.json`](config/26.04/cli.json) setting `extraArgs: ["-ac", "aac"]`.
- Prevents audio silence when sending screen recordings through Telegram, FAgram, Discord, or playing them in standard web players (which cannot decode Opus in MP4 containers).

### 9. Systemd User Supervision & Waybar Masking
- Includes [`config/26.04/systemd/caelestia-shell.service`](config/26.04/systemd/caelestia-shell.service) to supervise Quickshell: automatically restarts the bar within 2 seconds if a crash occurs.
- Automatically masks `waybar.service` (`systemctl --user mask waybar.service`) to prevent duplicate, conflicting topbars.

---

## Repository Structure

```
caelestia-shell-ubuntu/
├── config/
│   └── 26.04/
│       ├── cli.json                  # Caelestia CLI options (-ac aac for recordings)
│       ├── ghostty/
│       │   └── config                # Ghostty terminal config (Catppuccin Mocha, tabs)
│       ├── hyprland.conf             # Standalone, valid Hyprland 0.53 configuration
│       ├── qt6ct/
│       │   └── qt6ct.conf            # Qt6 appearance config (Papirus-Dark icons)
│       ├── quickshell/
│       │   └── qml_color.json        # Color scheme variables
│       ├── sddm/
│       │   ├── 99-theme.conf         # SDDM override (Pixie theme, no virtual keyboard)
│       │   └── background.jpg        # Custom SDDM background wallpaper
│       ├── shell.json                # Complete tuned Caelestia configuration
│       ├── shell.minimal.json        # Minimal fallback configuration
│       ├── starship.toml             # Catppuccin Mocha Starship prompt
│       ├── systemd/
│       │   └── caelestia-shell.service # User unit supervising Quickshell
│       └── zshrc                     # Zsh configuration with plugins & aliases
├── docs/
│   └── ubuntu-26.04.md               # Detailed manual installation & reference guide
├── patches/
│   └── qt6.10-compat.patch           # Patch enabling Caelestia to build on Qt 6.10.2
├── public/                           # Demonstration GIFs & media
├── install-26.04.sh                  # All-in-one installation script for Ubuntu 26.04.1
├── LICENSE                           # GPL-3.0 License
└── README.md                         # This documentation
```

---

## Troubleshooting & Common Problems

### 1. Blank tray / Status icons or `WARN: Could not load icon ...`
- **Cause:** Qt applications under Hyprland do not inherit GNOME's theme settings. If the icon theme isn't specified in Qt, lookups fall back to `hicolor` and fail.
- **Fix:** Install `papirus-icon-theme` and configure `~/.config/qt6ct/qt6ct.conf`:
  ```ini
  [Appearance]
  icon_theme=Papirus-Dark
  style=Fusion
  ```
  Ensure `QT_QPA_PLATFORMTHEME=qt6ct` is set in your `hyprland.conf`.

### 2. Bar shows literal words like `terminal`, `web`, `calendar_month` instead of icons
- **Cause:** Missing **Material Symbols Rounded** font. Caelestia renders icons via font ligatures; if the font is missing, fontconfig falls back to a generic sans font and prints the ligature name literally.
- **Fix:** Download and install the variable TTF to `~/.local/share/fonts/`:
  ```bash
  wget -O ~/.local/share/fonts/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf \
    https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf
  fc-cache -fv
  fc-match "Material Symbols Rounded"   # Must return MaterialSymbolsRounded, NOT NotoSans
  ```

### 3. SDDM shows a virtual keyboard covering the screen
- **Cause:** Ubuntu Budgie / Ubuntu 26.04.1 defaults configure `InputMethod=qtvirtualkeyboard`.
- **Fix:** Ensure `/etc/sddm.conf.d/99-theme.conf` contains an empty `InputMethod=`:
  ```ini
  [General]
  InputMethod=
  GreeterEnvironment=
  ```

### 4. SDDM screen flickers rapidly (black screen -> cursor -> turn off)
- **Cause:** Disabling or emptying `DisplayCommand` in SDDM configs on Ubuntu 26.04.1 prevents `budgie-sddm-display-setup` from initializing display outputs under X11.
- **Fix:** Keep `DisplayCommand=/usr/libexec/budgie-sddm-display-setup` in `/etc/sddm.conf.d/99-theme.conf`.

### 5. Display hangs or freezes when clicking "Logout" in Caelestia
- **Cause:** Default `loginctl terminate-user ""` does not pass a valid session or user when managed by UWSM.
- **Fix:** Open `~/.config/caelestia/shell.json` and change `session.commands.logout` to `["uwsm", "stop"]`.

### 6. Screen recordings have no sound when sent via Telegram / FAgram
- **Cause:** GPU Screen Recorder records audio in Opus format by default. Telegram/FAgram's internal video player does not support Opus audio tracks in MP4 files.
- **Fix:** Ensure `~/.config/caelestia/cli.json` specifies the AAC audio codec:
  ```json
  {
    "record": {
      "extraArgs": ["-ac", "aac"]
    }
  }
  ```

### 7. Brightness slider in Control Center does nothing
- **Cause:** Normal users do not have write access to `/sys/class/backlight/*/brightness`.
- **Fix:** Grant setuid permissions to `brightnessctl` and install the udev rule:
  ```bash
  sudo chmod u+s /usr/bin/brightnessctl
  echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' | sudo tee /etc/udev/rules.d/90-backlight.rules
  sudo usermod -aG video "$USER"
  ```

### 8. Two topbars visible on screen simultaneously
- **Cause:** Both `waybar` and Caelestia Shell are running.
- **Fix:** Mask Waybar's systemd user service:
  ```bash
  systemctl --user mask waybar.service
  pkill waybar
  ```

### 9. Everything appears oversized on laptop display
- **Cause:** Hyprland's `auto` scale defaults to `2.0` on high-resolution displays (e.g. 14" QHD panels).
- **Fix:** Edit `~/.config/hypr/hyprland.conf` and set scale explicitly to `1` or `1.25`:
  ```ini
  monitor = , preferred, auto, 1
  ```

### 10. `CavaProvider is not a type` during shell startup
- **Cause:** libcava headers or libraries were built but not detected by Quickshell's CMake build.
- **Fix:** Export the library search path before building:
  ```bash
  export PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
  ```

### 11. UWSM session fails immediately at login
- **Cause:** The `hyprland` package ships `hyprland-uwsm.desktop` without declaring a package dependency on `uwsm`.
- **Fix:** Install `uwsm` via apt:
  ```bash
  sudo apt install uwsm
  ```

---

## Credits & Acknowledgments

This project builds upon the hard work of the open-source community:

- **Original Base Guide & Repository:** Forked and expanded from [IshmamDC217/caelestia-shell-ubuntu](https://github.com/IshmamDC217/caelestia-shell-ubuntu) by [@IshmamDC217](https://github.com/IshmamDC217).
- **Caelestia Dots & Caelestia Shell:** Created by [Scout](https://github.com/caelestia-dots) ([caelestia-dots/shell](https://github.com/caelestia-dots/shell)).
- **Hyprland:** Dynamic tiling Wayland compositor by [@vaxry](https://github.com/vaxerski) ([hyprwm/Hyprland](https://hyprland.org/)).
- **Quickshell:** Flexible desktop shell framework by [@outfoxxed](https://github.com/outfoxxed) ([quickshell](https://quickshell.outfoxxed.me/)).
- **Pixie SDDM Theme:** Beautiful Pixel-style SDDM login theme by [@xCaptaiN09](https://github.com/xCaptaiN09) ([pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm)).
- **M3Shapes:** Material Design 3 shape plugin for Qt Quick by [@soramanew](https://github.com/soramanew) ([m3shapes](https://github.com/soramanew/m3shapes)).
- **GPU Screen Recorder:** High-performance screen recorder by [@dec05eba](https://repo.dec05eba.com/gpu-screen-recorder).
- **libcava:** Audio visualizer library fork by [@LukashonakV](https://github.com/LukashonakV) ([cava](https://github.com/LukashonakV/cava)).
- **Ghostty Terminal:** Fast, native GPU terminal emulator by [@mitchellh](https://github.com/mitchellh) and the [Ghostty Team](https://ghostty.org/).
- **Starship Prompt:** Fast cross-shell prompt ([starship.rs](https://starship.rs/)).
- **Catppuccin Theme:** Soothing pastel palette by the [Catppuccin Team](https://github.com/catppuccin).
- **Bibata Cursor:** Material-based cursor theme by [@ful1e5](https://github.com/ful1e5) ([Bibata_Cursor](https://github.com/ful1e5/Bibata_Cursor)).
- **Papirus Icon Theme:** Crisp, modern Linux icon theme by [Papirus Development Team](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme).
- **JaKooLit:** Initial inspiration for Ubuntu Hyprland packaging workflows.

---

## License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0). See [LICENSE](LICENSE) for details.
