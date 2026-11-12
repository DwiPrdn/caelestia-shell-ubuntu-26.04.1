#!/usr/bin/env bash
#
# Hyprland + Caelestia Shell installer for Ubuntu 26.04 LTS (Resolute Raccoon)
#
# Unlike the 25.10 guide, this installs Hyprland itself - 26.04 packages it in
# universe, so no third-party installer is needed.
#
# https://github.com/caelestia-dots/shell
#

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "\n${CYAN}${BOLD}== $* ==${NC}"; }
die()   { err "$@"; exit 1; }

[[ "$(id -u)" -eq 0 ]] && die "Do not run this script as root."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$HOME/caelestia-build"
SHELL_DIR="$HOME/.config/quickshell/caelestia"

# Sanity: this script only claims to work on 26.04.
if ! grep -q 'VERSION_ID="26.04"' /etc/os-release 2>/dev/null; then
    warn "This script targets Ubuntu 26.04. Detected: $(. /etc/os-release; echo "$PRETTY_NAME")"
    read -rp "Continue anyway? [y/N] " a; [[ "$a" =~ ^[Yy] ]] || exit 1
fi

# ---------------------------------------------------------------- Step 1/10 --
step "Step 1/10: Hyprland and desktop components (from apt)"

sudo apt-get update
sudo apt-get install -y \
    hyprland hyprland-protocols hyprland-qtutils hyprwayland-scanner \
    hypridle hyprlock hyprpaper hyprpicker hyprpolkitagent \
    xdg-desktop-portal-hyprland \
    uwsm \
    ghostty alacritty dunst fuzzel wlogout swayosd nwg-displays nwg-look \
    qt5ct qt6ct pavucontrol papirus-icon-theme bibata-cursor-theme \
    hyprland-plugin-hyprexpo power-profiles-daemon \
    ristretto thunar-archive-plugin file-roller xarchiver tumbler p7zip-full unar acl mpv \
    zsh zsh-syntax-highlighting zsh-autosuggestions lsd bat fzf zoxide

# `hyprland` ships hyprland-uwsm.desktop but neither Depends nor Recommends
# uwsm, so the "Hyprland (uwsm-managed)" session at GDM fails without it.
ok "Hyprland $(Hyprland --version 2>/dev/null | head -1 | awk '{print $2}') and desktop components installed"

# ---------------------------------------------------------------- Step 2/10 --
step "Step 2/10: Build dependencies"

# Notes on the non-obvious ones:
#   qt6-shadertools-dev      qt6-shader-baker ships the binary but NOT the
#                            CMake config Quickshell needs.
#   qt6-*-private-dev        Debian/Ubuntu split Qt private headers out.
#   libcli11-dev             new Quickshell dependency since the 25.10 guide.
#   libgbm-dev/libegl-dev    Quickshell's Wayland buffer backend.
#   libsensors-dev           lm-sensors is tools only; Caelestia needs the lib.
#   libiniparser-dev + fftw  required by libcava.
#   libav*-dev, libpipewire  required by gpu-screen-recorder.
sudo apt-get install -y \
    build-essential cmake ninja-build git pkg-config meson \
    qt6-base-dev qt6-declarative-dev qt6-svg-dev qt6-wayland-dev qt6-wayland \
    qt6-shader-baker qt6-shadertools-dev libqt6svg6 qt6-image-formats-plugins \
    qt6-base-private-dev qt6-declarative-private-dev qt6-wayland-private-dev \
    libwayland-dev wayland-protocols libjemalloc-dev \
    libpipewire-0.3-dev libxcb1-dev libdrm-dev \
    libcli11-dev libgbm-dev libegl-dev libegl1-mesa-dev \
    libpolkit-agent-1-dev libpolkit-gobject-1-dev libpam0g-dev \
    libsensors-dev libqalculate-dev libaubio-dev \
    libiniparser-dev libfftw3-dev libasound2-dev libpulse-dev \
    libavcodec-dev libavformat-dev libavfilter-dev libavutil-dev libswresample-dev \
    libxi-dev libx11-dev libxcomposite-dev libxdamage-dev libxrender-dev libxrandr-dev libxfixes-dev \
    libva-dev libcap-dev libdbus-1-dev libgl-dev \
    python3-pip python3-build python3-hatchling \
    libnotify-bin grim slurp wl-clipboard fish brightnessctl ddcutil \
    lm-sensors swappy unzip wget

ok "Build dependencies installed"

# ---------------------------------------------------------------- Step 3/10 --
step "Step 3/10: Fonts"

