#!/bin/bash
# =============================================================================
# PRO Linux — developer.sh
# One-click developer environment setup
# Interactive TUI with checkbox selection
# Navigate: Arrow keys | Select: Space | Confirm: Enter | Quit: Q
# Usage: sudo bash developer.sh [username]
# =============================================================================

set -o pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAUVE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# =============================================================================
# Items definition — grouped by category
# Format: KEY|LABEL|CATEGORY
# =============================================================================

declare -A ITEM_LABEL
declare -A ITEM_CATEGORY
declare -a ITEM_KEYS
declare -A CHECKED

# Languages
ITEM_KEYS+=("python")   ; ITEM_LABEL["python"]="🐍  Python 3 + pip + venv"       ; ITEM_CATEGORY["python"]="Languages"
ITEM_KEYS+=("java")     ; ITEM_LABEL["java"]="☕  Java JDK 17 (OpenJDK)"          ; ITEM_CATEGORY["java"]="Languages"
ITEM_KEYS+=("node")     ; ITEM_LABEL["node"]="🟩  Node.js + npm"                  ; ITEM_CATEGORY["node"]="Languages"
ITEM_KEYS+=("rust")     ; ITEM_LABEL["rust"]="🦀  Rust + Cargo"                   ; ITEM_CATEGORY["rust"]="Languages"
ITEM_KEYS+=("go")       ; ITEM_LABEL["go"]="🐹  Go (Golang)"                      ; ITEM_CATEGORY["go"]="Languages"
ITEM_KEYS+=("ruby")     ; ITEM_LABEL["ruby"]="💎  Ruby + gem"                     ; ITEM_CATEGORY["ruby"]="Languages"
ITEM_KEYS+=("php")      ; ITEM_LABEL["php"]="🐘  PHP + Composer"                  ; ITEM_CATEGORY["php"]="Languages"
ITEM_KEYS+=("kotlin")   ; ITEM_LABEL["kotlin"]="🔷  Kotlin"                       ; ITEM_CATEGORY["kotlin"]="Languages"
ITEM_KEYS+=("scala")    ; ITEM_LABEL["scala"]="🍺  Scala + SBT"                   ; ITEM_CATEGORY["scala"]="Languages"
ITEM_KEYS+=("swift")    ; ITEM_LABEL["swift"]="🎯  Swift"                         ; ITEM_CATEGORY["swift"]="Languages"
ITEM_KEYS+=("r")        ; ITEM_LABEL["r"]="📊  R Language"                        ; ITEM_CATEGORY["r"]="Languages"
ITEM_KEYS+=("deno")     ; ITEM_LABEL["deno"]="🦕  Deno"                           ; ITEM_CATEGORY["deno"]="Languages"
ITEM_KEYS+=("cpp")      ; ITEM_LABEL["cpp"]="💻  C / C++ (GCC + G++ + CMake)"     ; ITEM_CATEGORY["cpp"]="Languages"
ITEM_KEYS+=("conda")    ; ITEM_LABEL["conda"]="🐍  Conda (Miniconda)"             ; ITEM_CATEGORY["conda"]="Languages"
ITEM_KEYS+=("flutter")  ; ITEM_LABEL["flutter"]="📱  Flutter + Dart"              ; ITEM_CATEGORY["flutter"]="Languages"

# Databases
ITEM_KEYS+=("mysql")    ; ITEM_LABEL["mysql"]="🗄️   MariaDB (MySQL-compatible)"      ; ITEM_CATEGORY["mysql"]="Databases"
ITEM_KEYS+=("postgres") ; ITEM_LABEL["postgres"]="🐘  PostgreSQL"                 ; ITEM_CATEGORY["postgres"]="Databases"
ITEM_KEYS+=("mongodb")  ; ITEM_LABEL["mongodb"]="🍃  MongoDB"                     ; ITEM_CATEGORY["mongodb"]="Databases"
ITEM_KEYS+=("redis")    ; ITEM_LABEL["redis"]="📦  Redis"                         ; ITEM_CATEGORY["redis"]="Databases"

