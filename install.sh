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

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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
}

# ============================================================================
# Configuration
# ============================================================================

setup_env_file() {
    print_header "⚙️  Configuration Setup"
    
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

# Timezone
TZ=Europe/London

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
    echo -e "  ${BOLD}qBittorrent${NC}  → http://$SERVER_IP:8080 ${BLUE}(admin/adminadmin)${NC}"
    echo -e "  ${BOLD}Prowlarr${NC}     → http://$SERVER_IP:9696"
    echo -e "  ${BOLD}Sonarr${NC}       → http://$SERVER_IP:8989"
    echo -e "  ${BOLD}Radarr${NC}       → http://$SERVER_IP:7878"
    echo -e "  ${BOLD}Bazarr${NC}       → http://$SERVER_IP:6767"
    echo -e "  ${BOLD}Jellyseerr${NC}   → http://$SERVER_IP:5055"
    echo -e "  ${BOLD}Firefox${NC}      → http://$SERVER_IP:3000"
    echo ""
    echo -e "${YELLOW}Management Services:${NC}"
    echo -e "  ${BOLD}Plex${NC}         → http://$SERVER_IP:32400/web"
    echo -e "  ${BOLD}Portainer${NC}    → http://$SERVER_IP:9000"
    echo -e "  ${BOLD}Heimdall${NC}     → http://$SERVER_IP:8081"
    echo -e "  ${BOLD}Filebrowser${NC}  → http://$SERVER_IP:8443 ${BLUE}(admin/admin)${NC}"
    echo ""
    
    print_box "⚠  SECURITY: Change all default passwords!" "$RED"
    
    echo -e "${CYAN}${BOLD}📚 Useful Commands:${NC}"
    echo -e "  ${BOLD}View logs:${NC}      docker compose logs -f"
    echo -e "  ${BOLD}Stop stack:${NC}     docker compose down"
    echo -e "  ${BOLD}Restart:${NC}        docker compose restart"
    echo -e "  ${BOLD}Update images:${NC}  docker compose pull && docker compose up -d"
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
        
        # Get absolute path of this script - use multiple methods for reliability
        if [ -n "$BASH_SOURCE" ]; then
            SCRIPT_PATH="$(cd "$(dirname "$BASH_SOURCE")" && pwd)/$(basename "$BASH_SOURCE")"
        elif [ -L "$0" ]; then
            SCRIPT_PATH="$(readlink -f "$0")"
        else
            SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
        fi
        
        # Create a helper script to re-execute
        HELPER="/tmp/media-stack-helper-$$.sh"
        cat > "$HELPER" << HELPER_EOF
#!/bin/bash
exec "$SCRIPT_PATH"
HELPER_EOF
        chmod +x "$HELPER"
        
        # Re-execute using the helper with sg
        exec sg docker "$HELPER"
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
