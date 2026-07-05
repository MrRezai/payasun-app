#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════
#  Payasun Marketplace — Platform Management Dashboard
#  Version: 2.0.0
#
#  An interactive TUI management tool for the Payasun backend platform
#  running on Ubuntu servers. Provides ongoing system management
#  capabilities beyond first-time installation.
#
#  Features:
#    ✦ System health monitoring (Node.js, PostgreSQL, PM2, Nginx)
#    ✦ Nginx reverse proxy & domain configuration with Let's Encrypt SSL
#    ✦ Live PM2 log streaming
#    ✦ Backend restart & process management
#    ✦ Interactive .env reconfiguration
#    ✦ Smart no-duplicate installation checks
#
#  Usage:
#    chmod +x setup.sh && ./setup.sh
#
#  Requirements:
#    - Ubuntu 20.04+ (sudo access required for package installation)
#    - Internet connectivity for downloading packages
# ══════════════════════════════════════════════════════════════════════

# NOTE: We intentionally do NOT use global `set -euo pipefail` here.
# The menu loop must survive non-fatal check failures (e.g., a service
# being down). Individual functions use explicit error handling instead.

# ─── Constants ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${SCRIPT_DIR}/backend"
ENV_FILE="${BACKEND_DIR}/.env"
REQUIRED_NODE_MAJOR=20
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
PM2_APP_NAME="payasun-backend"
VERSION="2.0.0"

# ─── Color Codes ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m'

# ─── Output Helpers ───────────────────────────────────────────────────
info()    { echo -e "  ${CYAN}ℹ${NC}  $1"; }
success() { echo -e "  ${GREEN}✔${NC}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
error()   { echo -e "  ${RED}✖${NC}  $1"; }
header()  { echo -e "\n  ${MAGENTA}${BOLD}━━━ $1 ━━━${NC}\n"; }
divider() { echo -e "  ${BLUE}──────────────────────────────────────────────────────${NC}"; }

status_ok()   { echo -e "  ${GREEN}● RUNNING${NC}  $1"; }
status_fail() { echo -e "  ${RED}● STOPPED${NC}  $1"; }
status_miss() { echo -e "  ${YELLOW}● MISSING${NC}  $1"; }
status_info() { echo -e "  ${CYAN}● INFO${NC}     $1"; }

# ─── Utility: Check if a command exists ───────────────────────────────
cmd_exists() {
    command -v "$1" &>/dev/null
}

# ─── Utility: Check if a systemd service is active ───────────────────
service_active() {
    systemctl is-active --quiet "$1" 2>/dev/null
}

# ─── Utility: Confirmation prompt ────────────────────────────────────
confirm() {
    local prompt="$1"
    local response
    while true; do
        echo -en "  ${YELLOW}?${NC}  ${prompt} [y/n]: "
        read -r response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            [nN]|[nN][oO])     return 1 ;;
            *) warn "Please answer y or n." ;;
        esac
    done
}

# ─── Utility: Prompt for input with default ──────────────────────────
prompt_input() {
    local label="$1"
    local default="$2"
    local varname="$3"
    local input
    if [ -n "$default" ]; then
        echo -en "  ${CYAN}?${NC}  ${label} ${DIM}[${default}]${NC}: "
    else
        echo -en "  ${CYAN}?${NC}  ${label}: "
    fi
    read -r input
    eval "$varname=\"${input:-$default}\""
}

# ─── Utility: Prompt for hidden/sensitive input ──────────────────────
prompt_secret() {
    local label="$1"
    local default="$2"
    local varname="$3"
    local input
    if [ -n "$default" ]; then
        echo -en "  ${CYAN}?${NC}  ${label} ${DIM}[hidden]${NC}: "
    else
        echo -en "  ${CYAN}?${NC}  ${label}: "
    fi
    read -rs input
    echo ""
    eval "$varname=\"${input:-$default}\""
}

# ─── Utility: Press any key to continue ──────────────────────────────
pause_continue() {
    echo ""
    echo -en "  ${DIM}Press any key to return to the menu...${NC}"
    read -rsn1
    echo ""
}

# ─── Utility: Smart package installer (no duplicates) ────────────────
smart_install() {
    local pkg_name="$1"
    local display_name="${2:-$1}"

    if dpkg -s "$pkg_name" &>/dev/null; then
        success "${display_name} is already installed. Skipping."
        return 0
    fi

    if confirm "Install ${display_name}?"; then
        info "Installing ${display_name}..."
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y -qq "$pkg_name"
        if [ $? -eq 0 ]; then
            success "${display_name} installed successfully."
        else
            error "Failed to install ${display_name}."
            return 1
        fi
    else
        warn "Skipped ${display_name} installation."
        return 1
    fi
}


# ══════════════════════════════════════════════════════════════════════
#  MENU BANNER
# ══════════════════════════════════════════════════════════════════════
show_banner() {
    clear
    echo ""
    echo -e "  ${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${MAGENTA}${BOLD}║${NC}                                                          ${MAGENTA}${BOLD}║${NC}"
    echo -e "  ${MAGENTA}${BOLD}║${NC}   ${WHITE}${BOLD}🔧  PAYASUN PLATFORM MANAGEMENT DASHBOARD${NC}              ${MAGENTA}${BOLD}║${NC}"
    echo -e "  ${MAGENTA}${BOLD}║${NC}   ${DIM}Interactive server management for Payasun backend${NC}      ${MAGENTA}${BOLD}║${NC}"
    echo -e "  ${MAGENTA}${BOLD}║${NC}   ${DIM}Version ${VERSION}${NC}                                          ${MAGENTA}${BOLD}║${NC}"
    echo -e "  ${MAGENTA}${BOLD}║${NC}                                                          ${MAGENTA}${BOLD}║${NC}"
    echo -e "  ${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_menu() {
    echo -e "  ${BOLD}${UNDERLINE}Select an option:${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC}  📊  Check System Status"
    echo -e "  ${GREEN}[2]${NC}  🌐  Configure Nginx Reverse Proxy & Domain"
    echo -e "  ${GREEN}[3]${NC}  📋  View Live PM2 Logs"
    echo -e "  ${GREEN}[4]${NC}  🔄  Restart Backend Application"
    echo -e "  ${GREEN}[5]${NC}  ⚙️   Reconfigure Environment (.env)"
    echo -e "  ${GREEN}[6]${NC}  🛠️   Diagnose & Fix Database Connection"
    echo -e "  ${RED}[7]${NC}  🚪  Exit Dashboard"
    echo ""
    divider
    echo -en "  ${CYAN}▶${NC}  Enter your choice [1-7]: "
}


