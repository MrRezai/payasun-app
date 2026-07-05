#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
#  Payasun Marketplace — Ubuntu Server Setup Script
#  Version: 1.0.0
#
#  This script automates the deployment of the Payasun NestJS backend
#  on a clean Ubuntu server (20.04 / 22.04 / 24.04 LTS).
#
#  Features:
#    ✦ Prerequisite detection & installation (curl, git, Node.js v20+,
#      npm, PostgreSQL)
#    ✦ Interactive .env configuration generator
#    ✦ PostgreSQL database bootstrap
#    ✦ Backend build & PM2 process manager setup
#
#  Usage:
#    chmod +x setup.sh && ./setup.sh
#
#  Requirements:
#    - Ubuntu 20.04+ (sudo access required for package installation)
#    - Internet connectivity for downloading packages
# ══════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}/backend"
ENV_FILE="${BACKEND_DIR}/.env"
REQUIRED_NODE_MAJOR=20

# ─── Color Codes ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─── Output Helpers ───────────────────────────────────────────────────
info()    { echo -e "${CYAN}ℹ ${NC} $1"; }
success() { echo -e "${GREEN}✔ ${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠ ${NC} $1"; }
error()   { echo -e "${RED}✖ ${NC} $1"; }
step()    { echo -e "\n${MAGENTA}${BOLD}━━━ $1 ━━━${NC}\n"; }
divider() { echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"; }

# ─── Ask for user confirmation ────────────────────────────────────────
confirm() {
    local prompt="$1"
    local response
    while true; do
        echo -en "${YELLOW}? ${NC} ${prompt} [y/n]: "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            [nN]|[nN][oO])     return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

# ─── Prompt for input with a default value ────────────────────────────
prompt_input() {
    local label="$1"
    local default="$2"
    local varname="$3"
    local input

    if [ -n "$default" ]; then
        echo -en "${CYAN}? ${NC} ${label} ${BLUE}[${default}]${NC}: "
    else
        echo -en "${CYAN}? ${NC} ${label}: "
    fi
    read -r input
    eval "$varname=\"${input:-$default}\""
}

# ─── Prompt for sensitive input (hidden) ──────────────────────────────
prompt_secret() {
    local label="$1"
    local default="$2"
    local varname="$3"
    local input

    if [ -n "$default" ]; then
        echo -en "${CYAN}? ${NC} ${label} ${BLUE}[${default}]${NC}: "
    else
        echo -en "${CYAN}? ${NC} ${label}: "
    fi
    read -rs input
    echo ""
    eval "$varname=\"${input:-$default}\""
}

# ─── Check if a command exists ────────────────────────────────────────
cmd_exists() {
    command -v "$1" &>/dev/null
}

# ══════════════════════════════════════════════════════════════════════
#  STEP 1: WELCOME BANNER
# ══════════════════════════════════════════════════════════════════════
print_banner() {
    echo -e "${MAGENTA}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║                                                      ║"
    echo "  ║       🔧  PAYASUN MARKETPLACE SETUP  🔧              ║"
    echo "  ║       Ubuntu Server Deployment Script                ║"
    echo "  ║       Version 1.0.0                                  ║"
    echo "  ║                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    info "This script will set up the Payasun backend on this server."
    info "Root directory: ${BOLD}${SCRIPT_DIR}${NC}"
    divider
}

# ══════════════════════════════════════════════════════════════════════
#  STEP 2: PREREQUISITE CHECKS & INSTALLATION
# ══════════════════════════════════════════════════════════════════════
check_prerequisites() {
    step "STEP 1/5 — Checking Prerequisites"

    local missing_pkgs=()

    # ── curl ──
    if cmd_exists curl; then
        success "curl is installed ($(curl --version | head -1 | awk '{print $2}'))"
    else
        warn "curl is NOT installed."
        missing_pkgs+=("curl")
    fi

    # ── git ──
    if cmd_exists git; then
        success "git is installed ($(git --version | awk '{print $3}'))"
    else
        warn "git is NOT installed."
        missing_pkgs+=("git")
    fi

    # ── Node.js ──
    if cmd_exists node; then
        local node_version
        node_version=$(node --version | sed 's/v//')
        local node_major
        node_major=$(echo "$node_version" | cut -d. -f1)

        if [ "$node_major" -ge "$REQUIRED_NODE_MAJOR" ]; then
            success "Node.js is installed (v${node_version}) — meets v${REQUIRED_NODE_MAJOR}+ requirement"
        else
            warn "Node.js v${node_version} found, but v${REQUIRED_NODE_MAJOR}+ is required."
            missing_pkgs+=("nodejs_upgrade")
        fi
    else
        warn "Node.js is NOT installed."
        missing_pkgs+=("nodejs")
    fi

    # ── npm ──
    if cmd_exists npm; then
        success "npm is installed (v$(npm --version))"
    else
        warn "npm is NOT installed."
        # npm comes with nodejs, so it will be installed with it
    fi

    # ── PostgreSQL ──
    if cmd_exists psql; then
        success "PostgreSQL client is installed ($(psql --version | awk '{print $3}'))"
    else
        warn "PostgreSQL is NOT installed."
        missing_pkgs+=("postgresql")
    fi

    # ── Install missing packages ──
    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        divider
        warn "Missing packages detected: ${missing_pkgs[*]}"

        if confirm "Would you like to install missing prerequisites now?"; then
            install_prerequisites "${missing_pkgs[@]}"
        else
            error "Cannot proceed without required packages. Exiting."
            exit 1
        fi
    else
        echo ""
        success "All prerequisites are satisfied!"
    fi
}

install_prerequisites() {
    local packages=("$@")

    info "Updating apt package index..."
    sudo apt-get update -qq

    for pkg in "${packages[@]}"; do
        case "$pkg" in
            curl)
                info "Installing curl..."
                sudo apt-get install -y -qq curl
                success "curl installed successfully."
                ;;
            git)
                info "Installing git..."
                sudo apt-get install -y -qq git
                success "git installed successfully."
                ;;
            nodejs|nodejs_upgrade)
                info "Installing Node.js v${REQUIRED_NODE_MAJOR}.x via NodeSource..."
                # Remove old NodeSource list if exists
                sudo rm -f /etc/apt/sources.list.d/nodesource.list
                # Install NodeSource setup script for Node.js v20
                curl -fsSL "https://deb.nodesource.com/setup_${REQUIRED_NODE_MAJOR}.x" | sudo -E bash -
                sudo apt-get install -y -qq nodejs
                success "Node.js $(node --version) installed successfully."
                success "npm $(npm --version) installed successfully."
                ;;
            postgresql)
                info "Installing PostgreSQL..."
                sudo apt-get install -y -qq postgresql postgresql-contrib
                # Ensure PostgreSQL service is running
                sudo systemctl enable postgresql
                sudo systemctl start postgresql
                success "PostgreSQL installed and started."
                ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════
