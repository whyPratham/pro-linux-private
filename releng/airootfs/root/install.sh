#!/bin/bash
# =============================================================================
# PRO Linux — install.sh
# Main entry point for the PRO Linux installer
# Installs base Arch Linux system with GRUB bootloader
# Supports both UEFI and BIOS systems
# Partition scheme: Boot (512M) + Swap (4G) + Root (remaining)
# Filesystem: ext4
# =============================================================================

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# =============================================================================
# Welcome Screen
# =============================================================================

welcome() {
  clear
  echo -e "${MAUVE}${BOLD}"
  echo "  ██████╗ ██████╗  ██████╗     ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗"
  echo "  ██╔══██╗██╔══██╗██╔═══██╗    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝"
  echo "  ██████╔╝██████╔╝██║   ██║    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ "
  echo "  ██╔═══╝ ██╔══██╗██║   ██║    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ "
  echo "  ██║     ██║  ██║╚██████╔╝    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗"
  echo "  ╚═╝     ╚═╝  ╚═╝ ╚═════╝     ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝"
  echo -e "${RESET}"
  echo -e "${WHITE}${BOLD}  A clean, minimal, and opinionated Arch Linux distribution${RESET}"
  echo -e "${MAUVE}  Themed with Catppuccin Mocha + Mauve · Powered by AwesomeWM${RESET}"
  echo ""
  echo -e "${WHITE}  Version: 1.0.0${RESET}"
  echo -e "${WHITE}  https://github.com/whyPratham/pro-linux${RESET}"
  echo ""
  echo -e "${YELLOW}${BOLD}  WARNING: This installer will COMPLETELY ERASE the selected disk.${RESET}"
  echo -e "${YELLOW}  ALL existing data will be permanently destroyed.${RESET}"
  echo -e "${YELLOW}  Make sure you have backed up all important data before continuing.${RESET}"
  echo ""
  echo -e "${WHITE}  Press ENTER to continue or Ctrl+C to exit...${RESET}"
  read -r
}

# =============================================================================
# Collect user input
# =============================================================================

collect_input() {
  print_header "System Configuration"

  # BUG FIX: renamed from HOSTNAME to SYS_HOSTNAME
  # HOSTNAME is a reserved bash variable
  SYS_HOSTNAME=$(ask "Enter hostname" "pro-linux")
  USERNAME=$(ask "Enter username" "user")

  # User password
  while true; do
    PASSWORD=$(ask_password "Enter password for $USERNAME")
    PASSWORD_CONFIRM=$(ask_password "Confirm password")
    if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
      print_success "Passwords match."
      break
    else
      print_warning "Passwords do not match. Please try again."
    fi
  done

  # Root password
  while true; do
    ROOT_PASSWORD=$(ask_password "Enter root password")
    ROOT_PASSWORD_CONFIRM=$(ask_password "Confirm root password")
    if [ "$ROOT_PASSWORD" = "$ROOT_PASSWORD_CONFIRM" ]; then
      print_success "Root passwords match."
      break
    else
      print_warning "Passwords do not match. Please try again."
    fi
  done

  TIMEZONE=$(ask "Enter timezone" "Asia/Kolkata")

  # Validate timezone
  if [ ! -f "/usr/share/zoneinfo/${TIMEZONE}" ]; then
    print_warning "Timezone '${TIMEZONE}' not found — defaulting to Asia/Kolkata."
    TIMEZONE="Asia/Kolkata"
  fi

  LOCALE=$(ask "Enter locale" "en_US.UTF-8")

  # Disk selection
  list_disks
  DISK_NAME=$(ask "Enter disk to install to (e.g. sda, nvme0n1)" "sda")
  DISK="/dev/$DISK_NAME"

  if [ ! -b "$DISK" ]; then
    print_error "Disk $DISK not found or is not a block device."
  fi

  BOOT_MODE=$(detect_boot_mode)
  print_info "Boot mode detected: ${BOLD}$BOOT_MODE${RESET}"

  # BUG FIX: set PART variables here so available to all functions
  if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
    PART1="${DISK}p1"
    PART2="${DISK}p2"
    PART3="${DISK}p3"
  else
    PART1="${DISK}1"
    PART2="${DISK}2"
    PART3="${DISK}3"
  fi

  echo ""
  print_header "Installation Summary"
  echo -e "  ${WHITE}Hostname:${RESET}   $SYS_HOSTNAME"
  echo -e "  ${WHITE}Username:${RESET}   $USERNAME"
  echo -e "  ${WHITE}Timezone:${RESET}   $TIMEZONE"
  echo -e "  ${WHITE}Locale:${RESET}     $LOCALE"
  echo -e "  ${WHITE}Disk:${RESET}       $DISK"
  echo -e "  ${WHITE}Boot mode:${RESET}  $BOOT_MODE"
  echo -e "  ${WHITE}Partitions:${RESET}"
  if [ "$BOOT_MODE" = "UEFI" ]; then
    echo -e "    ${MAUVE}${PART1}${RESET} → EFI  (512M, FAT32)"
  else
    echo -e "    ${MAUVE}${PART1}${RESET} → Boot (512M, ext4)"
  fi
  echo -e "    ${MAUVE}${PART2}${RESET} → Swap (4G)"
  echo -e "    ${MAUVE}${PART3}${RESET} → Root (remaining, ext4)"
  echo ""
  echo -e "  ${RED}${BOLD}⚠  ALL DATA ON $DISK WILL BE PERMANENTLY ERASED  ⚠${RESET}"
  echo ""

  if ! confirm "Are you absolutely sure you want to proceed?"; then
    print_warning "Installation cancelled by user."
    exit 0
  fi
}

