#!/bin/bash
# ─────────────────────────────────────────────────────────
#  Clipboard History Applet — Auto Installer
#  Supports: Ubuntu, Debian, Linux Mint, Fedora, Arch
# ─────────────────────────────────────────────────────────

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/.local/share/clipboard-history"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔════════════════════════════════════════════╗"
echo "  ║     📋  Clipboard History Installer        ║"
echo "  ╚════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Detect distro ──
detect_distro() {
  if command -v apt &>/dev/null; then
    echo "debian"
  elif command -v dnf &>/dev/null; then
    echo "fedora"
  elif command -v pacman &>/dev/null; then
    echo "arch"
  else
    echo "unknown"
  fi
}

DISTRO=$(detect_distro)
echo -e "  ${BLUE}🖥️  Detected:${NC} $DISTRO-based system"
echo ""

# ── Install system dependencies ──
echo -e "  ${CYAN}📦 Installing system dependencies...${NC}"
sudo apt install 
case $DISTRO in
  debian)
    sudo apt update -qq
    sudo apt install -y \
      python3 \
      python3-pip \
      python3-gi \
      python3-gi-cairo \
      gir1.2-gtk-4.0 \
      gir1.2-notify-0.7 \
      libgtk-4-dev \
      libnotify-bin \
      xclip \
      gir1.2-adw-1 \
      -qq
    ;;
  fedora)
    sudo dnf install -y \
      python3 \
      python3-pip \
      python3-gobject \
      gtk4 \
      libnotify \
      xclip \
      gir1.2-adw-1 \
      -q
    ;;
  arch)
    sudo pacman -S --noconfirm \
      python \
      python-pip \
      python-gobject \
      gtk4 \
      libnotify \
      xclip \
      gir1.2-adw-1 
    ;;
  *)
    echo -e "  ${YELLOW}⚠️  Unknown distro — install manually:${NC}"
    echo "  python3-gi, gir1.2-gtk-4.0, gir1.2-notify-0.7"
    ;;
esac

echo -e "  ${GREEN}✅ System dependencies installed${NC}"
echo ""

# ── Install Python packages ──
echo -e "  ${CYAN}📦 Installing Python packages...${NC}"
pip3 install PyGObject --quiet 2>/dev/null || true
echo -e "  ${GREEN}✅ Python packages ready${NC}"
echo ""

# ── Install app files ──
echo -e "  ${CYAN}📁 Installing app to $APP_DIR...${NC}"
mkdir -p "$APP_DIR" "$BIN_DIR" "$DESKTOP_DIR"
cp "$SCRIPT_DIR/clipboard_history.py" "$APP_DIR/"
chmod +x "$APP_DIR/clipboard_history.py"

# ── Create launcher ──
cat > "$BIN_DIR/clipboard-history" <<EOF
#!/bin/bash
python3 $APP_DIR/clipboard_history.py "\$@"
EOF
chmod +x "$BIN_DIR/clipboard-history"

# ── Create .desktop entry ──
cat > "$DESKTOP_DIR/clipboard-history.desktop" <<EOF
[Desktop Entry]
Name=Clipboard History
Comment=Modern clipboard manager for Linux
Exec=$BIN_DIR/clipboard-history
Icon=edit-paste
Terminal=false
Type=Application
Categories=Utility;
Keywords=clipboard;copy;paste;history;
StartupNotify=true
EOF

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.local/bin:$PATH"
fi

echo ""
echo -e "${GREEN}${BOLD}"
echo "  ╔════════════════════════════════════════════╗"
echo "  ║       ✅  Installation Complete!           ║"
echo "  ╚════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${CYAN}Run from terminal:${NC}"
echo -e "  ${BOLD}  clipboard-history${NC}"
echo ""
echo -e "  ${CYAN}Or find it in your app launcher:${NC}"
echo -e "  ${BOLD}  'Clipboard History'${NC}"
echo ""
echo -e "  ${CYAN}Add to startup:${NC}"
echo -e "  ${BOLD}  Startup Applications → Add → clipboard-history${NC}"
echo ""