# DevOps & Cloud
ITEM_KEYS+=("docker")   ; ITEM_LABEL["docker"]="🐳  Docker + Docker Compose"      ; ITEM_CATEGORY["docker"]="DevOps & Cloud"
ITEM_KEYS+=("kubectl")  ; ITEM_LABEL["kubectl"]="🐋  Kubernetes (kubectl)"        ; ITEM_CATEGORY["kubectl"]="DevOps & Cloud"
ITEM_KEYS+=("awscli")   ; ITEM_LABEL["awscli"]="☁️   AWS CLI"                     ; ITEM_CATEGORY["awscli"]="DevOps & Cloud"
ITEM_KEYS+=("firebase") ; ITEM_LABEL["firebase"]="🔥  Firebase CLI"               ; ITEM_CATEGORY["firebase"]="DevOps & Cloud"
ITEM_KEYS+=("nginx")    ; ITEM_LABEL["nginx"]="🌐  Nginx Web Server"              ; ITEM_CATEGORY["nginx"]="DevOps & Cloud"

# Tools & Editors
ITEM_KEYS+=("git")      ; ITEM_LABEL["git"]="🔧  Git + GitHub CLI"                ; ITEM_CATEGORY["git"]="Tools & Editors"
ITEM_KEYS+=("vscode")   ; ITEM_LABEL["vscode"]="⚡  VS Code"                      ; ITEM_CATEGORY["vscode"]="Tools & Editors"
ITEM_KEYS+=("jupyter")  ; ITEM_LABEL["jupyter"]="📓  Jupyter Lab"                 ; ITEM_CATEGORY["jupyter"]="Tools & Editors"
ITEM_KEYS+=("android")  ; ITEM_LABEL["android"]="🤖  Android Studio (SDK tools)"  ; ITEM_CATEGORY["android"]="Tools & Editors"
ITEM_KEYS+=("rstudio")  ; ITEM_LABEL["rstudio"]="📊  RStudio"                     ; ITEM_CATEGORY["rstudio"]="Tools & Editors"
ITEM_KEYS+=("postman")  ; ITEM_LABEL["postman"]="🐙  Postman"                     ; ITEM_CATEGORY["postman"]="Tools & Editors"
ITEM_KEYS+=("openssl")  ; ITEM_LABEL["openssl"]="🔐  OpenSSL + curl + wget tools" ; ITEM_CATEGORY["openssl"]="Tools & Editors"

# Initialize all as unchecked
for key in "${ITEM_KEYS[@]}"; do
    CHECKED["$key"]=0
done

# =============================================================================
# User / privilege handling
# =============================================================================

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[✘]${RESET} Run as root: sudo bash developer.sh [username]"
    exit 1
fi

TARGET_USER="${1:-${SUDO_USER:-}}"

if [ -z "$TARGET_USER" ] || ! id "$TARGET_USER" &>/dev/null || [ "$TARGET_USER" = "root" ]; then
    echo -e "${RED}[✘]${RESET} Could not determine a non-root target user."
    echo -e "    ${WHITE}Run: sudo bash developer.sh <username>${RESET}"
    exit 1
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_UID="$(id -u "$TARGET_USER")"
TARGET_GID="$(id -g "$TARGET_USER")"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    echo -e "${RED}[✘]${RESET} Home directory for '$TARGET_USER' could not be resolved."
    exit 1
fi

run_as_user() {
    runuser -u "$TARGET_USER" -- env \
        HOME="$TARGET_HOME" \
        USER="$TARGET_USER" \
        LOGNAME="$TARGET_USER" \
        PATH="$TARGET_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
        "$@"
}

run_as_user_shell() {
    runuser -u "$TARGET_USER" -- env \
        HOME="$TARGET_HOME" \
        USER="$TARGET_USER" \
        LOGNAME="$TARGET_USER" \
        PATH="$TARGET_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
        bash -lc "$1"
}