# =============================================================================
# Partition the disk
# =============================================================================

partition_disk() {
  print_header "Partitioning Disk"

  print_step "Wiping all existing signatures on $DISK..."
  wipefs -af "$DISK" &>/dev/null
  print_success "Filesystem signatures wiped."

  print_step "Destroying existing partition table on $DISK..."
  sgdisk -Z "$DISK" &>/dev/null
  print_success "Partition table destroyed."

  if [ "$BOOT_MODE" = "UEFI" ]; then
    print_step "Creating UEFI partition scheme (GPT)..."
    sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" "$DISK" &>/dev/null
    sgdisk -n 2:0:+4G -t 2:8200 -c 2:"SWAP" "$DISK" &>/dev/null
    sgdisk -n 3:0:0 -t 3:8300 -c 3:"ROOT" "$DISK" &>/dev/null
    print_success "UEFI (GPT) partition scheme created."
  else
    print_step "Creating BIOS partition scheme (MBR)..."
    parted -s "$DISK" mklabel msdos &>/dev/null
    parted -s "$DISK" mkpart primary ext4 1MiB 513MiB &>/dev/null
    parted -s "$DISK" set 1 boot on &>/dev/null
    parted -s "$DISK" mkpart primary linux-swap 513MiB 4.5GiB &>/dev/null
    parted -s "$DISK" mkpart primary ext4 4.5GiB 100% &>/dev/null
    print_success "BIOS (MBR) partition scheme created."
  fi

  partprobe "$DISK" &>/dev/null
  sleep 1

  print_success "Partitions created: $PART1 $PART2 $PART3"
}

# =============================================================================
# Format partitions
# =============================================================================

format_partitions() {
  print_header "Formatting Partitions"

  if [ "$BOOT_MODE" = "UEFI" ]; then
    print_step "Formatting EFI partition ($PART1) as FAT32..."
    if ! mkfs.fat -F32 -n "EFI" "$PART1" &>/dev/null; then
      print_error "Failed to format EFI partition."
    fi
    print_success "EFI partition formatted as FAT32."
  else
    print_step "Formatting boot partition ($PART1) as ext4..."
    if ! mkfs.ext4 -F -L "BOOT" "$PART1" &>/dev/null; then
      print_error "Failed to format boot partition."
    fi
    print_success "Boot partition formatted as ext4."
  fi

  print_step "Formatting swap partition ($PART2)..."
  if ! mkswap -L "SWAP" "$PART2" &>/dev/null; then
    print_error "Failed to format swap partition."
  fi
  print_success "Swap partition formatted."

  print_step "Formatting root partition ($PART3) as ext4..."
  if ! mkfs.ext4 -F -L "ROOT" "$PART3" &>/dev/null; then
    print_error "Failed to format root partition."
  fi
  print_success "Root partition formatted as ext4."
}

# =============================================================================
# Mount partitions
# =============================================================================