# Caelestia needs THREE font families, plus JetBrainsMono for Ghostty/Terminal:
#   Material Symbols Rounded - every icon in the shell.
#   Rubik                    - clock and workspace labels
#   CaskaydiaCove NF         - monospace
#   JetBrainsMono NF         - terminal & code font

mkdir -p ~/.local/share/fonts
FONT_TMP="$(mktemp -d)"
trap 'rm -rf "$FONT_TMP"' EXIT

if fc-list | grep -qi "CaskaydiaCove"; then
    ok "CascadiaCode Nerd Font already installed"
else
    wget -q --show-progress -O "$FONT_TMP/CascadiaCode.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaCode.zip
    unzip -qo "$FONT_TMP/CascadiaCode.zip" -d "$FONT_TMP/CascadiaCode"
    cp "$FONT_TMP"/CascadiaCode/*.ttf ~/.local/share/fonts/
    ok "CascadiaCode Nerd Font installed"
fi

if fc-list | grep -qi "JetBrainsMono"; then
    ok "JetBrainsMono Nerd Font already installed"
else
    wget -q --show-progress -O "$FONT_TMP/JetBrainsMono.zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip
    unzip -qo "$FONT_TMP/JetBrainsMono.zip" -d "$FONT_TMP/JetBrainsMono"
    cp "$FONT_TMP"/JetBrainsMono/*.ttf ~/.local/share/fonts/
    ok "JetBrainsMono Nerd Font installed"
fi

if fc-list | grep -qi "Material Symbols Rounded"; then
    ok "Material Symbols Rounded already installed"
else
    wget -q --show-progress -O ~/.local/share/fonts/"MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf" \
        "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf"
    ok "Material Symbols Rounded installed"
fi

if fc-list | grep -qi "Rubik"; then
    ok "Rubik already installed"
else
    wget -q --show-progress -O ~/.local/share/fonts/"Rubik[wght].ttf" \
        "https://github.com/googlefonts/rubik/raw/main/fonts/variable/Rubik%5Bwght%5D.ttf"
    wget -q --show-progress -O ~/.local/share/fonts/"Rubik-Italic[wght].ttf" \
        "https://github.com/googlefonts/rubik/raw/main/fonts/variable/Rubik-Italic%5Bwght%5D.ttf"
    ok "Rubik installed"
fi

fc-cache -f >/dev/null

for family in "Material Symbols Rounded" "Rubik" "CaskaydiaCove NF" "JetBrainsMono NF"; do
    if fc-match "$family" | grep -qi "$(echo "$family" | tr -d ' ' | cut -c1-6)"; then
        ok "  $family resolves"
    else
        warn "  $family does NOT resolve - icons or text will look wrong"
    fi
done

# ---------------------------------------------------------------- Step 4/10 --
step "Step 4/10: Build Quickshell (not packaged in 26.04)"

mkdir -p "$BUILD_DIR"; cd "$BUILD_DIR"
if [[ -d quickshell ]]; then
    cd quickshell && git pull --ff-only || true
else
    git clone https://git.outfoxxed.me/quickshell/quickshell.git && cd quickshell
fi

cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCRASH_HANDLER=OFF \
    -DINSTALL_QML_PREFIX=lib/qt6/qml

cmake --build build
sudo cmake --install build
ok "Quickshell $(quickshell --version 2>/dev/null | awk '{print $2}') installed"

# ---------------------------------------------------------------- Step 5/10 --
step "Step 5/10: Build libcava (LukashonakV fork)"

cd "$BUILD_DIR"
if [[ -d libcava ]]; then
    cd libcava && git pull --ff-only || true
else
    git clone https://github.com/LukashonakV/cava.git libcava && cd libcava
fi

meson setup build --buildtype=release -Ddefault_library=shared --wipe 2>/dev/null \
    || meson setup build --buildtype=release -Ddefault_library=shared
meson compile -C build
sudo meson install -C build

echo "/usr/local/lib/x86_64-linux-gnu" | sudo tee /etc/ld.so.conf.d/libcava.conf >/dev/null
sudo ldconfig
ok "libcava installed"

# ---------------------------------------------------------------- Step 6/10 --
step "Step 6/10: Build m3shapes (Material Design 3 shapes Qt QML plugin)"

# Caelestia v2.4.0+ requires M3Shapes, which is not packaged in Ubuntu.
cd "$BUILD_DIR"
if [[ -d m3shapes ]]; then
    cd m3shapes && git pull --ff-only || true
else
    git clone https://github.com/soramanew/m3shapes.git m3shapes && cd m3shapes
fi

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DINSTALL_QMLDIR=lib/qt6/qml
cmake --build build
sudo cmake --install build
sudo ldconfig
ok "m3shapes installed"

# ---------------------------------------------------------------- Step 7/10 --
step "Step 7/10: Build gpu-screen-recorder (Caelestia screen recorder backend)"

cd "$BUILD_DIR"
if [[ -d gpu-screen-recorder ]]; then
    cd gpu-screen-recorder && git pull --ff-only || true
else
    git clone --depth 1 https://repo.dec05eba.com/gpu-screen-recorder && cd gpu-screen-recorder
fi

meson setup build --prefix=/usr --wipe 2>/dev/null || meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
ok "gpu-screen-recorder installed"

# ---------------------------------------------------------------- Step 8/10 --
step "Step 8/10: Caelestia CLI"

cd "$BUILD_DIR"
if [[ -d caelestia-cli ]]; then
    cd caelestia-cli && git pull --ff-only || true
else
    git clone https://github.com/caelestia-dots/cli.git caelestia-cli && cd caelestia-cli
fi

python3 -m build --wheel
sudo pip3 install dist/*.whl --break-system-packages --force-reinstall
ok "Caelestia CLI installed"

# ---------------------------------------------------------------- Step 9/10 --
step "Step 9/10: Caelestia Shell (+ Qt 6.10 compatibility patch)"

mkdir -p ~/.config/quickshell
if [[ -d "$SHELL_DIR/.git" ]]; then
    cd "$SHELL_DIR" && git pull --ff-only || true
else
    git clone https://github.com/caelestia-dots/shell.git "$SHELL_DIR"
    cd "$SHELL_DIR"
fi

if git apply --check "$SCRIPT_DIR/patches/qt6.10-compat.patch" 2>/dev/null; then
    git apply "$SCRIPT_DIR/patches/qt6.10-compat.patch"
    ok "Applied Qt 6.10 compatibility patch"
elif git apply --reverse --check "$SCRIPT_DIR/patches/qt6.10-compat.patch" 2>/dev/null; then
    ok "Qt 6.10 compatibility patch already applied"
else
    warn "Patch did not apply cleanly against this Caelestia revision."
    warn "Upstream has probably moved; see docs/ubuntu-26.04.md for what it fixes."
fi

PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:${PKG_CONFIG_PATH:-}" \
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build
ok "Caelestia Shell installed"

# ---------------------------------------------------------------- Step 10/10 -
step "Step 10/10: Configuration, Terminal & System Integrations"

# QML Import Path
if ! grep -q 'QML_IMPORT_PATH=/usr/lib/qt6/qml' ~/.bashrc 2>/dev/null; then
    echo 'export QML_IMPORT_PATH=/usr/lib/qt6/qml' >> ~/.bashrc
    ok "Added QML_IMPORT_PATH to ~/.bashrc"
fi

mkdir -p ~/.config/caelestia ~/.config/hypr ~/.config/ghostty ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/Pictures/Wallpapers

install_config() {
    local src="$1" dst="$2"
    if [[ -e "$dst" ]]; then
        warn "$dst exists, leaving it alone"
    else
        cp "$src" "$dst" && ok "Installed $dst"
    fi
}

install_config "$SCRIPT_DIR/config/26.04/shell.json"  ~/.config/caelestia/shell.json
install_config "$SCRIPT_DIR/config/26.04/cli.json"    ~/.config/caelestia/cli.json
install_config "$SCRIPT_DIR/config/26.04/quickshell/qml_color.json" ~/.config/quickshell/qml_color.json
install_config "$SCRIPT_DIR/config/26.04/hyprland.conf" ~/.config/hypr/hyprland.conf
install_config "$SCRIPT_DIR/config/26.04/ghostty/config" ~/.config/ghostty/config
install_config "$SCRIPT_DIR/config/26.04/starship.toml" ~/.config/starship.toml
install_config "$SCRIPT_DIR/config/26.04/zshrc" ~/.zshrc

# Install Starship prompt binary if missing
if ! command -v starship &>/dev/null; then
    info "Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y >/dev/null 2>&1 || true
fi

# Oh-My-Zsh & plugins
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh-My-Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >/dev/null 2>&1 || true
fi
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" >/dev/null 2>&1 || true
fi
if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" >/dev/null 2>&1 || true
fi

# Make bash launch zsh globally
if ! grep -q 'exec /usr/bin/zsh -l' ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Launch Zsh if available
if [ -x /usr/bin/zsh ] && [ "$SHLVL" = "1" ] && [ -z "$ZSH_VERSION" ]; then
    exec /usr/bin/zsh -l
fi
EOF
fi

# Set default terminal to Ghostty
sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/ghostty 100 >/dev/null 2>&1 || true
sudo update-alternatives --set x-terminal-emulator /usr/bin/ghostty >/dev/null 2>&1 || true

# Set login shell to zsh
if [[ "$SHELL" != */zsh ]]; then
    sudo chsh -s /usr/bin/zsh "$USER" 2>/dev/null || true