print_step()    { echo -e "${BLUE}[*]${RESET} $1"; }
print_success() { echo -e "${GREEN}[✔]${RESET} $1"; }
print_warning() { echo -e "${YELLOW}[!]${RESET} $1"; }
print_error()   { echo -e "${RED}[✘]${RESET} $1"; }

# =============================================================================
# Installation helpers
# =============================================================================

install_pacman() {
    local packages=("$@")

    if pacman -S --noconfirm --needed "${packages[@]}"; then
        return 0
    fi

    print_error "pacman failed while installing: ${packages[*]}"
    return 1
}

require_yay() {
    if command -v yay &>/dev/null; then
        return 0
    fi

    print_error "yay is not installed. Install yay before selecting AUR-based tools."
    return 1
}

install_aur() {
    local package="$1"

    require_yay || return 1

    print_step "Installing AUR package: $package"
    if run_as_user yay -S --noconfirm --needed "$package"; then
        return 0
    fi

    print_error "AUR installation failed: $package"
    return 1
}

install_aur_verified() {
    local package="$1"

    install_aur "$package" || return 1

    if yay -Qi "$package" &>/dev/null; then
        return 0
    fi

    print_error "AUR package '$package' is not installed after yay completed."
    return 1
}

service_available() {
    systemctl cat "$1" &>/dev/null
}

enable_service() {
    local service="$1"

    if ! service_available "$service"; then
        print_error "Service '$service' does not exist."
        return 1
    fi

    if ! systemctl enable "$service"; then
        print_error "Failed to enable $service."
        return 1
    fi

    # systemctl start cannot actually start a service from a non-booted chroot.
    if [ -d /run/systemd/system ]; then
        if ! systemctl start "$service"; then
            print_error "Failed to start $service."
            return 1
        fi

        if ! systemctl is-active --quiet "$service"; then
            print_error "$service is enabled but not active."
            return 1
        fi
    else
        print_warning "Systemd is not currently running; $service is enabled and will start on next boot."
    fi

    return 0
}

verify_command() {
    local command_name="$1"
    local label="$2"

    if command -v "$command_name" &>/dev/null; then
        print_success "$label verified: $(command -v "$command_name")"
        return 0
    fi

    print_error "$label was not found after installation."
    return 1
}

# =============================================================================
# TUI — Text-based interactive checkbox list
# =============================================================================

CURSOR=0
SCROLL=0
VISIBLE_LINES=15