#  STEP 3: INTERACTIVE .ENV GENERATOR
# ══════════════════════════════════════════════════════════════════════
generate_env_file() {
    step "STEP 2/5 — Environment Configuration"

    if [ -f "$ENV_FILE" ]; then
        warn "An existing .env file was found at: ${ENV_FILE}"
        if ! confirm "Overwrite the existing .env file?"; then
            info "Keeping existing .env file. Skipping configuration."
            return
        fi
    fi

    info "Please provide the following configuration values."
    info "Press Enter to accept the default value shown in brackets."
    divider

    # ── Database Configuration ──
    echo -e "\n${BOLD}📦 Database Configuration${NC}"
    prompt_input "Database Host"     "localhost" DB_HOST
    prompt_input "Database Port"     "5432"      DB_PORT
    prompt_input "Database Username" "postgres"  DB_USERNAME
    prompt_secret "Database Password" "postgres" DB_PASSWORD
    prompt_input "Database Name"     "payasun_db" DB_NAME

    # ── JWT Configuration ──
    echo -e "\n${BOLD}🔐 JWT Configuration${NC}"
    # Generate a random JWT secret if user doesn't provide one
    local default_jwt_secret
    default_jwt_secret=$(openssl rand -hex 32 2>/dev/null || echo "payasun_jwt_change_me_$(date +%s)")
    prompt_secret "JWT Secret Key" "$default_jwt_secret" JWT_SECRET
    prompt_input "JWT Expiration"  "7d" JWT_EXPIRATION

    # ── MeliPayamak SMS Gateway ──
    echo -e "\n${BOLD}📱 MeliPayamak SMS Gateway${NC}"
    prompt_input "MeliPayamak Username" "username_here" MELIPAYAMAK_USERNAME
    prompt_secret "MeliPayamak Password" "password_here" MELIPAYAMAK_PASSWORD
    prompt_input "MeliPayamak Body ID (Pattern Template ID)" "12345" MELIPAYAMAK_BODY_ID

    # ── SMS Debug Mode ──
    echo -e "\n${BOLD}🔧 SMS Debug Mode${NC}"
    info "When SMS_ENABLED=false, OTP codes are logged to the console"
    info "and returned in the API response (for frontend testing)."
    prompt_input "Enable real SMS sending? (true/false)" "false" SMS_ENABLED

    # ── Application ──
    echo -e "\n${BOLD}⚙️  Application${NC}"
    prompt_input "Application Port" "3000" APP_PORT

    # ── Write .env file ──
    divider
    info "Writing configuration to ${ENV_FILE}..."

    cat > "$ENV_FILE" << ENVFILE
# ─── Database ─────────────────────────────────────────────
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}