fi

# Cursor theme: Bibata-Modern-Classic
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
mkdir -p ~/.icons/default
printf '[Icon Theme]\nInherits=Bibata-Modern-Classic\n' > ~/.icons/default/index.theme

# Icon theme: Papirus-Dark
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true

# Default image viewer: Ristretto
for mime in image/png image/jpeg image/jpg image/webp image/gif image/bmp image/tiff image/svg+xml; do
    xdg-mime default org.xfce.ristretto.desktop "$mime" 2>/dev/null || true
done

# Hardware Brightness permission (suid on brightnessctl)
sudo chmod u+s /usr/bin/brightnessctl 2>/dev/null || true
echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' | sudo tee /etc/udev/rules.d/90-backlight.rules >/dev/null
sudo usermod -aG video "$USER" 2>/dev/null || true

# Fix APT sandboxing for local .debs
sudo setfacl -m u:_apt:rx "$HOME" "$HOME/Downloads" 2>/dev/null || true
sudo setfacl -d -m u:_apt:rx "$HOME/Downloads" 2>/dev/null || true

# Mask waybar to prevent conflicting topbars
systemctl --user mask waybar.service 2>/dev/null || true

# Qt6ct configuration
mkdir -p ~/.config/qt6ct
install_config "$SCRIPT_DIR/config/26.04/qt6ct/qt6ct.conf" ~/.config/qt6ct/qt6ct.conf

