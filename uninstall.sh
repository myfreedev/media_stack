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

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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
    
    echo -e "${RED}${BOLD}⚠️  WARNING: This action is DESTRUCTIVE! ⚠️${NC}"
    echo ""
    echo -e "${YELLOW}This script will PERMANENTLY DELETE:${NC}"
    echo ""
    echo "  ❌ All Docker containers (Plex, Sonarr, Radarr, etc.)"
    echo "  ❌ All container configurations and databases"
    echo "  ❌ All Docker data directory contents"
    echo "  ❌ Docker networks created by the stack"
    echo "  ❌ .env configuration file"
    echo ""
    echo -e "${GREEN}This script will PRESERVE:${NC}"
    echo ""
    echo "  ✓ Your media files (movies, TV shows, downloads)"
    echo "  ✓ Docker and Docker Compose installation"
    echo "  ✓ docker-compose.yml file (for reference)"
    echo ""
    
    # Load .env to show what will be deleted
    if [ -f ".env" ]; then
        source .env
        echo -e "${CYAN}${BOLD}Directories that will be deleted:${NC}"
        echo ""
        echo "  📁 Docker Data: ${RED}$DOCKER_DATA_DIR${NC}"
        echo ""
        echo -e "${CYAN}${BOLD}Directories that will be KEPT:${NC}"
        echo ""
        echo "  📁 Media Files: ${GREEN}$MEDIA_PATH${NC} (SAFE)"
        echo ""
    fi
    
    print_box "⚠  This action CANNOT be undone!" "$RED"
}

confirm_uninstall() {
    echo ""
    echo -e "${YELLOW}${BOLD}Are you ABSOLUTELY SURE you want to continue?${NC}"
    echo ""
    read -p "Type 'DELETE' (in capital letters) to confirm: " confirmation
    
    if [ "$confirmation" != "DELETE" ]; then
        echo ""
        print_info "Uninstallation cancelled. No changes were made."
        echo ""
        exit 0
    fi
    
    echo ""
    echo -e "${YELLOW}${BOLD}Last chance! Type 'YES' to proceed:${NC} "
    read -p "" final_confirmation
    
    if [ "$final_confirmation" != "YES" ]; then
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

remove_data() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Removing Docker Data${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -f ".env" ]; then
        source .env
        
        if [ -d "$DOCKER_DATA_DIR" ]; then
            print_step "Removing Docker data directory: $DOCKER_DATA_DIR"
            echo ""
            print_warning "This will delete ALL container configurations and databases!"
            echo ""
            read -p "Continue? (y/N): " -n 1 -r
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo rm -rf "$DOCKER_DATA_DIR"
                print_success "Docker data directory removed"
            else
                print_info "Skipped Docker data directory removal"
            fi
        else
            print_info "Docker data directory not found: $DOCKER_DATA_DIR"
        fi
        
        # Verify media path is NOT deleted
        if [ -d "$MEDIA_PATH" ]; then
            print_success "Media files preserved at: $MEDIA_PATH"
        fi
    else
        print_warning ".env file not found, skipping data directory removal"
    fi
}

remove_config() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}${BOLD}  Removing Configuration${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ -f ".env" ]; then
        print_step "Removing .env file..."
        rm -f .env
        print_success ".env file removed"
    else
        print_info ".env file not found"
    fi
    
    print_info "Keeping docker-compose.yml for reference"
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
    echo "║          ✓  UNINSTALLATION COMPLETE!  ✓                ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}What was removed:${NC}"
    echo "  ✓ All media stack containers"
    echo "  ✓ Docker data directory"
    echo "  ✓ Docker networks"
    echo "  ✓ .env configuration"
    echo ""
    
    echo -e "${GREEN}${BOLD}What was preserved:${NC}"
    echo "  ✓ Your media files (movies, TV shows, downloads)"
    echo "  ✓ Docker and Docker Compose"
    echo "  ✓ docker-compose.yml (for reference)"
    echo ""
    
    echo -e "${CYAN}${BOLD}To reinstall:${NC}"
    echo "  Run: ${BOLD}./install.sh${NC}"
    echo ""
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    show_warning
    confirm_uninstall
    
    echo ""
    print_box "Starting uninstallation..." "$YELLOW"
    
    stop_containers
    remove_containers
    remove_networks
    remove_data
    remove_config
    cleanup_docker
    
    show_summary
    
    print_box "🎊 Uninstallation completed successfully!" "$GREEN"
    echo ""
}

# Run main function
main