# ─── JWT ──────────────────────────────────────────────────
JWT_SECRET=${JWT_SECRET}
JWT_EXPIRATION=${JWT_EXPIRATION}

# ─── MeliPayamak SMS Gateway ─────────────────────────────
MELIPAYAMAK_USERNAME=${MELIPAYAMAK_USERNAME}
MELIPAYAMAK_PASSWORD=${MELIPAYAMAK_PASSWORD}
MELIPAYAMAK_BODY_ID=${MELIPAYAMAK_BODY_ID}

# ─── SMS Debug Mode ──────────────────────────────────────
# Set to 'true' in production. When 'false', OTP codes are
# logged to console and returned in the API response.
SMS_ENABLED=${SMS_ENABLED}

# ─── Application ─────────────────────────────────────────
APP_PORT=${APP_PORT}
ENVFILE

    success ".env file generated successfully."
}

# ══════════════════════════════════════════════════════════════════════
#  STEP 4: DATABASE BOOTSTRAP
# ══════════════════════════════════════════════════════════════════════
bootstrap_database() {
    step "STEP 3/5 — Database Bootstrap"

    # Source the .env to get DB_NAME and DB_USERNAME
    if [ -f "$ENV_FILE" ]; then
        # shellcheck disable=SC1090
        source <(grep -E '^(DB_NAME|DB_USERNAME|DB_PASSWORD|DB_HOST|DB_PORT)=' "$ENV_FILE")
    else
        error ".env file not found. Cannot bootstrap database."
        return 1
    fi

    info "Checking if database '${DB_NAME}' exists..."

    # Check if the database already exists
    local db_exists
    db_exists=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" 2>/dev/null || echo "0")

    if [ "$db_exists" = "1" ]; then
        success "Database '${DB_NAME}' already exists."
        return
    fi

    warn "Database '${DB_NAME}' does not exist."

    if confirm "Create the PostgreSQL database '${DB_NAME}' now?"; then
        info "Creating database '${DB_NAME}'..."

        # Create the PostgreSQL user if it doesn't exist (skip if 'postgres')
        if [ "$DB_USERNAME" != "postgres" ]; then
            local user_exists
            user_exists=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USERNAME}'" 2>/dev/null || echo "0")

            if [ "$user_exists" != "1" ]; then
                info "Creating PostgreSQL user '${DB_USERNAME}'..."
                sudo -u postgres psql -c "CREATE USER ${DB_USERNAME} WITH PASSWORD '${DB_PASSWORD}';" 2>/dev/null
                sudo -u postgres psql -c "ALTER USER ${DB_USERNAME} CREATEDB;" 2>/dev/null
                success "User '${DB_USERNAME}' created."
            else
                success "User '${DB_USERNAME}' already exists."
            fi
        fi

        # Create the database
        sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USERNAME};" 2>/dev/null

        if [ $? -eq 0 ]; then
            success "Database '${DB_NAME}' created successfully."
        else
            error "Failed to create database '${DB_NAME}'. Please create it manually."
            error "Command: sudo -u postgres psql -c \"CREATE DATABASE ${DB_NAME} OWNER ${DB_USERNAME};\""
        fi
    else
        warn "Skipping database creation. Make sure to create it manually before starting the app."
        info "Command: sudo -u postgres psql -c \"CREATE DATABASE ${DB_NAME} OWNER ${DB_USERNAME};\""
    fi
}

# ══════════════════════════════════════════════════════════════════════
#  STEP 5: BUILD BACKEND
# ══════════════════════════════════════════════════════════════════════
build_backend() {
    step "STEP 4/5 — Installing Dependencies & Building"

    if [ ! -d "$BACKEND_DIR" ]; then
        error "Backend directory not found at: ${BACKEND_DIR}"
        exit 1
    fi

    cd "$BACKEND_DIR"

    # ── Install node_modules ──
    info "Running npm install..."
    npm install --production=false

    if [ $? -eq 0 ]; then
        success "Dependencies installed successfully."
    else
        error "npm install failed. Check the output above."
        exit 1
    fi

    # ── Build the NestJS app ──
    info "Building NestJS application (npm run build)..."
    npm run build

    if [ $? -eq 0 ]; then
        success "Backend built successfully. Output: ${BACKEND_DIR}/dist/"
    else
        error "Build failed. Check the output above."
        exit 1
    fi
}

