#!/bin/bash

# Media Stack Setup Script
# This script automates the setup and deployment of the media stack

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root"
        print_info "Run it as a regular user with sudo privileges"
        exit 1
    fi
    
    # Check if user has sudo privileges
    if ! sudo -n true 2>/dev/null; then
        print_error "This script requires sudo privileges"
        print_info "Please run: sudo -v"
        exit 1
    fi
}

# Detect OS
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

# Install system dependencies
install_dependencies() {
    print_header "Installing System Dependencies"
    
    detect_os
    
    case $OS in
        ubuntu|debian)
            print_info "Detected: $OS $OS_VERSION"
            print_info "Updating package lists..."
            sudo apt-get update -qq
            
            print_info "Installing required packages..."
            sudo apt-get install -y -qq \
                git \
                curl \
                wget \
                ca-certificates \
                gnupg \
                lsb-release \
                jq \
                net-tools
            
            print_success "System dependencies installed"
            ;;
        centos|rhel|fedora)
            print_info "Detected: $OS $OS_VERSION"
            print_info "Installing required packages..."
            sudo yum install -y -q \
                git \
                curl \
                wget \
                ca-certificates \
                jq \
                net-tools
            
            print_success "System dependencies installed"
            ;;
        *)
            print_warning "Unsupported OS: $OS"
            print_info "Please install git, curl, wget, and jq manually"
            ;;
    esac
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed"
        return
    fi
    
    print_header "Installing Docker"
    
    detect_os
    
    case $OS in
        ubuntu|debian)
            print_info "Installing Docker for $OS..."
            
            # Remove old versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # Install Docker using official script
            print_info "Downloading Docker installation script..."
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            
            print_info "Running Docker installation..."
            sudo sh /tmp/get-docker.sh
            rm /tmp/get-docker.sh
            
            # Start Docker service
            sudo systemctl enable docker
            sudo systemctl start docker
            
            print_success "Docker installed successfully"
            ;;
        centos|rhel|fedora)
            print_info "Installing Docker for $OS..."
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sudo sh /tmp/get-docker.sh
            rm /tmp/get-docker.sh
            
            sudo systemctl enable docker
            sudo systemctl start docker
            
            print_success "Docker installed successfully"
            ;;
        *)
            print_error "Unsupported OS for automatic Docker installation"
            print_info "Please install Docker manually: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # Add user to docker group
    print_info "Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    print_warning "You need to log out and back in for docker group changes to take effect"
    print_info "Or run: newgrp docker"
}

# Install Docker Compose
install_docker_compose() {
    if docker compose version &> /dev/null; then
        print_success "Docker Compose is already installed"
        return
    fi
    
    print_header "Installing Docker Compose"
    
    detect_os
    
    case $OS in
        ubuntu|debian)
            print_info "Installing Docker Compose plugin..."
            sudo apt-get update -qq
            sudo apt-get install -y -qq docker-compose-plugin
            print_success "Docker Compose installed successfully"
            ;;
        centos|rhel|fedora)
            print_info "Installing Docker Compose plugin..."
            sudo yum install -y -q docker-compose-plugin
            print_success "Docker Compose installed successfully"
            ;;
        *)
            print_error "Unsupported OS for automatic Docker Compose installation"
            print_info "Please install Docker Compose manually"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_warning "Git is not installed"
        install_dependencies
    else
        print_success "Git is installed"
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed"
        install_docker
    else
        print_success "Docker is installed"
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        print_warning "Docker Compose is not installed"
        install_docker_compose
    else
        print_success "Docker Compose is installed"
    fi
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        print_warning "User is not in docker group"
        print_info "Adding user to docker group..."
        sudo usermod -aG docker $USER
        print_warning "You need to log out and back in for group changes to take effect"
        print_info "After logging back in, run this script again"
        print_info "Or run: newgrp docker && ./setup.sh"
        exit 0
    fi
    print_success "User is in docker group"
}

