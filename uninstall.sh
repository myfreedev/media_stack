#!/bin/bash

# ============================================================================
# Media Stack - Uninstallation Script
# ============================================================================
# This script removes:
# - All Docker containers from the media stack
# - All Docker data (configs, databases, etc.)
# - Docker networks
# - .env file
#
# This script PRESERVES:
# - Your media files (movies, TV shows, downloads)
# - Docker and Docker Compose installation
# ============================================================================

set -e  # Exit on error

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Installation directory
INSTALL_DIR="$HOME/media-stack"

# Move to installation directory if it exists
if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR"
else
    echo -e "${YELLOW}Warning: Installation directory not found at $INSTALL_DIR${NC}"
    echo -e "${CYAN}Using current directory instead${NC}"
fi

# ============================================================================
# Display Functions
# ============================================================================

print_banner() {
    clear
    echo -e "${RED}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║          ⚠️  MEDIA STACK UNINSTALLER  ⚠️                ║"
    echo "║                                                          ║"
    echo "║          This will REMOVE all stack data!               ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
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
    echo -e "${BLUE}  ▸${NC} $1"
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
# Warning and Confirmation
# ============================================================================

show_warning() {
    print_banner
    
    echo -e "${YELLOW}${BOLD}This script will remove Docker containers only${NC}"
    echo ""
    echo -e "${YELLOW}This script will REMOVE:${NC}"
    echo ""
    echo "  ❌ All Docker containers (Plex, Sonarr, Radarr, etc.)"
    echo "  ❌ Docker networks created by the stack"
    echo ""
    echo -e "${GREEN}This script will PRESERVE:${NC}"
    echo ""
    echo "  ✓ Your media files (movies, TV shows, downloads)"
    echo "  ✓ Docker data directory (configs, databases)"
    echo "  ✓ .env configuration file"
    echo "  ✓ docker-compose.yml file"
    echo "  ✓ Docker and Docker Compose installation"
    echo ""
    
    print_box "Containers will be removed but data is kept" "$CYAN"
}

confirm_uninstall() {
    echo ""
    echo -e "${YELLOW}${BOLD}Do you want to remove all media stack containers?${NC}"
    echo ""
    read -p "Type 'YES' to confirm: " confirmation
    
    if [ "$confirmation" != "YES" ]; then
        echo ""
        print_info "Uninstallation cancelled. No changes were made."
        echo ""
        exit 0
    fi
}

# ============================================================================
# Uninstallation Functions
# ============================================================================

stop_containers() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Stopping Containers${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -f "docker-compose.yml" ]; then
        print_step "Stopping all media stack containers..."
        docker compose down 2>/dev/null || true
        print_success "Containers stopped"
    else
        print_warning "docker-compose.yml not found, skipping container stop"
    fi
}

remove_containers() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Removing Containers${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    print_step "Removing media stack containers..."
    
    # List of container names from the stack
    containers=(
        "gluetun" "jellyseerr" "prowlarr" "sonarr" "radarr" 
        "bazarr" "flaresolverr" "qbittorrent" "firefox" 
        "plex" "portainer" "watchtower" "heimdall" "filebrowser" "deunhealth"
    )
    
    for container in "${containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
    
    print_success "Containers removed"
}

remove_networks() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Removing Networks${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    print_step "Removing Docker networks..."
    docker network rm media_stack_media_network 2>/dev/null || true
    docker network prune -f > /dev/null 2>&1
    print_success "Networks removed"
}

cleanup_docker() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Cleaning Up Docker${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    print_step "Removing unused Docker resources..."
    docker system prune -f > /dev/null 2>&1
    print_success "Docker cleanup completed"
}

show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║          ✓  CONTAINERS REMOVED!  ✓                     ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}What was removed:${NC}"
    echo "  ✓ All media stack containers"
    echo "  ✓ Docker networks"
    echo ""
    
    echo -e "${GREEN}${BOLD}What was preserved:${NC}"
    echo "  ✓ Docker data directory (configs, databases)"
    echo "  ✓ Media files (movies, TV shows, downloads)"
    echo "  ✓ .env configuration"
    echo "  ✓ docker-compose.yml"
    echo ""
    
    # Show manual cleanup commands if .env exists
    if [ -f ".env" ]; then
        source .env
        
        echo -e "${YELLOW}${BOLD}📝 Manual Cleanup Commands (if needed):${NC}"
        echo ""
        echo -e "To remove Docker data directory:"
        echo -e "  ${BOLD}sudo rm -rf $DOCKER_DATA_DIR${NC}"
        echo ""
        echo -e "To remove .env file:"
        echo -e "  ${BOLD}rm .env${NC}"
        echo ""
        echo -e "${RED}${BOLD}⚠️  WARNING: Only run these if you want to delete all data!${NC}"
        echo -e "Media files at ${GREEN}$MEDIA_PATH${NC} are always safe."
        echo ""
    fi
    
    echo -e "${CYAN}${BOLD}To reinstall:${NC}"
    echo -e "  Run: ${BOLD}./install.sh${NC}"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    show_warning
    confirm_uninstall
    
    echo ""
    print_box "Starting container removal..." "$YELLOW"
    
    stop_containers
    remove_containers
    remove_networks
    cleanup_docker
    
    show_summary
    
    print_box "🎊 Container removal completed successfully!" "$GREEN"
    echo ""
}

# Run main function
main