draw_ui() {
    clear
    echo -e "${MAUVE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║          PRO Linux — Developer Environment Setup            ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${DIM}Navigate: ↑↓ arrows  |  Select: Space  |  Confirm: Enter  |  Quit: Q${RESET}"
    echo -e "  ${DIM}Select All in category: A  |  Deselect All: D${RESET}"
    echo ""

    local total=${#ITEM_KEYS[@]}
    local end=$((SCROLL + VISIBLE_LINES))
    if [ "$end" -gt "$total" ]; then end=$total; fi

    local prev_category=""
    local checkbox

    for ((i=SCROLL; i<end; i++)); do
        local key="${ITEM_KEYS[$i]}"
        local label="${ITEM_LABEL[$key]}"
        local category="${ITEM_CATEGORY[$key]}"

        if [ "$category" != "$prev_category" ]; then
            if [ "$i" -ne "$SCROLL" ]; then
                echo ""
            fi
            echo -e "  ${CYAN}${BOLD}── $category ──────────────────────────────────${RESET}"
            prev_category="$category"
        fi

        if [ "${CHECKED[$key]}" -eq 1 ]; then
            checkbox="${GREEN}${BOLD}[✔]${RESET}"
        else
            checkbox="${WHITE}[ ]${RESET}"
        fi

        if [ "$i" -eq "$CURSOR" ]; then
            echo -e "  ${MAUVE}${BOLD}▶ $checkbox ${BOLD}$label${RESET}"
        else
            echo -e "    $checkbox ${WHITE}$label${RESET}"
        fi
    done

    echo ""

    local checked_count=0
    for key in "${ITEM_KEYS[@]}"; do
        [ "${CHECKED[$key]}" -eq 1 ] && ((checked_count += 1))
    done

    echo -e "  ${DIM}Showing $((SCROLL+1))-$end of $total items${RESET}  ${GREEN}${BOLD}$checked_count selected${RESET}"
    echo ""
}

run_tui() {
    tput civis 2>/dev/null || true
    trap 'tput cnorm 2>/dev/null || true; clear' EXIT

    while true; do
        draw_ui
        IFS= read -rsn1 key

        case "$key" in
            $'\x1b')
                IFS= read -rsn2 rest
                case "$rest" in
                    '[A')
                        if [ "$CURSOR" -gt 0 ]; then
                            ((CURSOR -= 1))
                            if [ "$CURSOR" -lt "$SCROLL" ]; then
                                ((SCROLL -= 1))
                            fi
                        fi
                        ;;
                    '[B')
                        if [ "$CURSOR" -lt $((${#ITEM_KEYS[@]}-1)) ]; then
                            ((CURSOR += 1))
                            if [ "$CURSOR" -ge $((SCROLL + VISIBLE_LINES)) ]; then
                                ((SCROLL += 1))
                            fi
                        fi
                        ;;
                esac
                ;;
            ' ')
                local key_at_cursor="${ITEM_KEYS[$CURSOR]}"
                if [ "${CHECKED[$key_at_cursor]}" -eq 1 ]; then
                    CHECKED["$key_at_cursor"]=0
                else
                    CHECKED["$key_at_cursor"]=1
                fi
                ;;
            'a'|'A')
                local cur_cat="${ITEM_CATEGORY[${ITEM_KEYS[$CURSOR]}]}"
                for k in "${ITEM_KEYS[@]}"; do
                    [ "${ITEM_CATEGORY[$k]}" = "$cur_cat" ] && CHECKED["$k"]=1
                done
                ;;
            'd'|'D')
                local cur_cat="${ITEM_CATEGORY[${ITEM_KEYS[$CURSOR]}]}"
                for k in "${ITEM_KEYS[@]}"; do
                    [ "${ITEM_CATEGORY[$k]}" = "$cur_cat" ] && CHECKED["$k"]=0
                done
                ;;
            'q'|'Q')
                tput cnorm 2>/dev/null || true
                clear
                echo -e "${YELLOW}Installation cancelled.${RESET}"
                exit 0
                ;;
            '')
                tput cnorm 2>/dev/null || true
                break
                ;;
        esac
    done

    trap - EXIT
    tput cnorm 2>/dev/null || true
}

# =============================================================================
# Installation functions — one per tool
# =============================================================================

install_python() {
    print_step "Installing Python 3 + pip + venv..."
    install_pacman python python-pip python-virtualenv || return 1
    verify_command python "Python" || return 1
    verify_command pip "pip" || return 1
    print_success "Python installed. $(python --version)"
}

install_java() {
    print_step "Installing Java JDK 17..."
    install_pacman jdk17-openjdk || return 1
    archlinux-java set java-17-openjdk || true
    java_version="$(java -version 2>&1 | head -1)"
    [ -n "$java_version" ] || return 1
    print_success "Java installed. $java_version"
}

install_node() {
    print_step "Installing Node.js + npm..."
    install_pacman nodejs npm || return 1
    verify_command node "Node.js" || return 1
    verify_command npm "npm" || return 1
    print_success "Node installed. $(node --version)"
}

install_rust() {
    print_step "Installing Rust + Cargo..."
    install_pacman rust || return 1
    verify_command rustc "Rust" || return 1
    verify_command cargo "Cargo" || return 1
    print_success "Rust installed. $(rustc --version)"
}

