#!/bin/bash

# ============================================================================
# Media Stack - All-in-One Installation Script
# ============================================================================
# This script handles everything:
# - Downloads files from GitHub (if needed)
# - Installs dependencies (Docker, Docker Compose, Git)
# - Interactive configuration
# - Deploys the media stack!
# ============================================================================

set -e  # Exit on error

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# GitHub repository
GITHUB_REPO="https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main"

# Installation directory
INSTALL_DIR="$HOME/media-stack"

# Create and move to installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# ============================================================================
# Display Functions
# ============================================================================

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║          🎬  MEDIA STACK INSTALLER  🎬                  ║"
    echo "║                                                          ║"
    echo "║          Automated Setup & Deployment                    ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}  ✓${NC} $1"
}

print_error() {
    echo -e "${RED}  ✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}  ⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}  ℹ${NC} $1"
}

print_step() {
    echo -e "${MAGENTA}  ▸${NC} $1"
}

print_box() {
    local message="$1"
    local color="${2:-$CYAN}"
    echo ""
    echo -e "${color}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${color}│  ${BOLD}${message}${NC}${color}  │${NC}"
    echo -e "${color}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ============================================================================
# System Checks
# ============================================================================

check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root"
        print_info "Run it as a regular user with sudo privileges"
        exit 1
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
}

# ============================================================================
# Installation Functions
# ============================================================================

install_dependencies() {
    print_header "📦 Installing System Dependencies"
    
    detect_os
    print_info "Detected: ${BOLD}$OS $OS_VERSION${NC}"
    
    case $OS in
        ubuntu|debian)
            print_step "Updating package lists..."
            sudo apt-get update -qq
            
            print_step "Installing required packages..."
            sudo apt-get install -y -qq \
                git curl wget ca-certificates gnupg lsb-release jq net-tools \
                2>&1 | grep -v "^Reading" | grep -v "^Building" || true
            
            print_success "System dependencies installed"
            ;;
        centos|rhel|fedora)
            print_step "Installing required packages..."
            sudo yum install -y -q git curl wget ca-certificates jq net-tools
            print_success "System dependencies installed"
            ;;
        *)
            print_warning "Unsupported OS: $OS"
            print_info "Please install git, curl, wget, and jq manually"
            ;;
    esac
}

install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed ($(docker --version | cut -d' ' -f3 | tr -d ','))"
        return
    fi
    
    print_header "🐳 Installing Docker"
    
    detect_os
    
    print_step "Downloading Docker installation script..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    
    print_step "Running Docker installation..."
    sudo sh /tmp/get-docker.sh > /dev/null 2>&1
    rm /tmp/get-docker.sh
    
    print_step "Starting Docker service..."
    sudo systemctl enable docker > /dev/null 2>&1
    sudo systemctl start docker
    
    print_success "Docker installed successfully"
    
    # Add user to docker group
    print_step "Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    print_box "⚠  IMPORTANT: Docker Group Added" "$YELLOW"
    print_warning "You need to log out and back in for docker group changes to take effect"
    print_info "Or run: ${BOLD}newgrp docker && $0${NC}"
    echo ""
    read -p "Press Enter to continue after running 'newgrp docker' in a new terminal..."
}

install_docker_compose() {
    if docker compose version &> /dev/null; then
        print_success "Docker Compose is already installed ($(docker compose version --short))"
        return
    fi
    
    print_header "🔧 Installing Docker Compose"
    
    detect_os
    
    case $OS in
        ubuntu|debian)
            print_step "Installing Docker Compose plugin..."
            sudo apt-get update -qq
            sudo apt-get install -y -qq docker-compose-plugin
            ;;
        centos|rhel|fedora)
            print_step "Installing Docker Compose plugin..."
            sudo yum install -y -q docker-compose-plugin
            ;;
        *)
            print_error "Unsupported OS for automatic Docker Compose installation"
            exit 1
            ;;
    esac
    
    print_success "Docker Compose installed successfully"
}