# SDDM configuration (Pixie theme, custom wallpaper, disable virtual keyboard)
if command -v sddm &>/dev/null || [[ -d /usr/share/sddm ]]; then
    if [[ ! -d /usr/share/sddm/themes/pixie ]]; then
        info "Installing Pixie SDDM theme..."
        sudo git clone --depth=1 https://github.com/xCaptaiN09/pixie-sddm.git /usr/share/sddm/themes/pixie >/dev/null 2>&1 || true
    fi
    if [[ -f "$SCRIPT_DIR/config/26.04/sddm/background.jpg" && -d /usr/share/sddm/themes/pixie/assets ]]; then
        sudo cp "$SCRIPT_DIR/config/26.04/sddm/background.jpg" /usr/share/sddm/themes/pixie/assets/background.jpg 2>/dev/null || true
    fi
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp "$SCRIPT_DIR/config/26.04/sddm/99-theme.conf" /etc/sddm.conf.d/99-theme.conf 2>/dev/null || true
    ok "SDDM Pixie theme configured"
fi

# Caelestia systemd service
mkdir -p ~/.config/systemd/user
install_config "$SCRIPT_DIR/config/26.04/systemd/caelestia-shell.service" \
    ~/.config/systemd/user/caelestia-shell.service
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable caelestia-shell.service 2>/dev/null \
    && ok "Shell supervised by systemd (auto-restarts on crash)" \
    || warn "Could not enable caelestia-shell.service"

if Hyprland --verify-config 2>&1 | grep -q "config ok"; then
    ok "Hyprland config verified"
else
    warn "Hyprland reported config errors; run: Hyprland --verify-config"
fi

echo ""
echo -e "${GREEN}${BOLD}=========================================================${NC}"
echo -e "${GREEN}${BOLD}  Done. Log out and pick 'Hyprland' at the login screen.${NC}"
echo -e "${GREEN}${BOLD}=========================================================${NC}"
echo ""
echo -e "  Start the shell manually:  ${CYAN}caelestia shell -d${NC}"
echo -e "  Terminal:                  ${BOLD}Ghostty${NC} (tabs, Catppuccin Mocha, Starship, Zsh)"
echo -e "  Wallpapers:                ${BOLD}~/Pictures/Wallpapers/${NC}"
echo -e "  Shell config:              ${BOLD}~/.config/caelestia/shell.json${NC}"
echo ""