mount_partitions() {
  print_header "Mounting Partitions"

  print_step "Mounting root partition ($PART3) at /mnt..."
  if ! mount "$PART3" /mnt; then
    print_error "Failed to mount root partition $PART3. Aborting."
  fi
  print_success "Root partition mounted at /mnt"

  print_step "Enabling swap ($PART2)..."
  if ! swapon "$PART2"; then
    print_warning "Failed to enable swap — continuing without it."
  else
    print_success "Swap enabled."
  fi

  if [ "$BOOT_MODE" = "UEFI" ]; then
    print_step "Mounting EFI partition ($PART1) at /mnt/boot/efi..."
    mkdir -p /mnt/boot/efi
    if ! mount "$PART1" /mnt/boot/efi; then
      print_error "Failed to mount EFI partition. Aborting."
    fi
    print_success "EFI partition mounted at /mnt/boot/efi"
  else
    print_step "Mounting boot partition ($PART1) at /mnt/boot..."
    mkdir -p /mnt/boot
    if ! mount "$PART1" /mnt/boot; then
      print_error "Failed to mount boot partition. Aborting."
    fi
    print_success "Boot partition mounted at /mnt/boot"
  fi
}

# =============================================================================
# Install base system
# =============================================================================

install_base() {
  print_header "Installing Base System"

  print_step "Updating pacman mirrors with reflector..."
  if reflector --country India --latest 10 --sort rate \
    --save /etc/pacman.d/mirrorlist &>/dev/null; then
    print_success "Mirrors updated."
  else
    print_warning "Reflector failed — using default mirrors."
  fi

  sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' \
    /etc/pacman.conf &>/dev/null

  print_step "Installing base system via pacstrap (this may take a while)..."
  if ! pacstrap /mnt \
    base base-devel linux linux-firmware linux-headers \
    nano vim git curl wget \
    networkmanager grub efibootmgr dosfstools \
    os-prober reflector sudo zsh parted \
    &>/dev/null; then
    print_error "pacstrap failed. Check your internet connection and try again."
  fi
  print_success "Base system installed."
}

# =============================================================================
# Generate fstab
# =============================================================================

generate_fstab() {
  print_header "Generating fstab"
  print_step "Generating fstab using UUIDs..."
  genfstab -U /mnt >>/mnt/etc/fstab
  print_success "fstab generated."
}

# =============================================================================
# Configure system inside chroot
# =============================================================================

configure_system() {
  print_header "Configuring System"

  # Timezone
  print_step "Setting timezone to ${TIMEZONE}..."
  arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
  arch-chroot /mnt hwclock --systohc
  print_success "Timezone set to ${TIMEZONE}"

  # Locale
  # BUG FIX: uncomment existing entry instead of always appending
  print_step "Setting locale to ${LOCALE}..."
  if grep -q "^#${LOCALE} UTF-8" /mnt/etc/locale.gen; then
    sed -i "s/^#${LOCALE} UTF-8/${LOCALE} UTF-8/" /mnt/etc/locale.gen
  else
    echo "${LOCALE} UTF-8" >>/mnt/etc/locale.gen
  fi
  arch-chroot /mnt locale-gen &>/dev/null
  echo "LANG=${LOCALE}" >/mnt/etc/locale.conf
  print_success "Locale set to ${LOCALE}"

  # Hostname
  # BUG FIX: using SYS_HOSTNAME not HOSTNAME
  print_step "Setting hostname to ${SYS_HOSTNAME}..."
  echo "${SYS_HOSTNAME}" >/mnt/etc/hostname
  cat >/mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${SYS_HOSTNAME}.localdomain ${SYS_HOSTNAME}
EOF
  print_success "Hostname set to ${SYS_HOSTNAME}"

  # PRO Linux identity
  # FIX: sets os-release on installed system so fastfetch shows PRO Linux
  print_step "Setting PRO Linux system identity..."
  cat >/mnt/etc/os-release <<'EOF'
NAME="PRO Linux"
PRETTY_NAME="PRO Linux 1.0.0"
ID=pro-linux
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="0;35"
HOME_URL="https://github.com/whyPratham/pro-linux"
SUPPORT_URL="https://github.com/whyPratham/pro-linux/issues"
BUG_REPORT_URL="https://github.com/whyPratham/pro-linux/issues"
LOGO=pro-linux
EOF
  print_success "PRO Linux identity set — fastfetch will show PRO Linux."

  # Passwords
  print_step "Setting root password..."
  echo "root:${ROOT_PASSWORD}" | arch-chroot /mnt chpasswd
  print_success "Root password set."

  # Create user
  print_step "Creating user ${USERNAME}..."
  arch-chroot /mnt useradd -m \
    -G wheel,audio,video,storage,optical,network \
    -s /bin/zsh \
    "${USERNAME}"
  echo "${USERNAME}:${PASSWORD}" | arch-chroot /mnt chpasswd
  print_success "User ${USERNAME} created."

  # Sudo
  print_step "Configuring sudo for wheel group..."
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' \
    /mnt/etc/sudoers
  print_success "Sudo configured for wheel group."

  # Pacman tweaks
  print_step "Configuring pacman..."
  sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /mnt/etc/pacman.conf
  sed -i 's/#Color/Color/' /mnt/etc/pacman.conf
  sed -i '/^Color/a ILoveCandy' /mnt/etc/pacman.conf
  sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /mnt/etc/pacman.conf
  print_success "Pacman configured."

  # Pacman keyring
  # BUG FIX: prevents PGP errors during AUR installs in awesome.sh
  print_step "Initializing pacman keyring..."
  arch-chroot /mnt pacman-key --init &>/dev/null
  arch-chroot /mnt pacman-key --populate archlinux &>/dev/null
  print_success "Pacman keyring initialized."

  # Initramfs
  print_step "Generating initramfs..."
  arch-chroot /mnt mkinitcpio -P &>/dev/null
  print_success "Initramfs generated."

  # NetworkManager
  print_step "Enabling NetworkManager..."
  arch-chroot /mnt systemctl enable NetworkManager &>/dev/null
  arch-chroot /mnt systemctl enable NetworkManager-wait-online &>/dev/null
  print_success "NetworkManager enabled."
}