download_files() {
    print_header "📥 Downloading Media Stack Files"
    
    local files=("docker-compose.yml" ".env.example" ".gitignore")
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            print_info "File exists: $file (skipping)"
        else
            print_step "Downloading: $file"
            curl -fsSL "$GITHUB_REPO/$file" -o "$file"
            print_success "Downloaded: $file"
        fi
    done
    
    # Download docker-data-templates directory if it doesn't exist
    if [ ! -d "docker-data-templates" ]; then
        print_step "Downloading preconfigured templates..."
        
        # Create the directory structure
        mkdir -p docker-data-templates/qbittorrent/config/qBittorrent
        
        # Download qBittorrent template files
        # Note: This is a simplified approach. For production, you might want to use git clone
        # or download a zip archive of the templates directory
        print_info "Template directory created at: $INSTALL_DIR/docker-data-templates"
        print_warning "Please manually copy your docker-data-templates from your repository"
        print_info "Or the installer will skip template deployment"
    else
        print_success "Template directory already exists"
    fi
}


# ============================================================================
# Configuration
# ============================================================================

setup_env_file() {
    print_header "⚙️  Configuration Setup"
    
    echo -e "${CYAN}${BOLD}Installation Directory:${NC} ${GREEN}$INSTALL_DIR${NC}"
    echo ""
    
    if [ -f ".env" ]; then
        print_warning ".env file already exists"
        echo ""
        read -p "  Do you want to reconfigure it? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return
        fi
        echo ""
    fi
    
    # Docker data directory
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}📁 Docker Data Directory${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo "  Where Docker stores container configs and databases"
    echo -e "  ${BLUE}Example:${NC} /home/$USER/docker-data or /data/docker"
    echo ""
    read -p "  Path [/home/$USER/docker-data]: " DOCKER_DATA_DIR
    DOCKER_DATA_DIR=${DOCKER_DATA_DIR:-/home/$USER/docker-data}
    echo ""
    
    # Media path
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}🎬 Media Files Directory${NC}                              ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo "  Where movies, TV shows, and downloads will be stored"
    echo "  This should be a large storage location"
    echo -e "  ${BLUE}Example:${NC} /home/$USER/media or /mnt/media"
    echo ""
    read -p "  Path [/home/$USER/media]: " MEDIA_PATH
    MEDIA_PATH=${MEDIA_PATH:-/home/$USER/media}
    echo ""
    
    # Surfshark WireGuard key
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}🔐 Surfshark VPN Configuration${NC}                        ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo "  Your WireGuard private key from Surfshark"
    echo -e "  ${GREEN}Get it from:${NC} https://my.surfshark.com/vpn/manual-setup/main/wireguard"
    echo -e "  ${YELLOW}Steps:${NC} Login → Manual Setup → WireGuard → Copy Private Key"
    echo ""
    read -p "  WireGuard Private Key: " SURFSHARK_KEY
    while [ -z "$SURFSHARK_KEY" ]; do
        echo -e "${RED}  ✗ VPN key is required!${NC}"
        read -p "  WireGuard Private Key: " SURFSHARK_KEY
    done
    echo ""
    
    # Server IP (auto-detected)
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}🌐 Server IP Address${NC}                                  ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${GREEN}Auto-detected:${NC} ${BOLD}$SERVER_IP${NC}"
    echo "  Press Enter to use this, or type a different IP"
    echo ""
    read -p "  Server IP [$SERVER_IP]: " INPUT_IP
    SERVER_IP=${INPUT_IP:-$SERVER_IP}
    echo ""
    
    # Plex claim token
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}📺 Plex Media Server (Optional)${NC}                       ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo "  Claim token to link Plex to your account"
    echo -e "  ${GREEN}Get it from:${NC} https://www.plex.tv/claim/"
    echo -e "  ${YELLOW}⚠  Token expires in 4 minutes!${NC}"
    echo "  Press Enter to skip if you'll configure Plex later"
    echo ""
    read -p "  Plex Claim Token (optional): " PLEX_TOKEN
    echo ""
    
    # Preconfigured templates
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}⚙️  Preconfigured ARR Stack Templates${NC}                 ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────┘${NC}"
    echo "  Use preconfigured settings for ARR services?"
    echo -e "  ${GREEN}Includes:${NC} Radarr, Sonarr, Prowlarr, Qbittorrent, Jellyseerr"
    echo -e "  ${YELLOW}Default credentials:${NC} admin / MediaStack@S3cure"
    echo -e "  ${BLUE}Note:${NC} You can change passwords after installation"
    echo ""
    read -p "  Use preconfigured templates? (Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        USE_TEMPLATES="false"
        print_info "Templates disabled - services will start unconfigured"
    else
        USE_TEMPLATES="true"
        print_success "Templates enabled - services will use preconfigured settings"
    fi
    echo ""
    
    
    # Detect Docker Socket Group ID (Source of Truth via container)
    # This ensures we get the internal GID (e.g., 999) even on macOS Docker Desktop
    DOCKER_GID=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock alpine stat -c '%g' /var/run/docker.sock 2>/dev/null || echo "0")
    # Clean up any potential whitespace/CR
    DOCKER_GID=$(echo "$DOCKER_GID" | tr -d '\r')
    print_info "Detected Docker Socket GID: $DOCKER_GID"

    # Create .env file
    cat > .env << EOF