# ══════════════════════════════════════════════════════════════════════
#  STEP 6: PM2 PROCESS MANAGER SETUP
# ══════════════════════════════════════════════════════════════════════
setup_pm2() {
    step "STEP 5/5 — Process Manager (PM2) Setup"

    # ── Check/Install PM2 ──
    if cmd_exists pm2; then
        success "PM2 is already installed ($(pm2 --version))"
    else
        warn "PM2 is not installed."
        if confirm "Install PM2 globally for process management?"; then
            info "Installing PM2 globally..."
            sudo npm install -g pm2
            success "PM2 installed successfully ($(pm2 --version))"
        else
            warn "Skipping PM2 setup."
            divider
            info "To run the backend manually:"
            echo ""
            echo -e "  ${CYAN}cd ${BACKEND_DIR}${NC}"
            echo -e "  ${CYAN}node dist/main.js${NC}"
            echo ""
            info "Or with nohup for background execution:"
            echo ""
            echo -e "  ${CYAN}nohup node dist/main.js > app.log 2>&1 &${NC}"
            echo ""
            return
        fi
    fi

    cd "$BACKEND_DIR"

    # ── Source port from .env ──
    local app_port="3000"
    if [ -f "$ENV_FILE" ]; then
        app_port=$(grep -E '^APP_PORT=' "$ENV_FILE" | cut -d= -f2 || echo "3000")
    fi

    # ── Start with PM2 ──
    if confirm "Start the Payasun backend with PM2 now?"; then
        # Stop existing instance if running
        pm2 delete payasun-backend 2>/dev/null || true

        info "Starting Payasun backend via PM2..."
        pm2 start dist/main.js \
            --name "payasun-backend" \
            --max-memory-restart "512M" \
            --log-date-format "YYYY-MM-DD HH:mm:ss" \
            --merge-logs

        success "Backend started with PM2!"
        echo ""
        pm2 status

        divider
        if confirm "Save PM2 process list and enable startup on boot?"; then
            pm2 save
            pm2 startup systemd -u "$(whoami)" --hp "$HOME" 2>/dev/null || \
                warn "Run the 'pm2 startup' command printed above with sudo if needed."
            success "PM2 startup configured."
        fi
    else
        info "Skipping PM2 start. To start manually later:"
        echo ""
        echo -e "  ${CYAN}cd ${BACKEND_DIR}${NC}"
        echo -e "  ${CYAN}pm2 start dist/main.js --name payasun-backend${NC}"
        echo ""
    fi
}

# ══════════════════════════════════════════════════════════════════════
#  COMPLETION SUMMARY
# ══════════════════════════════════════════════════════════════════════
print_summary() {
    local app_port="3000"
    if [ -f "$ENV_FILE" ]; then
        app_port=$(grep -E '^APP_PORT=' "$ENV_FILE" | cut -d= -f2 || echo "3000")
    fi

    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║                                                      ║"
    echo "  ║       ✅  SETUP COMPLETE!                            ║"
    echo "  ║                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    divider
    info "Application URL:  ${BOLD}http://localhost:${app_port}${NC}"
    info "Swagger Docs:     ${BOLD}http://localhost:${app_port}/api/docs${NC}"
    info "Backend Dir:      ${BOLD}${BACKEND_DIR}${NC}"
    info "Environment:      ${BOLD}${ENV_FILE}${NC}"
    divider

    echo ""
    echo -e "${BOLD}Useful Commands:${NC}"
    echo -e "  ${CYAN}pm2 status${NC}                — Check process status"
    echo -e "  ${CYAN}pm2 logs payasun-backend${NC}  — View live logs"
    echo -e "  ${CYAN}pm2 restart payasun-backend${NC} — Restart the app"
    echo -e "  ${CYAN}pm2 stop payasun-backend${NC}  — Stop the app"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ══════════════════════════════════════════════════════════════════════
main() {
    print_banner

    if confirm "Continue with the setup?"; then
        check_prerequisites
        generate_env_file
        bootstrap_database
        build_backend
        setup_pm2
        print_summary
    else
        info "Setup cancelled. Goodbye!"
        exit 0
    fi
}

# ── Entry Point ───────────────────────────────────────────────────────
main "$@"
