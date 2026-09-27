#!/bin/bash

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

LOG_FILE="$HOME/devinstall_log.txt"
echo "Install log - $(date)" > "$LOG_FILE"

INSTALLED=()
FAILED=()
SKIPPED=()

# ─── Header ───
clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║         🚀  DEV ENVIRONMENT INSTALLER               ║"
echo "  ║         One Command — Everything You Need            ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BLUE}👤 User     :${NC} $(whoami)"
echo -e "  ${BLUE}🖥️  System   :${NC} $(lsb_release -ds 2>/dev/null || uname -s)"
echo -e "  ${BLUE}📅 Date     :${NC} $(date '+%d %b %Y, %I:%M %p')"
echo -e "  ${BLUE}📁 Log file :${NC} $LOG_FILE"
echo ""
echo -e "  ${YELLOW}💡 Use SPACE to select/deselect, ENTER to confirm${NC}"
echo -e "  ${YELLOW}   Or type numbers separated by space (e.g: 1 3 5 7)${NC}"
echo ""
echo -e "  ${CYAN}${BOLD}══════════════════════════════════════════════════════${NC}"

# ─── All available tools ───
declare -A TOOL_DESC=(
  [1]="🐍  Python 3 + pip + venv"
  [2]="☕  Java JDK 17 (OpenJDK)"
  [3]="🟩  Node.js + npm"
  [4]="🐳  Docker + Docker Compose"
  [5]="🦀  Rust + Cargo"
  [6]="🐹  Go (Golang)"
  [7]="💎  Ruby + gem"
  [8]="🐘  PHP + Composer"
  [9]="🗄️   MySQL Server"
  [10]="🐘  PostgreSQL"
  [11]="🍃  MongoDB"
  [12]="📦  Redis"
  [13]="🔧  Git + GitHub CLI"
  [14]="🐋  Kubernetes (kubectl)"
  [15]="⚡  VS Code"
  [16]="📓  Jupyter Lab"
  [17]="🤖  Android Studio (SDK tools)"
  [18]="🌐  Nginx Web Server"
  [19]="🔥  Firebase CLI"
  [20]="☁️   AWS CLI"
  [21]="🐍  Conda (Miniconda)"
  [22]="📱  Flutter + Dart"
  [23]="🦕  Deno"
  [24]="💻  C / C++ (GCC + G++ + CMake)"
  [25]="🔷  Kotlin"
  [26]="🍺  Scala + SBT"
  [27]="🎯  Swift (via Snap)"
  [28]="📊  R + RStudio"
  [29]="🐙  Postman"
  [30]="🔐  OpenSSL + curl + wget tools"
)