# Create .env file if it doesn't exist
setup_env_file() {
    print_header "Setting Up Environment Variables"
    
    if [ -f ".env" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to reconfigure it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return
        fi
    fi
    
    print_info "Creating .env file from template..."
    
    # Prompt for required variables
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}   Configuration Setup${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Docker data directory
    echo -e "${BLUE}📁 Docker Data Directory${NC}"
    echo "   Where Docker will store container configurations and databases"
    echo "   Example: /home/$USER/docker-data or /data/docker"
    echo ""
    read -p "   Path [/home/$USER/docker-data]: " DOCKER_DATA_DIR
    DOCKER_DATA_DIR=${DOCKER_DATA_DIR:-/home/$USER/docker-data}
    echo ""
    
    # Media path
    echo -e "${BLUE}🎬 Media Files Directory${NC}"
    echo "   Where your movies, TV shows, and downloads will be stored"
    echo "   This should be a large storage location"
    echo "   Example: /home/$USER/media or /mnt/media"
    echo ""
    read -p "   Path [/home/$USER/media]: " MEDIA_PATH
    MEDIA_PATH=${MEDIA_PATH:-/home/$USER/media}
    echo ""
    
    # Surfshark WireGuard key
    echo -e "${BLUE}🔐 Surfshark VPN Configuration${NC}"
    echo "   Your WireGuard private key from Surfshark"
    echo "   Get it from: ${GREEN}https://my.surfshark.com/vpn/manual-setup/main/wireguard${NC}"
    echo "   (Login → Manual Setup → WireGuard → Copy Private Key)"
    echo ""
    read -p "   WireGuard Private Key: " SURFSHARK_KEY
    while [ -z "$SURFSHARK_KEY" ]; do
        echo -e "${RED}   ✗ VPN key is required!${NC}"
        read -p "   WireGuard Private Key: " SURFSHARK_KEY
    done
    echo ""
    
    # Username (auto-detected)
    USERNAME=${USER}
    
    # Server IP (auto-detected)
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "${BLUE}🌐 Server IP Address${NC}"
    echo "   Auto-detected: ${GREEN}$SERVER_IP${NC}"
    echo "   Press Enter to use this, or type a different IP"
    echo ""
    read -p "   Server IP [$SERVER_IP]: " INPUT_IP
    SERVER_IP=${INPUT_IP:-$SERVER_IP}
    echo ""
    
    # Plex claim token
    echo -e "${BLUE}📺 Plex Media Server (Optional)${NC}"
    echo "   Claim token to link Plex to your account"
    echo "   Get it from: ${GREEN}https://www.plex.tv/claim/${NC}"
    echo "   ${YELLOW}⚠  Token expires in 4 minutes!${NC}"
    echo "   Press Enter to skip if you'll configure Plex later"
    echo ""
    read -p "   Plex Claim Token (optional): " PLEX_TOKEN
    echo ""
    
    # Create .env file
    cat > .env << EOF
# ============================================================================
# Media Stack Environment Variables
# Generated on $(date)
# ============================================================================

# ----------------------------------------------------------------------------
# Directory Paths
# ----------------------------------------------------------------------------
DOCKER_DATA_DIR=$DOCKER_DATA_DIR
MEDIA_PATH=$MEDIA_PATH

# ----------------------------------------------------------------------------
# VPN Configuration (Surfshark WireGuard)
# ----------------------------------------------------------------------------
SURFSHARK_WIREGUARD_KEY=$SURFSHARK_KEY

# ----------------------------------------------------------------------------
# Plex Configuration
# ----------------------------------------------------------------------------
USERNAME=$USERNAME
SERVER_IP=$SERVER_IP
PLEX_CLAIM_TOKEN=$PLEX_TOKEN

# ----------------------------------------------------------------------------
# User/Group IDs
# ----------------------------------------------------------------------------
PUID=1000
PGID=1000

# ----------------------------------------------------------------------------
# Timezone
# ----------------------------------------------------------------------------
TZ=Europe/London

# ----------------------------------------------------------------------------
# Network Configuration
# ----------------------------------------------------------------------------
DOCKER_NETWORK_SUBNET=172.20.0.0/16
DOCKER_NETWORK_GATEWAY=172.20.0.1
LOCAL_NETWORK_SUBNET=192.168.50.0/24
EOF
    
    print_success ".env file created successfully"
}

# Create required directories
create_directories() {
    print_header "Creating Required Directories"
    
    # Source .env file
    if [ -f ".env" ]; then
        source .env
    else
        print_error ".env file not found"
        exit 1
    fi
    
    # Create Docker data directory
    if [ ! -d "$DOCKER_DATA_DIR" ]; then
        print_info "Creating Docker data directory: $DOCKER_DATA_DIR"
        mkdir -p "$DOCKER_DATA_DIR"
        print_success "✓ Created: $DOCKER_DATA_DIR"
    else
        print_success "✓ Using existing directory: $DOCKER_DATA_DIR"
    fi
    
    # Create media directory structure
    if [ ! -d "$MEDIA_PATH" ]; then
        print_info "Creating media directory: $MEDIA_PATH"
        mkdir -p "$MEDIA_PATH"/{Movies,TV\ Shows,downloads}
        print_success "✓ Created: $MEDIA_PATH"
        print_info "  └─ Subdirectories: Movies, TV Shows, downloads"
    else
        print_success "✓ Using existing directory: $MEDIA_PATH"
    fi
    
    # Set permissions
    print_info "Setting directory permissions (UID:GID 1000:1000)..."
    sudo chown -R 1000:1000 "$DOCKER_DATA_DIR" 2>/dev/null || true
    sudo chown -R 1000:1000 "$MEDIA_PATH" 2>/dev/null || true
    print_success "✓ Permissions configured"
}

# Clean up existing containers and networks
cleanup() {
    print_header "Cleaning Up Existing Resources"
    
    print_info "Stopping existing containers..."
    docker compose down 2>/dev/null || true
    
    print_info "Removing orphaned containers..."
    docker container prune -f
    
    print_info "Removing orphaned networks..."
    docker network prune -f
    
    print_success "Cleanup completed"
}

# Start the stack
start_stack() {
    print_header "Starting Media Stack"
    
    print_info "Pulling latest images..."
    docker compose pull
    
    print_info "Starting containers..."
    docker compose up -d
    
    # Wait for containers to start
    sleep 5
    
    print_success "Containers started"
}

# Check container status
check_status() {
    print_header "Container Status"
    
    docker compose ps
    
    echo ""
    print_info "Checking for unhealthy containers..."
    
    UNHEALTHY=$(docker compose ps --format json | jq -r 'select(.Health == "unhealthy") | .Name' 2>/dev/null || true)
    
    if [ -z "$UNHEALTHY" ]; then
        print_success "All containers are healthy!"
    else
        print_warning "Some containers are unhealthy:"
        echo "$UNHEALTHY"
    fi
}

# Display access information
show_access_info() {
    print_header "Service Access Information"
    
    source .env
    
    echo -e "${GREEN}Your media stack is now running!${NC}"
    echo ""
    echo "Access your services at:"
    echo ""
    echo -e "${BLUE}VPN-Protected Services (via Gluetun):${NC}"
    echo "  • qBittorrent:  http://$SERVER_IP:8080 (admin/adminadmin)"
    echo "  • Prowlarr:     http://$SERVER_IP:9696"
    echo "  • Sonarr:       http://$SERVER_IP:8989"
    echo "  • Radarr:       http://$SERVER_IP:7878"
    echo "  • Bazarr:       http://$SERVER_IP:6767"
    echo "  • Jellyseerr:   http://$SERVER_IP:5055"
    echo "  • Firefox:      http://$SERVER_IP:3000"
    echo ""
    echo -e "${BLUE}Management Services:${NC}"
    echo "  • Plex:         http://$SERVER_IP:32400/web"
    echo "  • Portainer:    http://$SERVER_IP:9000"
    echo "  • Heimdall:     http://$SERVER_IP:8081"
    echo "  • Filebrowser:  http://$SERVER_IP:8443 (admin/admin)"
    echo ""
    print_warning "Remember to change default passwords!"
    echo ""
    print_info "View logs: docker compose logs -f"
    print_info "Stop stack: docker compose down"
    print_info "Restart:    docker compose restart"
}

# Main execution
main() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════╗"
    echo "║   Media Stack Setup & Deployment      ║"
    echo "║   Automated Installation Script       ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    
    check_root
    check_prerequisites
    setup_env_file
    create_directories
    cleanup
    start_stack
    check_status
    show_access_info
    
    echo ""
    print_success "Setup completed successfully!"
    echo ""
}

# Run main function
main