# ============================================================================
# Media Stack Environment Variables
# Generated on $(date)
# ============================================================================

# Directory Paths
DOCKER_DATA_DIR=$DOCKER_DATA_DIR
MEDIA_PATH=$MEDIA_PATH

# VPN Configuration
SURFSHARK_WIREGUARD_KEY=$SURFSHARK_KEY

# Plex Configuration
USERNAME=$USER
SERVER_IP=$SERVER_IP
PLEX_CLAIM_TOKEN=$PLEX_TOKEN

# User/Group IDs
PUID=1000
PGID=1000
DOCKER_GID=$DOCKER_GID

# Timezone
TZ=Europe/London

# Template Configuration
USE_TEMPLATES=$USE_TEMPLATES

# Network Configuration
DOCKER_NETWORK_SUBNET=172.20.0.0/16
DOCKER_NETWORK_GATEWAY=172.20.0.1
LOCAL_NETWORK_SUBNET=192.168.50.0/24
EOF
    
    print_success "Configuration saved to .env file"
}

# ============================================================================
# Directory Setup
# ============================================================================

create_directories() {
    print_header "📁 Creating Directories"
    
    source .env
    
    # Docker data directory
    if [ ! -d "$DOCKER_DATA_DIR" ]; then
        print_step "Creating: $DOCKER_DATA_DIR"
        mkdir -p "$DOCKER_DATA_DIR"
        print_success "Created Docker data directory"
    else
        print_success "Using existing: $DOCKER_DATA_DIR"
    fi
    
    # Media directory
    if [ ! -d "$MEDIA_PATH" ]; then
        print_step "Creating: $MEDIA_PATH"
        mkdir -p "$MEDIA_PATH"/{Movies,TV\ Shows,downloads}
        print_success "Created media directory"
        print_info "  └─ Subdirectories: Movies, TV Shows, downloads"
    else
        print_success "Using existing: $MEDIA_PATH"
    fi
    
    # Set permissions
    print_step "Setting permissions (UID:GID 1000:1000)..."
    sudo chown -R 1000:1000 "$DOCKER_DATA_DIR" 2>/dev/null || true
    sudo chown -R 1000:1000 "$MEDIA_PATH" 2>/dev/null || true
    print_success "Permissions configured"
    
    # Setup Homepage Config
    setup_homepage
}