# ─── Categories ───
echo ""
echo -e "  ${CYAN}${BOLD}  ── 🖥️  LANGUAGES ──────────────────────────────────${NC}"
echo -e "  ${GREEN}  1 )${NC}  ${TOOL_DESC[1]}"
echo -e "  ${GREEN}  2 )${NC}  ${TOOL_DESC[2]}"
echo -e "  ${GREEN}  3 )${NC}  ${TOOL_DESC[3]}"
echo -e "  ${GREEN}  5 )${NC}  ${TOOL_DESC[5]}"
echo -e "  ${GREEN}  6 )${NC}  ${TOOL_DESC[6]}"
echo -e "  ${GREEN}  7 )${NC}  ${TOOL_DESC[7]}"
echo -e "  ${GREEN}  8 )${NC}  ${TOOL_DESC[8]}"
echo -e "  ${GREEN} 24 )${NC}  ${TOOL_DESC[24]}"
echo -e "  ${GREEN} 25 )${NC}  ${TOOL_DESC[25]}"
echo -e "  ${GREEN} 26 )${NC}  ${TOOL_DESC[26]}"
echo -e "  ${GREEN} 27 )${NC}  ${TOOL_DESC[27]}"
echo -e "  ${GREEN} 28 )${NC}  ${TOOL_DESC[28]}"
echo -e "  ${GREEN} 23 )${NC}  ${TOOL_DESC[23]}"
echo ""
echo -e "  ${CYAN}${BOLD}  ── 🗄️  DATABASES ──────────────────────────────────${NC}"
echo -e "  ${YELLOW}  9 )${NC}  ${TOOL_DESC[9]}"
echo -e "  ${YELLOW} 10 )${NC}  ${TOOL_DESC[10]}"
echo -e "  ${YELLOW} 11 )${NC}  ${TOOL_DESC[11]}"
echo -e "  ${YELLOW} 12 )${NC}  ${TOOL_DESC[12]}"
echo ""
echo -e "  ${CYAN}${BOLD}  ── 🛠️  DEV TOOLS ──────────────────────────────────${NC}"
echo -e "  ${MAGENTA} 13 )${NC}  ${TOOL_DESC[13]}"
echo -e "  ${MAGENTA} 14 )${NC}  ${TOOL_DESC[14]}"
echo -e "  ${MAGENTA} 15 )${NC}  ${TOOL_DESC[15]}"
echo -e "  ${MAGENTA} 16 )${NC}  ${TOOL_DESC[16]}"
echo -e "  ${MAGENTA} 17 )${NC}  ${TOOL_DESC[17]}"
echo -e "  ${MAGENTA} 22 )${NC}  ${TOOL_DESC[22]}"
echo -e "  ${MAGENTA} 29 )${NC}  ${TOOL_DESC[29]}"
echo ""
echo -e "  ${CYAN}${BOLD}  ── ☁️  CLOUD & INFRA ───────────────────────────────${NC}"
echo -e "  ${BLUE}  4 )${NC}  ${TOOL_DESC[4]}"
echo -e "  ${BLUE} 18 )${NC}  ${TOOL_DESC[18]}"
echo -e "  ${BLUE} 19 )${NC}  ${TOOL_DESC[19]}"
echo -e "  ${BLUE} 20 )${NC}  ${TOOL_DESC[20]}"
echo ""
echo -e "  ${CYAN}${BOLD}  ── 🧪 DATA SCIENCE & ML ───────────────────────────${NC}"
echo -e "  ${RED} 21 )${NC}  ${TOOL_DESC[21]}"
echo -e "  ${RED} 16 )${NC}  ${TOOL_DESC[16]}"
echo ""
echo -e "  ${CYAN}${BOLD}  ── 🔧 UTILITIES ────────────────────────────────────${NC}"
echo -e "  ${GREEN} 30 )${NC}  ${TOOL_DESC[30]}"
echo ""
echo -e "  ${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${BOLD}${YELLOW}  Type 'all' to install everything${NC}"
echo -e "  ${BOLD}${YELLOW}  Type numbers separated by space (e.g: 1 2 3 15)${NC}"
echo ""
echo -ne "  ${BOLD}👉 Your selection: ${NC}"
read -r RAW_INPUT

# ─── Parse selection ───
if [[ "$RAW_INPUT" == "all" ]]; then
  SELECTED=($(seq 1 30))
else
  SELECTED=($RAW_INPUT)
fi