install_go() {
    print_step "Installing Go..."
    install_pacman go || return 1
    verify_command go "Go" || return 1
    print_success "Go installed. $(go version)"
}

install_ruby() {
    print_step "Installing Ruby + gem..."
    install_pacman ruby || return 1
    verify_command ruby "Ruby" || return 1
    verify_command gem "RubyGems" || return 1
    print_success "Ruby installed. $(ruby --version)"
}

install_php() {
    print_step "Installing PHP + Composer..."
    install_pacman php composer || return 1
    verify_command php "PHP" || return 1
    verify_command composer "Composer" || return 1
    print_success "PHP installed. $(php --version | head -1)"
}

install_kotlin() {
    print_step "Installing Kotlin..."
    install_pacman kotlin || return 1
    verify_command kotlinc "Kotlin compiler" || return 1
    print_success "Kotlin installed."
}

install_scala() {
    print_step "Installing Scala + SBT..."
    install_pacman scala sbt || return 1
    verify_command scala "Scala" || return 1
    verify_command sbt "SBT" || return 1
    print_success "Scala installed."
}

install_swift() {
    print_step "Installing Swift from AUR..."
    install_aur_verified swift-bin || return 1
    verify_command swift "Swift" || return 1
    print_success "Swift installed."
}

install_r() {
    print_step "Installing R..."
    install_pacman r || return 1
    verify_command R "R" || return 1
    print_success "R installed."
}

install_deno() {
    print_step "Installing Deno..."
    install_pacman deno || return 1
    verify_command deno "Deno" || return 1
    print_success "Deno installed. $(deno --version | head -1)"
}

install_cpp() {
    print_step "Installing C/C++ tools..."
    # Arch's gcc package already provides gcc, g++, and c++.
    install_pacman gcc cmake make gdb || return 1
    verify_command gcc "GCC" || return 1
    verify_command g++ "G++" || return 1
    verify_command cmake "CMake" || return 1
    print_success "C/C++ toolchain installed. $(gcc --version | head -1)"
}

install_conda() {
    print_step "Installing Miniconda from AUR..."
    install_aur_verified miniconda3 || return 1

    # Miniconda's package is system-wide; initialize it for the target user.
    local conda_bin=""
    conda_bin="$(pacman -Ql miniconda3 2>/dev/null | awk '$2 ~ /\/bin\/conda$/ {print $2; exit}')"
    if [ -z "$conda_bin" ] || [ ! -x "$conda_bin" ]; then
        if [ -x /opt/miniconda3/bin/conda ]; then
            conda_bin="/opt/miniconda3/bin/conda"
        else
            print_error "Miniconda was installed but the conda executable could not be located."
            return 1
        fi
    fi

    if ! run_as_user_shell "'$conda_bin' init bash && '$conda_bin' init zsh"; then
        print_error "Failed to initialize Conda for $TARGET_USER."
        return 1
    fi

    print_success "Miniconda installed and initialized for $TARGET_USER."
}

install_flutter() {
    print_step "Installing Flutter + Dart from AUR..."
    install_pacman dart || return 1
    install_aur_verified flutter || return 1
    verify_command flutter "Flutter" || return 1
    verify_command dart "Dart" || return 1
    print_success "Flutter installed."
}

install_mysql() {
    print_step "Installing MariaDB (MySQL-compatible server)..."
    install_pacman mariadb || return 1

    if [ ! -f /var/lib/mysql/mysql/user.frm ] && [ ! -d /var/lib/mysql/mysql ]; then
        if ! mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql; then
            print_error "MariaDB database initialization failed."
            return 1
        fi
    fi

    enable_service mariadb.service || return 1
    verify_command mariadb "MariaDB client" || return 1
    print_success "MariaDB installed and configured."
}