setup_homepage() {
    print_step "Configuring Homepage dashboard..."
    mkdir -p "$DOCKER_DATA_DIR/homepage"
    
    # Create docker.yaml for socket access
    cat > "$DOCKER_DATA_DIR/homepage/docker.yaml" << EOF
my-docker:
  socket: /var/run/docker.sock
EOF

    # Create settings.yaml (Layout & Customization)
    # Management top, Media bottom, Custom Background
    cat > "$DOCKER_DATA_DIR/homepage/settings.yaml" << EOF
title: Media Stack
headerStyle: clean
background:
  image: https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=2072
  brightness: 50
layout:
  Management:
    style: row
    columns: 2
  Media:
    style: row
    columns: 4
EOF

    # Create widgets.yaml (Time, Date, Resources)
    cat > "$DOCKER_DATA_DIR/homepage/widgets.yaml" << EOF
- greeting:
    text_size: 2xl
    text: Media Center
- resources:
    cpu: true
    memory: true
    disk: /
- datetime:
    format:
      dateStyle: short
      timeStyle: short
EOF

    # Create empty services.yaml (Remove default groups)
    cat > "$DOCKER_DATA_DIR/homepage/services.yaml" << EOF
[]
EOF

    # Create empty bookmarks.yaml (Remove default bookmarks)
    cat > "$DOCKER_DATA_DIR/homepage/bookmarks.yaml" << EOF
[]
EOF

    # Set permissions
    sudo chown -R 1000:1000 "$DOCKER_DATA_DIR/homepage" 2>/dev/null || true
    print_success "Homepage configured for Docker discovery"
}

# ============================================================================
# Template Deployment
# ============================================================================