if [ ${#SELECTED[@]} -eq 0 ]; then
  echo -e "  ${RED}❌ No selection made. Exiting.${NC}"
  exit 1
fi

# ─── Show selected ───
clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║           📋  INSTALLATION PLAN                     ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${YELLOW}The following will be installed:${NC}"
echo ""
for NUM in "${SELECTED[@]}"; do
  if [ -n "${TOOL_DESC[$NUM]}" ]; then
    echo -e "  ${GREEN}✔${NC}  ${TOOL_DESC[$NUM]}"
  fi
done
echo ""
echo -ne "  ${BOLD}${CYAN}🚀 Start installation? (yes/no): ${NC}"
read -r CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo -e "  ${RED}❌ Cancelled.${NC}"
  exit 0
fi

# ─── Update system first ───
echo ""
echo -e "  ${CYAN}${BOLD}🔄 Updating package list...${NC}"
sudo apt update -qq 2>/dev/null
echo -e "  ${GREEN}✅ System updated${NC}"
echo ""

# ─── Install functions ───

install_python() {
  echo -e "  ${CYAN}📦 Installing Python 3...${NC}"
  sudo apt install -y python3 python3-pip python3-venv python3-dev -qq
  echo -e "  ${GREEN}✅ Python $(python3 --version) installed${NC}"
  echo "Python: $(python3 --version)" >> "$LOG_FILE"
}

install_java() {
  echo -e "  ${CYAN}📦 Installing Java JDK 17...${NC}"
  sudo apt install -y openjdk-17-jdk -qq
  echo -e "  ${GREEN}✅ Java $(java -version 2>&1 | head -1) installed${NC}"
  echo "Java: $(java -version 2>&1 | head -1)" >> "$LOG_FILE"
}

install_node() {
  echo -e "  ${CYAN}📦 Installing Node.js LTS + npm...${NC}"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - -qq
  sudo apt install -y nodejs -qq
  echo -e "  ${GREEN}✅ Node $(node --version) + npm $(npm --version) installed${NC}"
  echo "Node: $(node --version)" >> "$LOG_FILE"
}

install_docker() {
  echo -e "  ${CYAN}📦 Installing Docker + Docker Compose...${NC}"
  sudo apt install -y ca-certificates curl gnupg -qq
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt update -qq
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin -qq
  sudo usermod -aG docker "$USER"
  echo -e "  ${GREEN}✅ Docker $(docker --version) installed${NC}"
  echo "Docker: $(docker --version)" >> "$LOG_FILE"
}

install_rust() {
  echo -e "  ${CYAN}📦 Installing Rust + Cargo...${NC}"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
  source "$HOME/.cargo/env"
  echo -e "  ${GREEN}✅ Rust $(rustc --version) installed${NC}"
  echo "Rust: $(rustc --version)" >> "$LOG_FILE"
}

install_go() {
  echo -e "  ${CYAN}📦 Installing Go...${NC}"
  GO_VERSION="1.22.0"
  wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
  export PATH=$PATH:/usr/local/go/bin
  echo -e "  ${GREEN}✅ Go $(go version) installed${NC}"
  echo "Go: $(go version)" >> "$LOG_FILE"
}

install_ruby() {
  echo -e "  ${CYAN}📦 Installing Ruby + gem...${NC}"
  sudo apt install -y ruby-full -qq
  echo -e "  ${GREEN}✅ Ruby $(ruby --version) installed${NC}"
  echo "Ruby: $(ruby --version)" >> "$LOG_FILE"
}

install_php() {
  echo -e "  ${CYAN}📦 Installing PHP + Composer...${NC}"
  sudo apt install -y php php-cli php-mbstring unzip -qq
  curl -sS https://getcomposer.org/installer | php -- --quiet
  sudo mv composer.phar /usr/local/bin/composer
  echo -e "  ${GREEN}✅ PHP $(php --version | head -1) installed${NC}"
  echo "PHP: $(php --version | head -1)" >> "$LOG_FILE"
}

install_mysql() {
  echo -e "  ${CYAN}📦 Installing MySQL...${NC}"
  sudo apt install -y mysql-server -qq
  echo -e "  ${GREEN}✅ MySQL installed${NC}"
  echo "MySQL: installed" >> "$LOG_FILE"
}

install_postgresql() {
  echo -e "  ${CYAN}📦 Installing PostgreSQL...${NC}"
  sudo apt install -y postgresql postgresql-contrib -qq
  echo -e "  ${GREEN}✅ PostgreSQL installed${NC}"
  echo "PostgreSQL: installed" >> "$LOG_FILE"
}

install_mongodb() {
  echo -e "  ${CYAN}📦 Installing MongoDB...${NC}"
  curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg 2>/dev/null
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list > /dev/null
  sudo apt update -qq
  sudo apt install -y mongodb-org -qq
  echo -e "  ${GREEN}✅ MongoDB installed${NC}"
  echo "MongoDB: installed" >> "$LOG_FILE"
}

install_redis() {
  echo -e "  ${CYAN}📦 Installing Redis...${NC}"
  sudo apt install -y redis-server -qq
  echo -e "  ${GREEN}✅ Redis $(redis-server --version) installed${NC}"
  echo "Redis: $(redis-server --version)" >> "$LOG_FILE"
}

install_git() {
  echo -e "  ${CYAN}📦 Installing Git + GitHub CLI...${NC}"
  sudo apt install -y git -qq
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update -qq && sudo apt install -y gh -qq
  echo -e "  ${GREEN}✅ Git $(git --version) + GitHub CLI installed${NC}"
  echo "Git: $(git --version)" >> "$LOG_FILE"
}

install_kubectl() {
  echo -e "  ${CYAN}📦 Installing kubectl...${NC}"
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl
  echo -e "  ${GREEN}✅ kubectl $(kubectl version --client --short 2>/dev/null) installed${NC}"
  echo "kubectl: installed" >> "$LOG_FILE"
}

install_vscode() {
  echo -e "  ${CYAN}📦 Installing VS Code...${NC}"
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor > /tmp/packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg \
    /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  sudo apt update -qq && sudo apt install -y code -qq
  echo -e "  ${GREEN}✅ VS Code installed${NC}"
  echo "VSCode: installed" >> "$LOG_FILE"
}

install_jupyter() {
  echo -e "  ${CYAN}📦 Installing Jupyter Lab...${NC}"
  pip3 install jupyterlab -q
  echo -e "  ${GREEN}✅ Jupyter Lab installed${NC}"
  echo "JupyterLab: installed" >> "$LOG_FILE"
}

install_android() {
  echo -e "  ${CYAN}📦 Installing Android SDK tools...${NC}"
  sudo apt install -y android-tools-adb android-tools-fastboot -qq
  echo -e "  ${GREEN}✅ Android tools installed${NC}"
  echo "Android tools: installed" >> "$LOG_FILE"
}

install_nginx() {
  echo -e "  ${CYAN}📦 Installing Nginx...${NC}"
  sudo apt install -y nginx -qq
  echo -e "  ${GREEN}✅ Nginx $(nginx -v 2>&1) installed${NC}"
  echo "Nginx: installed" >> "$LOG_FILE"
}

install_firebase() {
  echo -e "  ${CYAN}📦 Installing Firebase CLI...${NC}"
  npm install -g firebase-tools -q
  echo -e "  ${GREEN}✅ Firebase CLI installed${NC}"
  echo "Firebase: installed" >> "$LOG_FILE"
}

install_awscli() {
  echo -e "  ${CYAN}📦 Installing AWS CLI...${NC}"
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp/
  sudo /tmp/aws/install
  echo -e "  ${GREEN}✅ AWS CLI $(aws --version) installed${NC}"
  echo "AWS CLI: $(aws --version)" >> "$LOG_FILE"
}

install_conda() {
  echo -e "  ${CYAN}📦 Installing Miniconda...${NC}"
  wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -O /tmp/miniconda.sh
  bash /tmp/miniconda.sh -b -p "$HOME/miniconda3"
  "$HOME/miniconda3/bin/conda" init bash
  echo -e "  ${GREEN}✅ Miniconda installed${NC}"
  echo "Conda: installed" >> "$LOG_FILE"
}

install_flutter() {
  echo -e "  ${CYAN}📦 Installing Flutter + Dart...${NC}"
  sudo snap install flutter --classic
  flutter --version &>/dev/null
  echo -e "  ${GREEN}✅ Flutter installed${NC}"
  echo "Flutter: installed" >> "$LOG_FILE"
}

install_deno() {
  echo -e "  ${CYAN}📦 Installing Deno...${NC}"
  curl -fsSL https://deno.land/install.sh | sh -s -- --quiet
  echo 'export PATH="$HOME/.deno/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.deno/bin:$PATH"
  echo -e "  ${GREEN}✅ Deno installed${NC}"
  echo "Deno: installed" >> "$LOG_FILE"
}

install_cpp() {
  echo -e "  ${CYAN}📦 Installing C/C++ + CMake...${NC}"
  sudo apt install -y gcc g++ cmake build-essential -qq
  echo -e "  ${GREEN}✅ GCC $(gcc --version | head -1) installed${NC}"
  echo "GCC: $(gcc --version | head -1)" >> "$LOG_FILE"
}

install_kotlin() {
  echo -e "  ${CYAN}📦 Installing Kotlin...${NC}"
  sudo snap install kotlin --classic
  echo -e "  ${GREEN}✅ Kotlin installed${NC}"
  echo "Kotlin: installed" >> "$LOG_FILE"
}

install_scala() {
  echo -e "  ${CYAN}📦 Installing Scala + SBT...${NC}"
  sudo apt install -y scala -qq
  echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | \
    sudo tee /etc/apt/sources.list.d/sbt.list > /dev/null
  curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | \
    sudo apt-key add - &>/dev/null
  sudo apt update -qq && sudo apt install -y sbt -qq
  echo -e "  ${GREEN}✅ Scala + SBT installed${NC}"
  echo "Scala: installed" >> "$LOG_FILE"
}

install_swift() {
  echo -e "  ${CYAN}📦 Installing Swift via Snap...${NC}"
  sudo snap install swift --classic
  echo -e "  ${GREEN}✅ Swift installed${NC}"
  echo "Swift: installed" >> "$LOG_FILE"
}

install_r() {
  echo -e "  ${CYAN}📦 Installing R...${NC}"
  sudo apt install -y r-base -qq
  echo -e "  ${GREEN}✅ R $(R --version | head -1) installed${NC}"
  echo "R: $(R --version | head -1)" >> "$LOG_FILE"
}

install_postman() {
  echo -e "  ${CYAN}📦 Installing Postman...${NC}"
  sudo snap install postman
  echo -e "  ${GREEN}✅ Postman installed${NC}"
  echo "Postman: installed" >> "$LOG_FILE"
}

install_utils() {
  echo -e "  ${CYAN}📦 Installing OpenSSL + curl + wget + unzip...${NC}"
  sudo apt install -y openssl curl wget unzip zip htop tree net-tools -qq
  echo -e "  ${GREEN}✅ Utilities installed${NC}"
  echo "Utils: installed" >> "$LOG_FILE"
}

# ─── Run selected installs ───
run_install() {
  NUM=$1
  TOOL="${TOOL_DESC[$NUM]}"
  echo ""
  echo -e "  ${CYAN}${BOLD}────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}Installing: $TOOL${NC}"
  echo -e "  ${CYAN}────────────────────────────────────────${NC}"

  case $NUM in
    1)  install_python  ;;
    2)  install_java    ;;
    3)  install_node    ;;
    4)  install_docker  ;;
    5)  install_rust    ;;
    6)  install_go      ;;
    7)  install_ruby    ;;
    8)  install_php     ;;
    9)  install_mysql   ;;
    10) install_postgresql ;;
    11) install_mongodb ;;
    12) install_redis   ;;
    13) install_git     ;;
    14) install_kubectl ;;
    15) install_vscode  ;;
    16) install_jupyter ;;
    17) install_android ;;
    18) install_nginx   ;;
    19) install_firebase ;;
    20) install_awscli  ;;
    21) install_conda   ;;
    22) install_flutter ;;
    23) install_deno    ;;
    24) install_cpp     ;;
    25) install_kotlin  ;;
    26) install_scala   ;;
    27) install_swift   ;;
    28) install_r       ;;
    29) install_postman ;;
    30) install_utils   ;;
    *)  echo -e "  ${YELLOW}⚠️  Unknown option: $NUM — skipping${NC}" ;;
  esac

  if [ $? -eq 0 ]; then
    INSTALLED+=("$TOOL")
  else
    FAILED+=("$TOOL")
  fi
}