install_postgres() {
    print_step "Installing PostgreSQL..."
    install_pacman postgresql || return 1

    mkdir -p /var/lib/postgres/data
    chown postgres:postgres /var/lib/postgres/data

    if [ ! -f /var/lib/postgres/data/PG_VERSION ]; then
        print_step "Initializing PostgreSQL database cluster..."
        if ! runuser -u postgres -- initdb -D /var/lib/postgres/data; then
            print_error "PostgreSQL initdb failed."
            return 1
        fi
    else
        print_success "PostgreSQL database cluster already initialized."
    fi

    enable_service postgresql.service || return 1

    if [ -x /usr/bin/pg_isready ] && [ -d /run/systemd/system ]; then
        if ! pg_isready -q; then
            print_error "PostgreSQL service is active but pg_isready failed."
            return 1
        fi
    fi

    verify_command psql "PostgreSQL client" || return 1
    print_success "PostgreSQL installed and configured."
}

install_mongodb() {
    print_step "Installing MongoDB from AUR..."
    install_aur_verified mongodb-bin || return 1

    enable_service mongodb.service || return 1

    if command -v mongosh >/dev/null 2>&1; then
        print_success "MongoDB shell verified."
    else
        print_warning "mongosh is not provided by this MongoDB package; install a MongoDB shell package separately if needed."
    fi
    verify_command mongod "MongoDB server" || return 1
    print_success "MongoDB installed and configured."
}

install_redis() {
    print_step "Installing Redis..."
    install_pacman redis || return 1
    enable_service redis.service || return 1
    verify_command redis-cli "Redis client" || return 1
    print_success "Redis installed and started."
}

install_docker() {
    print_step "Installing Docker + Docker Compose..."
    install_pacman docker docker-compose || return 1
    enable_service docker.service || return 1

    if ! getent group docker &>/dev/null; then
        groupadd docker || return 1
    fi

    usermod -aG docker "$TARGET_USER" || return 1
    verify_command docker "Docker" || return 1
    verify_command docker-compose "Docker Compose" || return 1
    print_success "Docker installed. '$TARGET_USER' was added to the docker group; re-login is required."
}

install_kubectl() {
    print_step "Installing kubectl..."
    install_pacman kubectl || return 1
    verify_command kubectl "kubectl" || return 1
    print_success "kubectl installed. $(kubectl version --client 2>/dev/null | head -1)"
}

install_awscli() {
    print_step "Installing AWS CLI..."
    install_pacman aws-cli || return 1
    verify_command aws "AWS CLI" || return 1
    print_success "AWS CLI installed. $(aws --version)"
}

install_firebase() {
    print_step "Installing Firebase CLI..."

    # Firebase CLI is distributed through npm. Install it for the user rather
    # than using root's global npm prefix.
    install_pacman nodejs npm || return 1
    mkdir -p "$TARGET_HOME/.local/bin"
    chown -R "$TARGET_UID:$TARGET_GID" "$TARGET_HOME/.local"

    if ! run_as_user_shell 'npm_config_prefix="$HOME/.local" npm install -g firebase-tools'; then
        print_error "Firebase CLI installation failed."
        return 1
    fi

    if [ -x "$TARGET_HOME/.local/bin/firebase" ]; then
        ln -sf "$TARGET_HOME/.local/bin/firebase" /usr/local/bin/firebase
    fi

    verify_command firebase "Firebase CLI" || return 1
    print_success "Firebase CLI installed for $TARGET_USER."
}

install_nginx() {
    print_step "Installing Nginx..."
    install_pacman nginx || return 1
    enable_service nginx.service || return 1
    verify_command nginx "Nginx" || return 1
    print_success "Nginx installed and started."
}

install_git() {
    print_step "Installing Git + GitHub CLI..."
    install_pacman git github-cli || return 1
    verify_command git "Git" || return 1
    verify_command gh "GitHub CLI" || return 1
    print_success "Git installed. $(git --version)"
}