# ══════════════════════════════════════════════════════════════════════
#  [1] CHECK SYSTEM STATUS
# ══════════════════════════════════════════════════════════════════════
check_system_status() {
    header "SYSTEM HEALTH STATUS"

    local all_ok=true

    # ── Node.js ──────────────────────────────────────────────────────
    echo -e "  ${BOLD}Node.js${NC}"
    if cmd_exists node; then
        local node_ver
        node_ver=$(node --version 2>/dev/null || echo "unknown")
        local node_major
        node_major=$(echo "$node_ver" | sed 's/v//' | cut -d. -f1)

        if [ "$node_major" -ge "$REQUIRED_NODE_MAJOR" ] 2>/dev/null; then
            status_ok "Node.js ${node_ver} ${DIM}(meets v${REQUIRED_NODE_MAJOR}+ requirement)${NC}"
        else
            status_fail "Node.js ${node_ver} ${RED}(v${REQUIRED_NODE_MAJOR}+ required)${NC}"
            all_ok=false
        fi
    else
        status_miss "Node.js is not installed"
        all_ok=false
    fi

    # ── npm ──────────────────────────────────────────────────────────
    echo -e "  ${BOLD}npm${NC}"
    if cmd_exists npm; then
        status_ok "npm v$(npm --version 2>/dev/null || echo 'unknown')"
    else
        status_miss "npm is not installed"
        all_ok=false
    fi

    # ── PostgreSQL ───────────────────────────────────────────────────
    echo -e "  ${BOLD}PostgreSQL${NC}"
    if cmd_exists psql; then
        local pg_ver
        pg_ver=$(psql --version 2>/dev/null | awk '{print $3}' || echo "unknown")
        if service_active postgresql; then
            status_ok "PostgreSQL ${pg_ver} ${DIM}(service active)${NC}"
        else
            status_fail "PostgreSQL ${pg_ver} ${RED}(service not running)${NC}"
            all_ok=false
        fi
    else
        status_miss "PostgreSQL is not installed"
        all_ok=false
    fi

    # ── PM2 ──────────────────────────────────────────────────────────
    echo -e "  ${BOLD}PM2 Process Manager${NC}"
    if cmd_exists pm2; then
        local pm2_ver
        pm2_ver=$(pm2 --version 2>/dev/null || echo "unknown")

        # Check if payasun-backend is running in PM2
        local pm2_status
        pm2_status=$(pm2 jlist 2>/dev/null | grep -o "\"name\":\"${PM2_APP_NAME}\"" || echo "")

        if [ -n "$pm2_status" ]; then
            local pm2_app_status
            pm2_app_status=$(pm2 jlist 2>/dev/null | python3 -c "
import sys, json
try:
    apps = json.load(sys.stdin)
    for app in apps:
        if app.get('name') == '${PM2_APP_NAME}':
            status = app.get('pm2_env', {}).get('status', 'unknown')
            mem = app.get('monit', {}).get('memory', 0)
            cpu = app.get('monit', {}).get('cpu', 0)
            uptime = app.get('pm2_env', {}).get('pm_uptime', 0)
            print(f'{status}|{mem}|{cpu}')
            break
except: print('unknown|0|0')
" 2>/dev/null || echo "unknown|0|0")

            local app_state mem_bytes cpu_pct
            app_state=$(echo "$pm2_app_status" | cut -d'|' -f1)
            mem_bytes=$(echo "$pm2_app_status" | cut -d'|' -f2)
            cpu_pct=$(echo "$pm2_app_status" | cut -d'|' -f3)

            # Convert memory to MB
            local mem_mb="0"
            if [ "$mem_bytes" -gt 0 ] 2>/dev/null; then
                mem_mb=$((mem_bytes / 1024 / 1024))
            fi

            if [ "$app_state" = "online" ]; then
                status_ok "PM2 v${pm2_ver} — ${BOLD}${PM2_APP_NAME}${NC} is ${GREEN}online${NC} ${DIM}(${mem_mb}MB RAM, ${cpu_pct}% CPU)${NC}"
            else
                status_fail "PM2 v${pm2_ver} — ${BOLD}${PM2_APP_NAME}${NC} is ${RED}${app_state}${NC}"
                all_ok=false
            fi
        else
            status_info "PM2 v${pm2_ver} — ${BOLD}${PM2_APP_NAME}${NC} ${YELLOW}not registered${NC}"
            all_ok=false
        fi
    else
        status_miss "PM2 is not installed"
        all_ok=false
    fi

    # ── Nginx ────────────────────────────────────────────────────────
    echo -e "  ${BOLD}Nginx${NC}"
    if cmd_exists nginx; then
        local nginx_ver
        nginx_ver=$(nginx -v 2>&1 | sed 's/.*\///' || echo "unknown")
        if service_active nginx; then
            status_ok "Nginx ${nginx_ver} ${DIM}(service active)${NC}"

            # Show configured domains
            if [ -d "$NGINX_SITES_ENABLED" ]; then
                local site_count
                site_count=$(ls -1 "$NGINX_SITES_ENABLED" 2>/dev/null | grep -v default | wc -l)
                if [ "$site_count" -gt 0 ]; then
                    for site in "$NGINX_SITES_ENABLED"/*; do
                        local site_name
                        site_name=$(basename "$site")
                        if [ "$site_name" != "default" ]; then
                            local domain
                            domain=$(grep -m1 'server_name' "$site" 2>/dev/null | awk '{print $2}' | tr -d ';' || echo "$site_name")
                            status_info "  └─ Domain: ${BOLD}${domain}${NC}"
                        fi
                    done
                fi
            fi
        else
            status_fail "Nginx ${nginx_ver} ${RED}(service not running)${NC}"
            all_ok=false
        fi
    else
        status_miss "Nginx is not installed"
    fi

    # ── .env File ────────────────────────────────────────────────────
    echo -e "  ${BOLD}Environment Config${NC}"
    if [ -f "$ENV_FILE" ]; then
        local sms_mode
        sms_mode=$(grep -E '^SMS_ENABLED=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "unknown")
        local app_port
        app_port=$(grep -E '^APP_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "3000")
        status_ok ".env file exists ${DIM}(Port: ${app_port}, SMS: ${sms_mode})${NC}"
    else
        status_fail ".env file not found at ${ENV_FILE}"
        all_ok=false
    fi

    # ── Summary ──────────────────────────────────────────────────────
    echo ""
    divider
    if [ "$all_ok" = true ]; then
        echo ""
        success "${GREEN}${BOLD}All systems are healthy!${NC}"
    else
        echo ""
        warn "${YELLOW}Some components need attention. Review the status above.${NC}"
    fi

    pause_continue
}


# ══════════════════════════════════════════════════════════════════════
#  [2] CONFIGURE NGINX REVERSE PROXY & DOMAIN
# ══════════════════════════════════════════════════════════════════════
configure_nginx() {
    header "NGINX REVERSE PROXY & DOMAIN SETUP"

    # ── Step 1: Ensure Nginx is installed ────────────────────────────
    if ! cmd_exists nginx; then
        warn "Nginx is not installed on this system."
        if confirm "Install Nginx now?"; then
            info "Installing Nginx..."
            sudo apt-get update -qq 2>/dev/null
            sudo apt-get install -y -qq nginx
            sudo systemctl enable nginx
            sudo systemctl start nginx
            success "Nginx installed and started."
        else
            error "Cannot configure reverse proxy without Nginx. Returning to menu."
            pause_continue
            return
        fi
    else
        success "Nginx is already installed. $(nginx -v 2>&1 | sed 's/.*: //')"
    fi

    echo ""

    # ── Step 2: Read the backend port from .env ──────────────────────
    local backend_port="3000"
    if [ -f "$ENV_FILE" ]; then
        backend_port=$(grep -E '^APP_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "3000")
    fi
    info "Backend is configured on port: ${BOLD}${backend_port}${NC}"
    echo ""

    # ── Step 3: Ask for domain name ──────────────────────────────────
    local domain=""
    prompt_input "Enter your domain name (e.g., api.payasun.com)" "" domain

    if [ -z "$domain" ]; then
        error "Domain name cannot be empty. Returning to menu."
        pause_continue
        return
    fi

    # Sanitize the domain (remove protocol and trailing slashes)
    domain=$(echo "$domain" | sed -e 's|https\?://||' -e 's|/.*||' -e 's|:.*||')
    info "Configuring Nginx for domain: ${BOLD}${domain}${NC}"
    echo ""

    # ── Step 4: Check for existing config (no-duplicate) ─────────────
    local config_file="${NGINX_SITES_AVAILABLE}/${domain}"

    if [ -f "$config_file" ]; then
        warn "A Nginx configuration for '${domain}' already exists:"
        echo -e "  ${DIM}${config_file}${NC}"
        echo ""

        if ! confirm "Overwrite the existing configuration?"; then
            info "Keeping existing configuration. Skipping."
            pause_continue
            return
        fi
        info "Overwriting existing configuration..."
    fi

    # ── Step 5: Generate Nginx server block ──────────────────────────
    info "Generating Nginx server block..."

    sudo tee "$config_file" > /dev/null << NGINX_CONF
# ──────────────────────────────────────────────────────────
# Payasun Backend — Nginx Reverse Proxy Configuration
# Domain: ${domain}
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ──────────────────────────────────────────────────────────
server {
    listen 80;
    listen [::]:80;
    server_name ${domain};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    # Max upload size
    client_max_body_size 10M;

    # Proxy to NestJS backend
    location / {
        proxy_pass http://127.0.0.1:${backend_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 90s;
        proxy_connect_timeout 90s;
    }

    # Swagger UI specific — allow larger payloads
    location /api/docs {
        proxy_pass http://127.0.0.1:${backend_port}/api/docs;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
        proxy_busy_buffers_size 256k;
    }
}
NGINX_CONF

    success "Server block written to: ${config_file}"

    # ── Step 6: Enable the site (symlink) ────────────────────────────
    local enabled_link="${NGINX_SITES_ENABLED}/${domain}"

    if [ -L "$enabled_link" ]; then
        sudo rm "$enabled_link"
    fi

    sudo ln -s "$config_file" "$enabled_link"
    success "Site enabled: ${enabled_link} → ${config_file}"

    # ── Step 7: Remove default site if it exists (optional) ──────────
    if [ -L "${NGINX_SITES_ENABLED}/default" ]; then
        if confirm "Remove the default Nginx site? (Recommended for production)"; then
            sudo rm "${NGINX_SITES_ENABLED}/default"
            success "Default site removed."
        fi
    fi

    # ── Step 8: Test & reload Nginx ──────────────────────────────────
    echo ""
    info "Testing Nginx configuration..."

    if sudo nginx -t 2>&1; then
        success "Nginx configuration test passed!"
        info "Reloading Nginx..."
        sudo systemctl reload nginx
        success "Nginx reloaded successfully."
    else
        error "Nginx configuration test FAILED. Please review the config above."
        error "File: ${config_file}"
        pause_continue
        return
    fi

    echo ""
    divider
    success "Nginx reverse proxy configured for ${BOLD}${domain}${NC}"
    info "HTTP traffic → ${BOLD}http://${domain}${NC} → ${BOLD}localhost:${backend_port}${NC}"
    info "Swagger UI  → ${BOLD}http://${domain}/api/docs${NC}"
    echo ""

    # ── Step 9: Offer Let's Encrypt SSL via Certbot ──────────────────
    divider
    echo ""
    echo -e "  ${BOLD}🔒 SSL Certificate (Let's Encrypt)${NC}"
    info "Free HTTPS certificates can be installed via Certbot."
    echo ""

    if confirm "Install Certbot and configure free SSL for ${domain}?"; then
        install_certbot_ssl "$domain"
    else
        info "Skipping SSL setup. You can run this option again later."
        warn "Your API is currently accessible only via HTTP (not encrypted)."
    fi

    pause_continue
}

# ─── Sub-function: Install Certbot & issue SSL ───────────────────────
install_certbot_ssl() {
    local domain="$1"

    # Check if certbot is already installed
    if ! cmd_exists certbot; then
        info "Installing Certbot and Nginx plugin..."
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y -qq certbot python3-certbot-nginx
        if [ $? -ne 0 ]; then
            error "Failed to install Certbot."
            return 1
        fi
        success "Certbot installed successfully."
    else
        success "Certbot is already installed."
    fi

    echo ""
    info "Requesting SSL certificate for ${BOLD}${domain}${NC}..."
    info "Make sure your domain's DNS A record points to this server's IP."
    echo ""

    if confirm "Proceed with certificate issuance? (DNS must be configured first)"; then
        # Run certbot with auto-redirect to HTTPS
        sudo certbot --nginx -d "$domain" --non-interactive --agree-tos \
            --redirect --email "admin@${domain}" 2>&1

        if [ $? -eq 0 ]; then
            echo ""
            success "SSL certificate installed and HTTPS redirect enabled!"
            info "Your API is now available at: ${BOLD}https://${domain}${NC}"
            info "Certificate auto-renewal is configured via systemd timer."
        else
            error "Certbot failed. Please check your DNS settings and try again."
            info "You can retry manually: sudo certbot --nginx -d ${domain}"
        fi
    else
        warn "SSL certificate issuance skipped."
        info "Run this option again or manually: sudo certbot --nginx -d ${domain}"
    fi
}


# ══════════════════════════════════════════════════════════════════════
#  [3] VIEW LIVE PM2 LOGS
# ══════════════════════════════════════════════════════════════════════
view_pm2_logs() {
    header "LIVE PM2 LOGS"

    if ! cmd_exists pm2; then
        error "PM2 is not installed. Install it first via: ${CYAN}sudo npm install -g pm2${NC}"
        pause_continue
        return
    fi

    # Check if the app is registered in PM2
    local app_registered
    app_registered=$(pm2 jlist 2>/dev/null | grep -o "\"name\":\"${PM2_APP_NAME}\"" || echo "")

    if [ -z "$app_registered" ]; then
        warn "Application '${PM2_APP_NAME}' is not registered in PM2."
        info "Start it first with: ${CYAN}pm2 start ${BACKEND_DIR}/dist/main.js --name ${PM2_APP_NAME}${NC}"
        pause_continue
        return
    fi

    info "Streaming live logs for ${BOLD}${PM2_APP_NAME}${NC}..."
    info "Press ${BOLD}Ctrl+C${NC} to stop and return to the menu."
    echo ""
    divider
    echo ""

    # Run pm2 logs — user exits with Ctrl+C, which we catch gracefully
    pm2 logs "$PM2_APP_NAME" --lines 50 || true

    echo ""
    info "Log stream ended."
    pause_continue
}


# ══════════════════════════════════════════════════════════════════════
#  [4] RESTART BACKEND APPLICATION
# ══════════════════════════════════════════════════════════════════════
restart_backend() {
    header "RESTART BACKEND APPLICATION"

    if ! cmd_exists pm2; then
        error "PM2 is not installed."

        if confirm "Install PM2 globally now?"; then
            sudo npm install -g pm2
            success "PM2 installed."
        else
            error "Cannot restart without PM2. Returning to menu."
            pause_continue
            return
        fi
    fi

    # Check if app is registered
    local app_registered
    app_registered=$(pm2 jlist 2>/dev/null | grep -o "\"name\":\"${PM2_APP_NAME}\"" || echo "")

    if [ -z "$app_registered" ]; then
        warn "Application '${PM2_APP_NAME}' is not registered in PM2."
        echo ""

        if confirm "Start it now? (Requires a prior build in ${BACKEND_DIR}/dist/)"; then
            if [ ! -f "${BACKEND_DIR}/dist/main.js" ]; then
                error "Build output not found at ${BACKEND_DIR}/dist/main.js"
                info "Run the build first:"
                echo -e "    ${CYAN}cd ${BACKEND_DIR} && npm install && npm run build${NC}"
                pause_continue
                return
            fi

            cd "$BACKEND_DIR"
            pm2 start dist/main.js \
                --name "$PM2_APP_NAME" \
                --max-memory-restart "512M" \
                --log-date-format "YYYY-MM-DD HH:mm:ss" \
                --merge-logs

            success "Application started with PM2!"
            echo ""
            pm2 status
        fi

        pause_continue
        return
    fi

    # App is registered — offer restart options
    echo -e "  ${BOLD}Restart options:${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC}  Graceful restart (reload)"
    echo -e "  ${GREEN}[2]${NC}  Hard restart (stop + start)"
    echo -e "  ${GREEN}[3]${NC}  Rebuild & restart (npm run build → reload)"
    echo -e "  ${RED}[4]${NC}  Cancel"
    echo ""
    echo -en "  ${CYAN}▶${NC}  Choose [1-4]: "

    local choice
    read -r choice

    case "$choice" in
        1)
            info "Gracefully reloading ${PM2_APP_NAME}..."
            pm2 reload "$PM2_APP_NAME"
            success "Application reloaded successfully!"
            echo ""
            pm2 status
            ;;
        2)
            info "Hard restarting ${PM2_APP_NAME}..."
            pm2 restart "$PM2_APP_NAME"
            success "Application restarted successfully!"
            echo ""
            pm2 status
            ;;
        3)
            info "Rebuilding backend..."
            cd "$BACKEND_DIR"

            info "Running npm install..."
            npm install --production=false
            success "Dependencies installed."

            info "Building NestJS application..."
            npm run build
            if [ $? -eq 0 ]; then
                success "Build complete."
                info "Reloading PM2 process..."
                pm2 reload "$PM2_APP_NAME"
                success "Application rebuilt and reloaded!"
                echo ""
                pm2 status
            else
                error "Build failed! The running application was NOT restarted."
                error "Fix the build errors and try again."
            fi
            ;;
        4)
            info "Cancelled."
            ;;
        *)
            warn "Invalid option."
            ;;
    esac

    pause_continue
}


# ══════════════════════════════════════════════════════════════════════
#  [5] RECONFIGURE ENVIRONMENT (.env)
# ══════════════════════════════════════════════════════════════════════
reconfigure_env() {
    header "RECONFIGURE ENVIRONMENT (.env)"

    # ── Show current config ──────────────────────────────────────────
    if [ -f "$ENV_FILE" ]; then
        info "Current configuration at ${BOLD}${ENV_FILE}${NC}:"
        echo ""
        divider

        # Display current values (mask passwords)
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            if [[ -z "$line" || "$line" == \#* ]]; then
                echo -e "  ${DIM}${line}${NC}"
                continue
            fi

            local key val
            key=$(echo "$line" | cut -d= -f1)
            val=$(echo "$line" | cut -d= -f2-)

            # Mask sensitive values
            if [[ "$key" == *PASSWORD* || "$key" == *SECRET* ]]; then
                echo -e "  ${CYAN}${key}${NC}=${DIM}*****${NC}"
            else
                echo -e "  ${CYAN}${key}${NC}=${val}"
            fi
        done < "$ENV_FILE"

        divider
        echo ""
    else
        warn "No .env file found. Creating a new one."
    fi

    # ── Choose edit mode ─────────────────────────────────────────────
    echo -e "  ${BOLD}What would you like to do?${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC}  Edit individual variables"
    echo -e "  ${GREEN}[2]${NC}  Regenerate entire .env from scratch"
    echo -e "  ${RED}[3]${NC}  Cancel"
    echo ""
    echo -en "  ${CYAN}▶${NC}  Choose [1-3]: "

    local edit_choice
    read -r edit_choice

    case "$edit_choice" in
        1) edit_individual_vars ;;
        2) regenerate_full_env ;;
        3) info "Cancelled." ;;
        *) warn "Invalid option." ;;
    esac

    pause_continue
}

# ─── Sub-function: Edit individual variables ─────────────────────────
edit_individual_vars() {
    echo ""
    info "Type the variable name you want to change, then the new value."
    info "Type ${BOLD}done${NC} when finished."
    echo ""

    if [ ! -f "$ENV_FILE" ]; then
        error "No .env file to edit. Use option [2] to generate one."
        return
    fi

    while true; do
        echo -en "  ${CYAN}?${NC}  Variable name (or ${BOLD}done${NC}): "
        local varname
        read -r varname

        if [ "$varname" = "done" ] || [ -z "$varname" ]; then
            break
        fi

        # Check if variable exists
        if grep -qE "^${varname}=" "$ENV_FILE"; then
            local current_val
            current_val=$(grep -E "^${varname}=" "$ENV_FILE" | cut -d= -f2-)

            if [[ "$varname" == *PASSWORD* || "$varname" == *SECRET* ]]; then
                prompt_secret "New value for ${varname}" "$current_val" new_val
            else
                prompt_input "New value for ${varname}" "$current_val" new_val
            fi

            # Use sed to replace the value in .env
            sed -i "s|^${varname}=.*|${varname}=${new_val}|" "$ENV_FILE"
            success "${varname} updated."
        else
            warn "Variable '${varname}' not found in .env"

            if confirm "Add '${varname}' as a new variable?"; then
                prompt_input "Value for ${varname}" "" new_val
                echo "${varname}=${new_val}" >> "$ENV_FILE"
                success "${varname} added."
            fi
        fi
        echo ""
    done

    success "Environment file updated."
    echo ""

    # Offer to restart
    if cmd_exists pm2; then
        local app_registered
        app_registered=$(pm2 jlist 2>/dev/null | grep -o "\"name\":\"${PM2_APP_NAME}\"" || echo "")
        if [ -n "$app_registered" ]; then
            if confirm "Restart the application to apply changes?"; then
                pm2 restart "$PM2_APP_NAME"
                success "Application restarted."
            fi
        fi
    fi
}

# ─── Sub-function: Regenerate full .env ──────────────────────────────
regenerate_full_env() {
    echo ""

    if [ -f "$ENV_FILE" ]; then
        warn "This will overwrite your existing .env file."
        if ! confirm "Are you sure?"; then
            info "Cancelled."
            return
        fi

        # Create a backup
        local backup_file="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ENV_FILE" "$backup_file"
        success "Backup saved to: ${backup_file}"
    fi

    echo ""
    info "Please provide the configuration values."
    info "Press Enter to accept the default shown in brackets."
    echo ""

    # ── Read existing values as defaults if available ─────────────
    local cur_db_host="localhost" cur_db_port="5432" cur_db_user="postgres"
    local cur_db_pass="postgres" cur_db_name="payasun_db"
    local cur_jwt_exp="7d" cur_jwt_secret=""
    local cur_sms_user="username_here" cur_sms_pass="password_here"
    local cur_sms_body="12345" cur_sms_enabled="false" cur_app_port="3000"

    if [ -f "$ENV_FILE" ]; then
        cur_db_host=$(grep -E '^DB_HOST=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_db_host")
        cur_db_port=$(grep -E '^DB_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_db_port")
        cur_db_user=$(grep -E '^DB_USERNAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_db_user")
        cur_db_pass=$(grep -E '^DB_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_db_pass")
        cur_db_name=$(grep -E '^DB_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_db_name")
        cur_jwt_secret=$(grep -E '^JWT_SECRET=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "")
        cur_jwt_exp=$(grep -E '^JWT_EXPIRATION=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_jwt_exp")
        cur_sms_user=$(grep -E '^MELIPAYAMAK_USERNAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_sms_user")
        cur_sms_pass=$(grep -E '^MELIPAYAMAK_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_sms_pass")
        cur_sms_body=$(grep -E '^MELIPAYAMAK_BODY_ID=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_sms_body")
        cur_sms_enabled=$(grep -E '^SMS_ENABLED=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_sms_enabled")
        cur_app_port=$(grep -E '^APP_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "$cur_app_port")
    fi

    # Generate random JWT secret if none exists
    if [ -z "$cur_jwt_secret" ]; then
        cur_jwt_secret=$(openssl rand -hex 32 2>/dev/null || echo "payasun_jwt_$(date +%s)")
    fi

    # ── Database ─────────────────────────────────────────────────
    echo -e "  ${BOLD}📦 Database Configuration${NC}"
    prompt_input "Database Host"     "$cur_db_host" DB_HOST
    prompt_input "Database Port"     "$cur_db_port" DB_PORT
    prompt_input "Database Username" "$cur_db_user" DB_USERNAME
    prompt_secret "Database Password" "$cur_db_pass" DB_PASSWORD
    prompt_input "Database Name"     "$cur_db_name" DB_NAME

    # ── JWT ──────────────────────────────────────────────────────
    echo -e "\n  ${BOLD}🔐 JWT Configuration${NC}"
    prompt_secret "JWT Secret Key" "$cur_jwt_secret" JWT_SECRET
    prompt_input "JWT Expiration"  "$cur_jwt_exp" JWT_EXPIRATION

    # ── MeliPayamak ──────────────────────────────────────────────
    echo -e "\n  ${BOLD}📱 MeliPayamak SMS Gateway${NC}"
    prompt_input "MeliPayamak Username" "$cur_sms_user" MELIPAYAMAK_USERNAME
    prompt_secret "MeliPayamak Password" "$cur_sms_pass" MELIPAYAMAK_PASSWORD
    prompt_input "MeliPayamak Body ID"  "$cur_sms_body" MELIPAYAMAK_BODY_ID

    # ── SMS Debug ────────────────────────────────────────────────
    echo -e "\n  ${BOLD}🔧 SMS Debug Mode${NC}"
    info "When false, OTP codes appear in the API response for testing."
    prompt_input "Enable real SMS? (true/false)" "$cur_sms_enabled" SMS_ENABLED

    # ── App Port ─────────────────────────────────────────────────
    echo -e "\n  ${BOLD}⚙️  Application${NC}"
    prompt_input "Application Port" "$cur_app_port" APP_PORT

    # ── Write file ───────────────────────────────────────────────
    echo ""
    divider
    info "Writing configuration..."

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

    success ".env file regenerated successfully."
    echo ""

    # Offer to restart
    if cmd_exists pm2; then
        local app_registered
        app_registered=$(pm2 jlist 2>/dev/null | grep -o "\"name\":\"${PM2_APP_NAME}\"" || echo "")
        if [ -n "$app_registered" ]; then
            if confirm "Restart the application to apply the new config?"; then
                pm2 restart "$PM2_APP_NAME"
                success "Application restarted with new configuration."
            fi
        fi
    fi
}


# ══════════════════════════════════════════════════════════════════════
#  [6] DIAGNOSE & FIX DATABASE CONNECTION
# ══════════════════════════════════════════════════════════════════════
diagnose_database() {
    header "DATABASE CONNECTION DIAGNOSTICS"

    # ── Load .env credentials ────────────────────────────────────────
    if [ ! -f "$ENV_FILE" ]; then
        error ".env file not found at ${ENV_FILE}"
        error "Run option [5] to create one first."
        pause_continue
        return
    fi

    local db_host db_port db_user db_pass db_name
    db_host=$(grep -E '^DB_HOST=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "localhost")
    db_port=$(grep -E '^DB_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "5432")
    db_user=$(grep -E '^DB_USERNAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "postgres")
    db_pass=$(grep -E '^DB_PASSWORD=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "")
    db_name=$(grep -E '^DB_NAME=' "$ENV_FILE" 2>/dev/null | cut -d= -f2 || echo "payasun_db")

    info "Loaded .env credentials:"
    echo -e "    ${DIM}Host:     ${NC}${db_host}"
    echo -e "    ${DIM}Port:     ${NC}${db_port}"
    echo -e "    ${DIM}Username: ${NC}${db_user}"
    echo -e "    ${DIM}Password: ${NC}*****"
    echo -e "    ${DIM}Database: ${NC}${db_name}"
    echo ""
    divider

    local issues_found=0

    # ── Check 1: Is PostgreSQL installed? ─────────────────────────────
    echo ""
    echo -e "  ${BOLD}Test 1: PostgreSQL Installation${NC}"
    if cmd_exists psql; then
        local pg_ver
        pg_ver=$(psql --version 2>/dev/null | awk '{print $3}' || echo "unknown")
        status_ok "PostgreSQL client found (v${pg_ver})"
    else
        status_fail "PostgreSQL client (psql) not found"
        issues_found=$((issues_found + 1))

        if confirm "Install PostgreSQL now?"; then
            sudo apt-get update -qq 2>/dev/null
            sudo apt-get install -y -qq postgresql postgresql-contrib
            sudo systemctl enable postgresql
            sudo systemctl start postgresql
            success "PostgreSQL installed and started."
        else
            error "Cannot continue without PostgreSQL."
            pause_continue
            return
        fi
    fi

    # ── Check 2: Is the PostgreSQL service running? ───────────────────
    echo ""
    echo -e "  ${BOLD}Test 2: PostgreSQL Service Status${NC}"
    if service_active postgresql; then
        status_ok "PostgreSQL service is active"
    else
        status_fail "PostgreSQL service is NOT running"
        issues_found=$((issues_found + 1))

        if confirm "Start the PostgreSQL service?"; then
            sudo systemctl start postgresql
            if service_active postgresql; then
                success "PostgreSQL service started."
            else
                error "Failed to start PostgreSQL."
                error "Check logs: sudo journalctl -u postgresql -n 20"
                pause_continue
                return
            fi
        else
            error "Cannot diagnose further without a running PostgreSQL."
            pause_continue
            return
        fi
    fi

    # ── Check 3: Can we connect as the configured user? ──────────────
    echo ""
    echo -e "  ${BOLD}Test 3: Password Authentication for '${db_user}'${NC}"

    local auth_ok=false
    if PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d postgres -c "SELECT 1;" &>/dev/null; then
        status_ok "Authentication successful for user '${db_user}'"
        auth_ok=true
    else
        status_fail "Authentication FAILED for user '${db_user}'"
        issues_found=$((issues_found + 1))

        echo ""
        warn "This is the exact error your NestJS backend is hitting."
        info "Common causes:"
        echo -e "    ${DIM}1.${NC} The password in .env doesn't match PostgreSQL"
        echo -e "    ${DIM}2.${NC} pg_hba.conf uses 'peer' auth instead of 'md5/scram-sha-256'"
        echo -e "    ${DIM}3.${NC} The user '${db_user}' doesn't exist in PostgreSQL"
        echo ""

        echo -e "  ${BOLD}How would you like to fix this?${NC}"
        echo ""
        echo -e "  ${GREEN}[a]${NC}  Reset the '${db_user}' password in PostgreSQL to match .env"
        echo -e "  ${GREEN}[b]${NC}  Update .env password to match what PostgreSQL expects"
        echo -e "  ${GREEN}[c]${NC}  Fix pg_hba.conf authentication method (peer → md5)"
        echo -e "  ${GREEN}[d]${NC}  Create the user '${db_user}' if it doesn't exist"
        echo -e "  ${GREEN}[e]${NC}  Do all of the above (recommended)"
        echo -e "  ${RED}[s]${NC}  Skip"
        echo ""
        echo -en "  ${CYAN}▶${NC}  Choose [a/b/c/d/e/s]: "

        local fix_choice
        read -r fix_choice

        case "$fix_choice" in
            a|A) fix_pg_password "$db_user" "$db_pass" ;;
            b|B) fix_env_password "$db_user" ;;
            c|C) fix_pg_hba ;;
            d|D) fix_create_user "$db_user" "$db_pass" ;;
            e|E)
                fix_pg_hba
                fix_create_user "$db_user" "$db_pass"
                fix_pg_password "$db_user" "$db_pass"
                ;;
            s|S) info "Skipping authentication fix." ;;
            *) warn "Invalid option. Skipping." ;;
        esac

        # Re-test connection
        echo ""
        info "Re-testing authentication..."
        if PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d postgres -c "SELECT 1;" &>/dev/null; then
            success "Authentication now works! ✅"
            auth_ok=true
        else
            error "Authentication still failing."
            warn "You may need to manually check pg_hba.conf and restart PostgreSQL."
            info "Config file: $(sudo -u postgres psql -t -c 'SHOW hba_file;' 2>/dev/null | xargs || echo '/etc/postgresql/*/main/pg_hba.conf')"
        fi
    fi

    # ── Check 4: Does the database exist? ─────────────────────────────
    echo ""
    echo -e "  ${BOLD}Test 4: Database '${db_name}' Existence${NC}"

    if [ "$auth_ok" = true ]; then
        local db_exists
        db_exists=$(PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${db_name}'" 2>/dev/null || echo "")

        if [ "$db_exists" = "1" ]; then
            status_ok "Database '${db_name}' exists"
        else
            status_fail "Database '${db_name}' does NOT exist"
            issues_found=$((issues_found + 1))

            if confirm "Create database '${db_name}' now?"; then
                PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d postgres -c "CREATE DATABASE ${db_name};" 2>/dev/null
                if [ $? -eq 0 ]; then
                    success "Database '${db_name}' created."
                else
                    warn "Could not create with '${db_user}'. Trying with sudo postgres..."
                    sudo -u postgres psql -c "CREATE DATABASE ${db_name} OWNER ${db_user};" 2>/dev/null
                    if [ $? -eq 0 ]; then
                        success "Database '${db_name}' created (via postgres superuser)."
                    else
                        error "Failed to create database."
                    fi
                fi
            fi
        fi
    else
        status_info "Skipped (authentication not working)"
    fi

    # ── Check 5: Full connection test ─────────────────────────────────
    echo ""
    echo -e "  ${BOLD}Test 5: Full Connection Test (user → database)${NC}"

    if [ "$auth_ok" = true ]; then
        if PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT current_database(), current_user, version();" &>/dev/null; then
            status_ok "Full connection to '${db_name}' as '${db_user}' succeeded!"

            # Show connection details
            echo ""
            local conn_info
            conn_info=$(PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -tAc "SELECT 'DB: ' || current_database() || ' | User: ' || current_user || ' | Version: ' || split_part(version(), ' ', 2);" 2>/dev/null || echo "")
            if [ -n "$conn_info" ]; then
                info "${conn_info}"
            fi
        else
            status_fail "Cannot connect to database '${db_name}'"
            issues_found=$((issues_found + 1))
        fi
    else
        status_info "Skipped (authentication not working)"
    fi

    # ── Summary ───────────────────────────────────────────────────────
    echo ""
    divider
    echo ""

    if [ $issues_found -eq 0 ]; then
        success "${GREEN}${BOLD}All database checks passed! Your NestJS backend should connect fine.${NC}"
        echo ""

        if cmd_exists pm2; then
            local app_registered
            app_registered=$(pm2 jlist 2>/dev/null | grep -o "\"name\":\"${PM2_APP_NAME}\"" || echo "")
            if [ -n "$app_registered" ]; then
                if confirm "Restart the backend application now to apply the fix?"; then
                    pm2 restart "$PM2_APP_NAME"
                    success "Application restarted."
                    echo ""
                    sleep 2
                    # Quick check if it stayed up
                    local app_state
                    app_state=$(pm2 jlist 2>/dev/null | python3 -c "
import sys, json
try:
    apps = json.load(sys.stdin)
    for app in apps:
        if app.get('name') == '${PM2_APP_NAME}':
            print(app.get('pm2_env', {}).get('status', 'unknown'))
            break
except: print('unknown')
" 2>/dev/null || echo "unknown")

                    if [ "$app_state" = "online" ]; then
                        success "Backend is ${GREEN}online${NC} and running!"
                    else
                        warn "Backend status: ${app_state}. Check logs with menu option [3]."
                    fi
                fi
            fi
        fi
    else
        warn "${issues_found} issue(s) found. Review the output above."
        info "After fixing, run this diagnostic again to verify."
    fi

    pause_continue
}

# ─── Sub-function: Reset PostgreSQL user password ────────────────────
fix_pg_password() {
    local username="$1"
    local new_password="$2"

    info "Resetting password for PostgreSQL user '${username}'..."

    sudo -u postgres psql -c "ALTER USER ${username} WITH PASSWORD '${new_password}';" 2>/dev/null
    if [ $? -eq 0 ]; then
        success "Password for '${username}' updated to match .env"
    else
        error "Failed to reset password. You may need to do this manually:"
        echo -e "    ${CYAN}sudo -u postgres psql -c \"ALTER USER ${username} WITH PASSWORD 'your_password';\"${NC}"
    fi
}

# ─── Sub-function: Update .env with the correct password ─────────────
fix_env_password() {
    local username="$1"

    echo ""
    info "Enter the current PostgreSQL password for user '${username}':"
    prompt_secret "Password" "" new_db_pass

    if [ -n "$new_db_pass" ]; then
        sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${new_db_pass}|" "$ENV_FILE"
        success ".env DB_PASSWORD updated."
        # Reload the variable for subsequent checks
        db_pass="$new_db_pass"
    else
        warn "No password entered. Skipping."
    fi
}

# ─── Sub-function: Fix pg_hba.conf (peer → md5) ─────────────────────
fix_pg_hba() {
    info "Checking pg_hba.conf authentication method..."

    # Find pg_hba.conf
    local hba_file
    hba_file=$(sudo -u postgres psql -tAc "SHOW hba_file;" 2>/dev/null | xargs || echo "")

    if [ -z "$hba_file" ]; then
        # Try common locations
        hba_file=$(find /etc/postgresql -name pg_hba.conf 2>/dev/null | head -1)
    fi

    if [ -z "$hba_file" ] || [ ! -f "$hba_file" ]; then
        error "Could not locate pg_hba.conf"
        return 1
    fi

    info "Found: ${hba_file}"

    # Check if there are 'peer' entries for local connections
    local peer_count
    peer_count=$(grep -cE '^local\s+all\s+all\s+peer' "$hba_file" 2>/dev/null || echo "0")
    local ident_count
    ident_count=$(grep -cE '^host\s+all\s+all\s+127\.0\.0\.1.*ident' "$hba_file" 2>/dev/null || echo "0")

    if [ "$peer_count" -gt 0 ] || [ "$ident_count" -gt 0 ]; then
        warn "Found 'peer' or 'ident' authentication (blocks password login)"

        # Create backup
        sudo cp "$hba_file" "${hba_file}.backup.$(date +%Y%m%d_%H%M%S)"
        success "Backup created: ${hba_file}.backup.*"

        # Replace peer with md5 for local connections
        sudo sed -i 's/^local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' "$hba_file"
        # Replace ident with md5 for localhost connections
        sudo sed -i 's/^\(host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+\)ident/\1md5/' "$hba_file"
        sudo sed -i 's/^\(host\s\+all\s\+all\s\+::1\/128\s\+\)ident/\1md5/' "$hba_file"

        success "pg_hba.conf updated: peer/ident → md5"

        # Reload PostgreSQL to apply
        info "Reloading PostgreSQL configuration..."
        sudo systemctl reload postgresql
        success "PostgreSQL configuration reloaded."
    else
        success "pg_hba.conf already uses md5/scram-sha-256. No changes needed."
    fi
}

# ─── Sub-function: Create PostgreSQL user if missing ─────────────────
fix_create_user() {
    local username="$1"
    local password="$2"

    info "Checking if PostgreSQL user '${username}' exists..."

    local user_exists
    user_exists=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${username}'" 2>/dev/null || echo "")

    if [ "$user_exists" = "1" ]; then
        success "User '${username}' already exists."
    else
        info "Creating PostgreSQL user '${username}'..."
        sudo -u postgres psql -c "CREATE USER ${username} WITH PASSWORD '${password}' CREATEDB;" 2>/dev/null
        if [ $? -eq 0 ]; then
            success "User '${username}' created with CREATEDB privilege."
        else
            error "Failed to create user '${username}'."
        fi
    fi
}


# ══════════════════════════════════════════════════════════════════════
#  MAIN MENU LOOP
# ══════════════════════════════════════════════════════════════════════
main() {
    # Ensure we're running on a Linux system
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo ""
        error "This script is designed for Ubuntu/Linux servers."
        error "Detected OS: $(uname -s)"
        exit 1
    fi

    while true; do
        show_banner
        show_menu

        local choice
        read -r choice

        case "$choice" in
            1) check_system_status ;;
            2) configure_nginx ;;
            3) view_pm2_logs ;;
            4) restart_backend ;;
            5) reconfigure_env ;;
            6) diagnose_database ;;
            7)
                echo ""
                echo -e "  ${GREEN}${BOLD}Goodbye! 👋${NC}"
                echo -e "  ${DIM}Payasun Platform Management Dashboard v${VERSION}${NC}"
                echo ""
                exit 0
                ;;
            *)
                warn "Invalid option. Please enter a number between 1 and 7."
                sleep 1
                ;;
        esac
    done
}

# ── Entry Point ───────────────────────────────────────────────────────
main "$@"