for NUM in "${SELECTED[@]}"; do
  run_install "$NUM"
done

# ─── Final Summary ───
clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║              🎉  INSTALLATION COMPLETE!             ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

if [ ${#INSTALLED[@]} -gt 0 ]; then
  echo -e "  ${GREEN}${BOLD}✅ Successfully Installed (${#INSTALLED[@]}):${NC}"
  for ITEM in "${INSTALLED[@]}"; do
    echo -e "  ${GREEN}  ✔  $ITEM${NC}"
  done
fi

echo ""

if [ ${#FAILED[@]} -gt 0 ]; then
  echo -e "  ${RED}${BOLD}❌ Failed (${#FAILED[@]}):${NC}"
  for ITEM in "${FAILED[@]}"; do
    echo -e "  ${RED}  ✘  $ITEM${NC}"
  done
fi

echo ""
echo -e "  ${BLUE}📁 Full log saved to:${NC} $LOG_FILE"
echo ""
echo -e "  ${YELLOW}${BOLD}💡 Important Notes:${NC}"
echo -e "  ${YELLOW}  • Run ${BOLD}source ~/.bashrc${NC}${YELLOW} to apply PATH changes${NC}"
echo -e "  ${YELLOW}  • Docker requires ${BOLD}logout + login${NC}${YELLOW} to use without sudo${NC}"
echo -e "  ${YELLOW}  • Conda requires ${BOLD}restart terminal${NC}${YELLOW} to activate${NC}"
echo ""
echo -e "  ${CYAN}${BOLD}  Happy Coding, developer! 🚀${NC}"
echo ""