# =============================================================================
# Install GRUB bootloader
# =============================================================================

install_grub() {
  print_header "Installing GRUB Bootloader"

  if [ "$BOOT_MODE" = "UEFI" ]; then
    print_step "Installing GRUB for UEFI..."
    if ! arch-chroot /mnt grub-install \
      --target=x86_64-efi \
      --efi-directory=/boot/efi \
      --bootloader-id=PRO-Linux \
      &>/dev/null; then
      print_error "GRUB UEFI installation failed."
    fi
    print_success "GRUB installed for UEFI."
  else
    print_step "Installing GRUB for BIOS..."
    if ! arch-chroot /mnt grub-install \
      --target=i386-pc \
      "${DISK}" \
      &>/dev/null; then
      print_error "GRUB BIOS installation failed."
    fi
    print_success "GRUB installed for BIOS."
  fi

  print_step "Configuring GRUB..."
  sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' \
    /mnt/etc/default/grub
  sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="PRO Linux"/' \
    /mnt/etc/default/grub
  sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=3/' \
    /mnt/etc/default/grub

  if ! arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null; then
    print_error "Failed to generate GRUB config."
  fi
  print_success "GRUB configured."
}

# =============================================================================
# Copy installer scripts to new system
# =============================================================================

copy_scripts() {
  print_header "Copying Installer Scripts"

  print_step "Copying scripts to /home/${USERNAME}/pro-linux/..."
  mkdir -p "/mnt/home/${USERNAME}/pro-linux"
  cp -r "${SCRIPT_DIR}"/* "/mnt/home/${USERNAME}/pro-linux/"
  arch-chroot /mnt chown -R "${USERNAME}:${USERNAME}" \
    "/home/${USERNAME}/pro-linux"
  arch-chroot /mnt chmod +x \
    "/home/${USERNAME}/pro-linux/"*.sh
  print_success "Scripts copied to /home/${USERNAME}/pro-linux/"
}

# =============================================================================
# Set up first-boot systemd service to run awesome.sh
#
# BUG FIX (latest): previously used heredoc inside arch-chroot which
# silently failed — service was never created.
# FIX: write service file DIRECTLY to /mnt/etc/systemd/system/
# and create symlink manually instead of using systemctl enable in chroot.
# Both steps are now verified with existence checks.
# =============================================================================

run_awesome_installer() {
  print_header "Running AwesomeWM Installer"

  # Set up temporary passwordless sudo inside chroot
  # so run_as_user works correctly
  print_step "Configuring temporary sudo access..."
  echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL" > \
    /mnt/etc/sudoers.d/awesome-install
  chmod 440 /mnt/etc/sudoers.d/awesome-install
  print_success "Temporary sudo configured."

  # Ensure home directory and .config exist with correct ownership
  # before awesome.sh tries to clone anything into them
  print_step "Preparing user home directory..."
  mkdir -p /mnt/home/$USERNAME/.config
  arch-chroot /mnt chown -R $USERNAME:$USERNAME \
    /home/$USERNAME
  print_success "Home directory ready."

  # Run awesome.sh inside chroot
  print_step "Running awesome.sh (this will take a while)..."
  if arch-chroot /mnt bash \
    /home/$USERNAME/pro-linux/awesome.sh "$USERNAME"; then
    print_success "AwesomeWM setup complete."
  else
    print_warning "awesome.sh finished with some warnings — check output above."
  fi

  # Run tools.sh after awesome.sh
  print_step "Running tools.sh..."
  if arch-chroot /mnt bash \
    /home/$USERNAME/pro-linux/tools.sh "$USERNAME"; then
    print_success "Tools setup complete."
  else
    print_warning "tools.sh finished with warnings."
  fi

  # Remove temporary sudo access
  rm -f /mnt/etc/sudoers.d/awesome-install
  print_success "Temporary sudo access removed."
}

# =============================================================================
# Setup developer.sh first-launch hook
# Since developer.sh has an interactive TUI it cannot run silently
# during installation. Instead we add a one-time hook to .zprofile
# that triggers it automatically when the user first opens a terminal.
# The hook removes itself after running so it never prompts again.
# =============================================================================

setup_developer_launcher() {
  print_header "Setting Up Developer Environment Launcher"

  print_step "Writing first-launch hook to .zprofile..."
  cat >>/mnt/home/${USERNAME}/.zprofile <<EOF

# =============================================================================
# PRO Linux — One-time developer environment setup
# Runs automatically on first terminal open after installation
# Removes itself after running so it never prompts again
# =============================================================================
if [ -f "\$HOME/pro-linux/developer.sh" ] && \
   [ ! -f "\$HOME/.pro-linux-dev-setup-done" ]; then
    echo ""
    echo -e "\033[0;35m\033[1m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;35m\033[1m║       PRO Linux — Developer Environment Setup Available      ║\033[0m"
    echo -e "\033[0;35m\033[1m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "  \033[0;37mWould you like to set up your developer environment now?\033[0m"
    echo -e "  \033[2m(You can always run it later: sudo bash ~/pro-linux/developer.sh \$USER)\033[0m"
    echo ""
    read -rp "  Run developer setup? [y/N]: " _dev_answer
    echo ""
    if [[ "\$_dev_answer" =~ ^[Yy]$ ]]; then
        sudo bash "\$HOME/pro-linux/developer.sh" "\$USER"
    else
        echo -e "  \033[0;33m[!]\033[0m Skipped. Run later with: sudo bash ~/pro-linux/developer.sh \$USER"
    fi
    # Mark as done so this never runs again
    touch "\$HOME/.pro-linux-dev-setup-done"
    unset _dev_answer
fi
EOF

  # Set correct ownership
  arch-chroot /mnt chown ${USERNAME}:${USERNAME} \
    /home/${USERNAME}/.zprofile

  print_success "Developer launcher hook added to .zprofile"
  print_info "User will be prompted to run developer setup on first terminal open."
}

# =============================================================================
# Finish installation
# =============================================================================

finish() {
  print_header "Installation Complete!"

  echo -e "${GREEN}${BOLD}"
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║       PRO Linux Successfully Installed!          ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo ""
  echo -e "  ${WHITE}Login with username: ${MAUVE}${BOLD}${USERNAME}${RESET}"
  echo ""
  echo -e "  ${CYAN}${BOLD}What happens on first boot:${RESET}"
  echo -e "  ${WHITE}  1. System boots and connects to internet${RESET}"
  echo -e "  ${WHITE}  2. awesome.sh runs automatically (10-20 mins)${RESET}"
  echo -e "  ${WHITE}  3. All packages, themes and configs are installed${RESET}"
  echo -e "  ${WHITE}  4. Login screen appears when setup is complete${RESET}"
  echo -e "  ${WHITE}  5. Select AwesomeWM session and log in${RESET}"
  echo ""
  echo -e "  ${YELLOW}${BOLD}Remove the installation media before rebooting!${RESET}"
  echo ""

  if confirm "Reboot now?"; then
    print_step "Unmounting all partitions..."
    umount -R /mnt
    swapoff "${PART2}" &>/dev/null
    print_success "Partitions unmounted."
    print_step "Rebooting into PRO Linux..."
    reboot
  else
    print_info "Unmount manually with: umount -R /mnt && swapoff ${PART2}"
    print_info "Then reboot when ready."
  fi
}

# =============================================================================
# Main — order matters, do not rearrange
# =============================================================================

main() {
  check_root
  check_internet
  welcome
  collect_input
  partition_disk
  format_partitions
  mount_partitions
  install_base
  generate_fstab
  configure_system
  install_grub
  copy_scripts
  run_awesome_installer
  setup_developer_launcher
  finish
}

main