install_vscode() {
    print_step "Installing VS Code from AUR..."
    install_aur_verified visual-studio-code-bin || return 1
    verify_command code "VS Code" || return 1
    print_success "VS Code installed."
}

install_jupyter() {
    print_step "Installing Jupyter Lab from Arch packages..."
    # Do not use pip against Arch's system Python.
    install_pacman jupyterlab || return 1
    verify_command jupyter-lab "Jupyter Lab" || return 1
    print_success "Jupyter Lab installed."
}

install_android() {
    print_step "Installing Android Studio + Android platform tools..."
    install_pacman android-tools android-udev || return 1
    install_aur_verified android-studio || return 1
    verify_command adb "Android Debug Bridge" || return 1
    verify_command fastboot "Fastboot" || return 1
    print_success "Android Studio and platform tools installed."
}

install_rstudio() {
    print_step "Installing RStudio from AUR..."
    install_aur_verified rstudio-desktop-bin || return 1
    print_success "RStudio installed."
}

install_postman() {
    print_step "Installing Postman from AUR..."
    install_aur_verified postman-bin || return 1
    print_success "Postman installed."
}

install_openssl() {
    print_step "Installing OpenSSL + curl + wget tools..."
    install_pacman openssl curl wget || return 1
    verify_command openssl "OpenSSL" || return 1
    verify_command curl "curl" || return 1
    verify_command wget "wget" || return 1
    print_success "Security/network tools installed."
}

# =============================================================================
# Run selected installations
# =============================================================================

run_installations() {
    clear
    echo -e "${MAUVE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║              Installing Selected Tools...                   ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo ""

    local selected=()
    for key in "${ITEM_KEYS[@]}"; do
        [ "${CHECKED[$key]}" -eq 1 ] && selected+=("$key")
    done

    if [ "${#selected[@]}" -eq 0 ]; then
        echo -e "${YELLOW}No tools selected. Exiting.${RESET}"
        return 0
    fi

    echo -e "  ${CYAN}Target user: ${BOLD}$TARGET_USER${RESET}"
    echo -e "  ${CYAN}Installing ${#selected[@]} selected tools...${RESET}"
    echo ""

    local success=0
    local failed=0
    local failed_list=()

    for key in "${selected[@]}"; do
        echo -e "${MAUVE}${BOLD}━━ ${ITEM_LABEL[$key]} ━━${RESET}"

        if declare -F "install_$key" >/dev/null; then
            if "install_$key"; then
                ((success += 1))
            else
                ((failed += 1))
                failed_list+=("${ITEM_LABEL[$key]}")
            fi
        else
            print_error "No installer found for: $key"
            ((failed += 1))
            failed_list+=("${ITEM_LABEL[$key]}")
        fi

        echo ""
    done

    echo ""
    echo -e "${MAUVE}${BOLD}  ══════════════════════════════════════════${RESET}"
    echo -e "  ${GREEN}${BOLD}[✔] Successfully completed: $success${RESET}"

    if [ "$failed" -gt 0 ]; then
        echo -e "  ${RED}${BOLD}[✘] Failed: $failed${RESET}"
        for item in "${failed_list[@]}"; do
            echo -e "    ${RED}- $item${RESET}"
        done
    fi

    echo -e "${MAUVE}${BOLD}  ══════════════════════════════════════════${RESET}"
    echo ""

    if [ "$failed" -eq 0 ]; then
        echo -e "  ${GREEN}${BOLD}Developer environment setup completed successfully.${RESET}"
    else
        echo -e "  ${YELLOW}${BOLD}Setup completed with failures. Read the errors above and rerun the failed selections.${RESET}"
    fi
    echo ""

    return 0
}

# =============================================================================
# Main
# =============================================================================

printf '\n'
echo -e "${MAUVE}${BOLD}PRO Linux — Developer Environment Setup${RESET}"
echo -e "${DIM}Target user: ${TARGET_USER}${RESET}"
printf '\n'

run_tui
run_installations
