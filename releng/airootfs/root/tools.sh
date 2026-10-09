#!/bin/bash
# =============================================================================
# PRO Linux — tools.sh
# Installs PRO Linux custom tools:
#   1. Universal Runner (run) — identifies, compiles and runs any source file
#   2. GUI Git Manager — Python-based git repo manager with venv
# Usage: sudo bash tools.sh <username>
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAUVE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
RESET='\033[0m'

print_header() {
  echo ""
  echo -e "${MAUVE}${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
  echo -e "${MAUVE}${BOLD}║  $1${RESET}"
  echo -e "${MAUVE}${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
  echo ""
}
print_success() { echo -e "${GREEN}${BOLD}[✔]${RESET} $1"; }
print_info() { echo -e "${CYAN}${BOLD}[→]${RESET} $1"; }
print_warning() { echo -e "${YELLOW}${BOLD}[!]${RESET} $1"; }
print_error() {
  echo -e "${RED}${BOLD}[✘]${RESET} $1"
  exit 1
}
print_step() { echo -e "${BLUE}${BOLD}[*]${RESET} $1"; }

# =============================================================================
# Validate input
# =============================================================================

if [ "$EUID" -ne 0 ]; then
  print_error "Run as root: sudo bash tools.sh <username>"
fi

if [ -z "$1" ]; then
  print_error "Usage: sudo bash tools.sh <username>"
fi

USERNAME="$1"
HOME_DIR="/home/$USERNAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! id "$USERNAME" &>/dev/null; then
  print_error "User '$USERNAME' does not exist."
fi

print_header "PRO Linux — Tools Installer"
print_info "Installing tools for user: ${BOLD}$USERNAME${RESET}"
echo ""

# =============================================================================
# Step 1 — Install Universal Runner (run)
#
# The 'run' file is expected to be in the same directory as tools.sh
# i.e. /home/$USERNAME/pro-linux/run
#
# It gets installed to /usr/local/bin/run so typing 'run filename'
# from anywhere in the terminal works immediately
# =============================================================================

install_universal_runner() {
  print_header "Step 1 — Installing Universal Runner"

  local run_src="$SCRIPT_DIR/run"

  # Verify the run file exists
  if [ ! -f "$run_src" ]; then
    print_warning "'run' file not found at $run_src — skipping Universal Runner install."
    return 1
  fi

  print_step "Copying 'run' to /usr/local/bin/..."
  cp "$run_src" /usr/local/bin/run

  print_step "Setting executable permissions..."
  chmod +x /usr/local/bin/run

  print_step "Verifying installation..."
  if [ -x /usr/local/bin/run ]; then
    print_success "Universal Runner installed at /usr/local/bin/run"
    print_info "Usage: run <filename>   (e.g. run main.py, run hello.c, run App.java)"
  else
    print_error "Failed to install Universal Runner."
  fi
}

# =============================================================================
# Step 2 — Install GUI Git Manager
#
# Expected directory structure in your repo:
#   pro-linux/
#   └── gitmanager/
#       ├── main.py          ← entry point of the app
#       ├── requirements.txt ← Python dependencies
#       └── ... other files
#
# What this step does:
#   1. Copies gitmanager/ to /opt/pro-linux/gitmanager/
#   2. Creates a Python virtual environment inside it
#   3. Installs requirements.txt into the venv
#   4. Creates a launcher script at /usr/local/bin/pro-gitmanager
#      that activates the venv and runs the app
#   5. Makes the launcher owned by the user
# =============================================================================