deploy_preconfigured_templates() {
    local CURRENT_DIR=$(pwd)
    source .env
    
    # Check if templates are enabled
    if [ "$USE_TEMPLATES" != "true" ]; then
        return
    fi
    
    print_header "📦 Deploying Preconfigured Templates"
    
    # GitHub repository details
    local GITHUB_REPO_URL="https://github.com/myfreedev/media_stack.git"
    local TEMP_DIR=$(mktemp -d)
    
    print_step "Downloading preconfigured templates from GitHub..."
    
    # Clone only the docker-data-templates directory using sparse checkout
    cd "$TEMP_DIR"
    git init -q
    git remote add origin "$GITHUB_REPO_URL"
    git config core.sparseCheckout true
    echo "docker-data-templates/*" >> .git/info/sparse-checkout
    
    if git pull -q --depth=1 origin main 2>/dev/null; then
        print_success "Templates downloaded from GitHub"
        
        # Copy all service folders from docker-data-templates to DOCKER_DATA_DIR
        if [ -d "docker-data-templates" ]; then
            local deployed_count=0
            local services_list=""
            
            for service_dir in docker-data-templates/*; do
                if [ -d "$service_dir" ]; then
                    local service_name=$(basename "$service_dir")
                    
                    print_step "Deploying $service_name preconfigured data..."
                    
                    # Copy entire service folder to DOCKER_DATA_DIR
                    cp -r "$service_dir" "$DOCKER_DATA_DIR/" 2>/dev/null || true
                    
                    # Set permissions
                    sudo chown -R 1000:1000 "$DOCKER_DATA_DIR/$service_name" 2>/dev/null || true
                    
                    print_success "$service_name template deployed"
                    print_info "  └─ Deployed to: $DOCKER_DATA_DIR/$service_name"
                    
                    # Extract API Key to .env (for Homepage widgets)
                    # Convert service name to UPPERCASE for variable naming
                    local service_upper=$(echo "$service_name" | tr '[:lower:]' '[:upper:]')
                    if [[ "$service_upper" == "PROWLARR" || "$service_upper" == "SONARR" || "$service_upper" == "RADARR" ]]; then
                        local config_file=$(find "$DOCKER_DATA_DIR/$service_name" -name "config.xml" | head -n 1)
                        if [ -f "$config_file" ]; then
                            # Extract content between <ApiKey> tags
                            local api_key=$(sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "$config_file" | tr -d '\r')
                            
                            if [ ! -z "$api_key" ]; then
                                local env_var="${service_upper}_API_KEY"
                                # Append to .env in the original directory
                                if ! grep -q "^$env_var=" "$CURRENT_DIR/.env"; then
                                    echo "$env_var=$api_key" >> "$CURRENT_DIR/.env"
                                    print_info "  └─ Extracted API Key to .env: $env_var"
                                fi
                            fi
                        fi
                    fi
                    
                    # Inject Preconfigured Portainer Token
                    if [[ "$service_upper" == "PORTAINER" ]]; then
                         local portainer_token="ptr_3w05LC6Ky4yv0t5JcPBPHXNhW2Jop/Qah/YsvEGMYk8="
                         if ! grep -q "^PORTAINER_TOKEN=" "$CURRENT_DIR/.env"; then
                             echo "PORTAINER_TOKEN=$portainer_token" >> "$CURRENT_DIR/.env"
                             print_info "  └─ Injected Portainer Token to .env"
                         fi
                    fi
                    
                    deployed_count=$((deployed_count + 1))
                    services_list="$services_list$service_name, "
                fi
            done
            
            # Show summary
            if [ $deployed_count -gt 0 ]; then
                services_list=${services_list%, }  # Remove trailing comma
                echo ""
                print_success "Deployed $deployed_count service template(s): $services_list"
                print_info "Default credentials: admin / MediaStack@S3cure"
            fi
        fi
    else
        print_warning "Could not download templates from GitHub"
        print_info "Continuing without preconfigured templates..."
    fi
    
    # Cleanup temp directory
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo ""
    print_box "⚠  SECURITY: Change default passwords after first login!" "$RED"
}

# ============================================================================
# Docker Operations
# ============================================================================

cleanup() {
    print_header "🧹 Cleaning Up"
    
    print_step "Stopping existing containers..."
    docker compose down 2>/dev/null || true
    
    print_step "Removing orphaned containers..."
    docker container prune -f > /dev/null 2>&1
    
    print_step "Removing orphaned networks..."
    docker network prune -f > /dev/null 2>&1
    
    print_success "Cleanup completed"
}

start_stack() {
    print_header "🚀 Deploying Media Stack"
    
    print_step "Pulling Docker images..."
    docker compose pull 2>&1 | grep -E "Pulling|Downloaded|Status" || true
    
    print_step "Starting containers..."
    docker compose up -d
    
    print_step "Waiting for containers to initialize..."
    sleep 5
    
    print_success "All containers started"
}

check_status() {
    print_header "📊 Container Status"
    
    echo ""
    docker compose ps
    echo ""
    
    # Check for unhealthy containers
    UNHEALTHY=$(docker compose ps --format json 2>/dev/null | jq -r 'select(.Health == "unhealthy") | .Name' 2>/dev/null || true)
    
    if [ -z "$UNHEALTHY" ]; then
        print_success "All containers are healthy!"
    else
        print_warning "Some containers are unhealthy:"
        echo "$UNHEALTHY"
    fi
}

# ============================================================================
# Final Information
# ============================================================================

show_access_info() {
    source .env
    
    print_header "🎉 Installation Complete!"
    
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║          ✓  MEDIA STACK IS NOW RUNNING!  ✓             ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}🌐 Access Your Services:${NC}"
    echo ""
    echo -e "${YELLOW}VPN-Protected Services (via Gluetun):${NC}"
    
    # Show credentials based on template usage
    if [ "$USE_TEMPLATES" = "true" ]; then
        echo -e "  ${BOLD}qBittorrent${NC}  → http://$SERVER_IP:8080 ${BLUE}(admin/MediaStack@S3cure)${NC}"
        echo -e "  ${BOLD}Prowlarr${NC}     → http://$SERVER_IP:9696 ${BLUE}(No auth / admin/MediaStack@S3cure)${NC}"
        echo -e "  ${BOLD}Sonarr${NC}       → http://$SERVER_IP:8989 ${BLUE}(No auth / admin/MediaStack@S3cure)${NC}"
        echo -e "  ${BOLD}Radarr${NC}       → http://$SERVER_IP:7878 ${BLUE}(No auth / admin/MediaStack@S3cure)${NC}"
        echo -e "  ${BOLD}Bazarr${NC}       → http://$SERVER_IP:6767 ${BLUE}(No auth / admin/MediaStack@S3cure)${NC}"
    else
        echo -e "  ${BOLD}qBittorrent${NC}  → http://$SERVER_IP:8080 ${BLUE}(admin/adminadmin)${NC}"
        echo -e "  ${BOLD}Prowlarr${NC}     → http://$SERVER_IP:9696"
        echo -e "  ${BOLD}Sonarr${NC}       → http://$SERVER_IP:8989"
        echo -e "  ${BOLD}Radarr${NC}       → http://$SERVER_IP:7878"
        echo -e "  ${BOLD}Bazarr${NC}       → http://$SERVER_IP:6767"
    fi
    
    echo -e "  ${BOLD}Jellyseerr${NC}   → http://$SERVER_IP:5055 ${YELLOW}-- need to configure manually${NC}"
    echo -e "  ${BOLD}Brave${NC}        → https://$SERVER_IP:3000 ${BLUE}(admin/MediaStack@S3cure)${NC}"
    echo ""
    echo -e "${YELLOW}Management Services:${NC}"
    echo -e "  ${BOLD}Plex${NC}         → http://$SERVER_IP:32400/web ${YELLOW}-- need to configure manually${NC}"
    
    if [ "$USE_TEMPLATES" = "true" ]; then
        echo -e "  ${BOLD}Portainer${NC}    → http://$SERVER_IP:9000 ${BLUE}(admin/MediaStack@S3cure)${NC}"
    else
        echo -e "  ${BOLD}Portainer${NC}    → http://$SERVER_IP:9000"
    fi

    echo -e "  ${BOLD}Homepage${NC}     → http://$SERVER_IP:3001"
    
    if [ "$USE_TEMPLATES" = "true" ]; then
        echo -e "  ${BOLD}Filebrowser${NC}  → http://$SERVER_IP:8443 ${BLUE}(admin/MediaStack@S3cure)${NC}"
    else
        echo -e "  ${BOLD}Filebrowser${NC}  → http://$SERVER_IP:8443 ${BLUE}(admin/admin)${NC}"
    fi

    echo ""
    
    # Show template credentials summary if enabled
    if [ "$USE_TEMPLATES" = "true" ]; then
        echo -e "${CYAN}${BOLD}🔐 Preconfigured Template Credentials:${NC}"
        echo -e "  ${GREEN}Username:${NC} admin"
        echo -e "  ${GREEN}Password:${NC} MediaStack@S3cure"
        
        # Build list of services detected in templates
        local detected_services=""
        if [ -d "$INSTALL_DIR/docker-data-templates" ]; then
            for d in "$INSTALL_DIR/docker-data-templates/"*; do
                if [ -d "$d" ]; then
                    detected_services="$detected_services$(basename "$d"), "
                fi
            done
            # Remove trailing comma and space
            detected_services=${detected_services%, }
        fi
        
        # Fallback if no specific folders detected but templates enabled
        if [ -z "$detected_services" ]; then
             detected_services="qBittorrent, Prowlarr, Sonarr, Radarr, Bazarr"
        fi
        
        echo -e "  ${YELLOW}Services:${NC} $detected_services"
        echo ""
    fi
    
        print_box "⚠  SECURITY: Change all default passwords!" "$RED"
    
    echo -e "${CYAN}${BOLD} Installation Directory:${NC}"
    echo -e "  ${BOLD}$INSTALL_DIR${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}📚 Useful Commands:${NC}"
    echo -e "  ${BOLD}Go to directory:${NC} cd $INSTALL_DIR"
    echo -e "  ${BOLD}View logs:${NC}       docker compose logs -f"
    echo -e "  ${BOLD}Stop stack:${NC}      docker compose down"
    echo -e "  ${BOLD}Restart:${NC}         docker compose restart"
    echo -e "  ${BOLD}Update images:${NC}   docker compose pull && docker compose up -d"
    echo ""
    
    # Show manual configuration steps for Plex and Jellyseerr
    echo -e "${YELLOW}${BOLD}📝 Manual Configuration Required:${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}1. Configure Plex Media Server:${NC}"
    echo -e "   ${BOLD}URL:${NC} http://$SERVER_IP:32400/web"
    echo -e "   ${BOLD}Steps:${NC}"
    echo "   • Sign in with your Plex account (or create one)"
    echo "   • Name your server"
    echo "   • Add media libraries:"
    echo -e "     - Movies: ${GREEN}$MEDIA_PATH/Movies${NC}"
    echo -e "     - TV Shows: ${GREEN}$MEDIA_PATH/TV Shows${NC}"
    echo "   • Complete the setup wizard"
    echo ""
    echo -e "${CYAN}${BOLD}2. Configure Jellyseerr:${NC}"
    echo -e "   ${BOLD}URL:${NC} http://$SERVER_IP:5055"
    echo -e "   ${BOLD}Steps:${NC}"
    echo "   • Sign in with your Plex account"
    echo "   • Connect to your Plex server (should auto-detect)"
    echo "   • Configure Sonarr connection:"
    echo -e "     - URL: ${GREEN}http://sonarr:8989${NC}"
    echo "     - API Key: (get from Sonarr settings)"
    echo "   • Configure Radarr connection:"
    echo -e "     - URL: ${GREEN}http://radarr:7878${NC}"
    echo "     - API Key: (get from Radarr settings)"
    echo ""
    echo -e "${BLUE}${BOLD}ℹ  Note:${NC} Plex and Jellyseerr require your personal account"
    echo -e "   and cannot be preconfigured with templates."
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    print_banner
    
    check_root
    
    # Check prerequisites
    print_header "🔍 Checking Prerequisites"
    
    if ! command -v git &> /dev/null; then
        print_warning "Git is not installed"
        install_dependencies
    else
        print_success "Git is installed"
    fi
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed"
        install_docker
    else
        print_success "Docker is installed"
    fi
    
    if ! docker compose version &> /dev/null; then
        print_warning "Docker Compose is not installed"
        install_docker_compose
    else
        print_success "Docker Compose is installed"
    fi
    
    # Check docker group and auto-fix
    if ! groups | grep -q docker; then
        print_warning "User is not in docker group"
        print_step "Adding user to docker group..."
        sudo usermod -aG docker $USER
        print_success "User added to docker group"
        
        print_info "Activating docker group and continuing installation..."
        echo ""
        
        # Determine script path
        if [ -f "$BASH_SOURCE" ]; then
            # Script exists as a file
            SCRIPT_PATH="$(cd "$(dirname "$BASH_SOURCE")" && pwd)/$(basename "$BASH_SOURCE")"
        else
            # Script is being piped (from curl), download it
            SCRIPT_PATH="/tmp/media-stack-installer-$$.sh"
            print_step "Downloading installer..."
            curl -fsSL "$GITHUB_REPO/install.sh" -o "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
        fi
        
        # Re-execute with docker group active
        exec sg docker "$SCRIPT_PATH"
    fi
    
    print_success "User is in docker group"
    
    # Download files if needed
    if [ ! -f "docker-compose.yml" ]; then
        download_files
    else
        print_success "Media stack files already present"
    fi
    
    # Setup
    setup_env_file
    create_directories
    deploy_preconfigured_templates
    cleanup
    start_stack
    check_status
    show_access_info
    
    echo ""
    print_box "🎊 Enjoy your media stack!" "$GREEN"
    echo ""
}

# Run main function
main "$@"
