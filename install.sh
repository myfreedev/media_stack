#!/bin/bash
# One-liner installer for Media Stack
# Usage: curl -fsSL https://raw.githubusercontent.com/your-repo/media_stack/main/install.sh | bash

set -e

echo "╔════════════════════════════════════════╗"
echo "║   Media Stack One-Line Installer      ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if git is installed, if not install it
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    if [ -f /etc/debian_version ]; then
        sudo apt-get update -qq && sudo apt-get install -y -qq git
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y -q git
    else
        echo "Please install git manually"
        exit 1
    fi
fi

# Clone or download the repository
INSTALL_DIR="$HOME/media_stack"

if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR already exists"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
    else
        echo "Installation cancelled"
        exit 0
    fi
fi

echo "Downloading media stack..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download all necessary files from GitHub
echo "Downloading setup script..."
curl -fsSL https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/setup.sh -o setup.sh
curl -fsSL https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/docker-compose.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/.env.example -o .env.example
curl -fsSL https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/.gitignore -o .gitignore

chmod +x setup.sh

echo ""
echo "✓ Media stack downloaded to: $INSTALL_DIR"
echo ""
echo "Running setup script..."
echo ""

./setup.sh