install_git_manager() {
  print_header "Step 2 — Installing GUI Git Manager"

  local src_dir="$SCRIPT_DIR/gitmanager"
  local install_dir="/opt/pro-linux/gitmanager"
  local launcher="/usr/local/bin/pro-gitmanager"

  # Verify gitmanager directory exists
  if [ ! -d "$src_dir" ]; then
    print_warning "gitmanager/ directory not found at $src_dir — skipping Git Manager install."
    return 1
  fi

  # Verify main.py exists
  if [ ! -f "$src_dir/main.py" ]; then
    print_warning "main.py not found inside gitmanager/ — skipping Git Manager install."
    return 1
  fi

  # Install python-venv if not present
  print_step "Ensuring python3-venv is available..."
  if ! python3 -m venv --help &>/dev/null; then
    pacman -S --noconfirm --needed python-virtualenv &>/dev/null
  fi
  print_success "python3-venv available."

  # Create install directory
  print_step "Creating install directory at $install_dir..."
  mkdir -p "$install_dir"

  # Copy all gitmanager files
  print_step "Copying gitmanager files to $install_dir..."
  cp -r "$src_dir"/. "$install_dir/"
  print_success "Files copied."

  # Create Python virtual environment inside install dir
  print_step "Creating Python virtual environment..."
  if ! python3 -m venv "$install_dir/venv"; then
    print_error "Failed to create virtual environment."
  fi
  print_success "Virtual environment created at $install_dir/venv"

  # Install requirements if requirements.txt exists
  if [ -f "$install_dir/requirements.txt" ]; then
    print_step "Installing Python dependencies from requirements.txt..."
    if ! "$install_dir/venv/bin/pip" install \
      -r "$install_dir/requirements.txt" \
      --quiet; then
      print_warning "Some dependencies failed to install — check requirements.txt"
    else
      print_success "Python dependencies installed."
    fi
  else
    print_warning "No requirements.txt found — skipping dependency install."
    print_info "Add a requirements.txt to gitmanager/ if your app has dependencies."
  fi

  # Set correct ownership so the user can read/write app files
  print_step "Setting ownership to $USERNAME..."
  chown -R "$USERNAME:$USERNAME" "$install_dir"
  print_success "Ownership set."

  # Create the launcher script
  # This script activates the venv and runs main.py
  # It's placed in /usr/local/bin so it's in $PATH for everyone
  print_step "Creating launcher script at $launcher..."
  cat >"$launcher" <<EOF
#!/bin/bash
# PRO Linux — GUI Git Manager Launcher
# Activates the Python venv and runs the app
# Generated by tools.sh — do not edit manually

APP_DIR="/opt/pro-linux/gitmanager"
VENV="\$APP_DIR/venv"

# Verify app directory exists
if [ ! -d "\$APP_DIR" ]; then
    echo "Error: Git Manager not found at \$APP_DIR"
    echo "Run: sudo bash ~/pro-linux/tools.sh $USERNAME"
    exit 1
fi

# Activate virtual environment
source "\$VENV/bin/activate"

# Run the app
cd "\$APP_DIR"
exec python3 main.py "\$@"
EOF

  chmod +x "$launcher"
  print_success "Launcher created at $launcher"
  print_info "You can now launch the Git Manager with: pro-gitmanager"
}

# =============================================================================
# Step 3 — Create .desktop entry for the Git Manager
# This allows the app to appear in rofi and app menus
# =============================================================================

create_desktop_entry() {
  print_header "Step 3 — Creating Desktop Entry"

  local desktop_dir="/usr/share/applications"
  local desktop_file="$desktop_dir/pro-gitmanager.desktop"

  print_step "Creating .desktop entry..."
  cat >"$desktop_file" <<'EOF'
[Desktop Entry]
Name=PRO Git Manager
Comment=GUI-based Git repository manager
Exec=pro-gitmanager
Icon=git
Terminal=false
Type=Application
Categories=Development;
Keywords=git;repo;version control;
StartupNotify=true
EOF

  chmod 644 "$desktop_file"
  print_success "Desktop entry created — app will appear in rofi and app menus."
}

# =============================================================================
# Step 4 — Print AwesomeWM keybinding instructions
# The actual keybinding must be added to rc.lua manually
# This function prints the exact line to add
# =============================================================================

print_keybinding_instructions() {
  print_header "Step 4 — AwesomeWM Keybinding (Super + G)"

  echo -e "  ${WHITE}Add this keybinding to your rc.lua to open Git Manager with Super+G:${RESET}"
  echo ""
  echo -e "  ${CYAN}${BOLD}Open your rc.lua:${RESET}"
  echo -e "  ${WHITE}  nano ~/.config/awesome/rc.lua${RESET}"
  echo ""
  echo -e "  ${CYAN}${BOLD}Find your keybindings section and add:${RESET}"
  echo ""
  echo -e "  ${MAUVE}${BOLD}-- Git Manager${RESET}"
  echo -e "  ${MAUVE}awful.key({ modkey }, \"g\", function()${RESET}"
  echo -e "  ${MAUVE}    awful.spawn(\"pro-gitmanager\")${RESET}"
  echo -e "  ${MAUVE}end, { description = \"open git manager\", group = \"launcher\" }),${RESET}"
  echo ""
  echo -e "  ${CYAN}${BOLD}Then reload AwesomeWM:${RESET}"
  echo -e "  ${WHITE}  Super + Ctrl + R${RESET}"
  echo ""
  echo -e "  ${GREEN}After that, Super + G will launch the Git Manager! 🎉${RESET}"
  echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
  install_universal_runner
  install_git_manager
  create_desktop_entry
  print_keybinding_instructions

  print_header "Tools Installation Complete!"
  echo -e "  ${GREEN}${BOLD}[✔] Universal Runner → /usr/local/bin/run${RESET}"
  echo -e "  ${GREEN}${BOLD}[✔] Git Manager      → /usr/local/bin/pro-gitmanager${RESET}"
  echo -e "  ${GREEN}${BOLD}[✔] Desktop entry    → rofi + app menus${RESET}"
  echo ""
  echo -e "  ${CYAN}Quick test:${RESET}"
  echo -e "  ${WHITE}  run <any_source_file>${RESET}"
  echo -e "  ${WHITE}  pro-gitmanager${RESET}"
  echo ""
}

main
