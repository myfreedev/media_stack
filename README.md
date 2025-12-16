# 🎬 Media Stack with VPN Protection

A complete Docker Compose media automation stack with VPN protection via Gluetun, featuring popular *arr services, Plex, and management tools.

## 📋 Table of Contents

- [Overview](#overview)
- [Services Included](#services-included)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Service Access](#service-access)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

---

## 🎯 Overview

This stack provides a complete media automation solution with:
- **VPN Protection**: All download-related services route through Gluetun VPN
- **Media Management**: Sonarr, Radarr, Bazarr for automated media organization
- **Indexer Management**: Prowlarr for centralized indexer configuration
- **Download Client**: qBittorrent with VPN protection
- **Media Server**: Plex with hardware transcoding support
- **Request Management**: Jellyseerr for user requests
- **Container Management**: Portainer and Watchtower
- **Dashboard**: Heimdall for unified access

---

## 📦 Services Included

### VPN & Core Services
- **Gluetun** - VPN client (Surfshark WireGuard)
- **Deunhealth** - Automatic container restart on health check failures

### VPN-Protected Services (via Gluetun)
- **Jellyseerr** (Port 5055) - Media request management
- **Prowlarr** (Port 9696) - Indexer manager
- **Sonarr** (Port 8989) - TV show automation
- **Radarr** (Port 7878) - Movie automation
- **Bazarr** (Port 6767) - Subtitle automation
- **FlareSolverr** (Port 8191) - Cloudflare bypass
- **qBittorrent** (Port 8080) - Torrent client
- **Firefox** (Port 3000) - Browser with VPN

### Direct Network Services
- **Plex** (Port 32400) - Media server with hardware transcoding
- **Portainer** (Ports 9000/9443) - Docker management UI
- **Watchtower** - Automatic container updates
- **Heimdall** (Port 8081) - Application dashboard
- **Filebrowser** (Port 8443) - Web-based file manager

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Host Network                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Plex   │  │Portainer │  │Heimdall  │  │Filebrowser│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   Media Network (172.20.0.0/16)             │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Gluetun VPN Container                  │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐│    │
│  │  │Jellyseerr│ │ Prowlarr │ │  Sonarr  │ │ Radarr ││    │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────┘│    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐│    │
│  │  │  Bazarr  │ │Flaresolv.│ │qBittorrent│ │Firefox ││    │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────┘│    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Surfshark VPN    │
                    │   (Netherlands)   │
                    └───────────────────┘
```

---

## ✅ Prerequisites

### System Requirements
- **OS**: Linux (Ubuntu 20.04+ recommended)
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **CPU**: Intel CPU with QuickSync (for Plex hardware transcoding)
- **RAM**: Minimum 8GB (16GB recommended)
- **Storage**: Sufficient space for media files

### Required Accounts
- **Surfshark VPN** subscription with WireGuard support
- **Plex** account (free or Plex Pass)

### Installation Commands
```bash
# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

---

## 🚀 Quick Start

### 1. Clone or Download This Repository
```bash
cd /path/to/your/projects
# If using git:
git clone <your-repo-url>
cd media_stack
```

### 2. Create Environment File
```bash
# Copy the example environment file
cp .env.example .env

# Edit with your values
nano .env
```

### 3. Configure Required Variables

Edit `.env` and set these **required** values:

```bash
# Paths
DOCKER_DATA_DIR=/home/youruser/docker-data
MEDIA_PATH=/mnt/media

# VPN (get from https://my.surfshark.com/vpn/manual-setup/main/wireguard)
SURFSHARK_WIREGUARD_KEY=your_key_here

# Plex
USERNAME=youruser
SERVER_IP=192.168.1.100
PLEX_CLAIM_TOKEN=claim-xxxx  # Get from https://www.plex.tv/claim/
```

### 4. Create Required Directories
```bash
# Create Docker data directory
mkdir -p $DOCKER_DATA_DIR

# Create media directory structure
mkdir -p $MEDIA_PATH/{Movies,TV\ Shows,downloads}

# Set permissions
sudo chown -R 1000:1000 $DOCKER_DATA_DIR
sudo chown -R 1000:1000 $MEDIA_PATH
```

### 5. Update docker-compose.yml

Replace all template variables in `docker-compose.yml` with your `.env` variables:

```bash
# Use sed or manually replace:
# {{docker_data_dir}} → ${DOCKER_DATA_DIR}
# {{media_path}} → ${MEDIA_PATH}
# {{surfshark_wireguard_pvt_key}} → ${SURFSHARK_WIREGUARD_KEY}
# {{ username }} → ${USERNAME}
# {{ ip_address }} → ${SERVER_IP}
```

### 6. Create the Network
```bash
# The network will be created automatically by docker compose
# But you can create it manually if needed:
docker network create --subnet=172.20.0.0/16 --gateway=172.20.0.1 media_network
```

### 7. Start the Stack
```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

---

## ⚙️ Configuration

### Initial Service Setup

After starting the stack, configure each service:

#### 1. **Prowlarr** (http://your-ip:9696)
- Complete initial setup wizard
- Add indexers
- Configure Sonarr/Radarr apps

#### 2. **Sonarr** (http://your-ip:8989)
- Settings → Media Management → Root Folder: `/tv`
- Settings → Download Clients → Add qBittorrent
  - Host: `localhost`
  - Port: `8080`

#### 3. **Radarr** (http://your-ip:7878)
- Settings → Media Management → Root Folder: `/movies`
- Settings → Download Clients → Add qBittorrent
  - Host: `localhost`
  - Port: `8080`

#### 4. **qBittorrent** (http://your-ip:8080)
- Default credentials: `admin` / `adminadmin`
- Change password immediately!
- Settings → Downloads → Default Save Path: `/downloads`

#### 5. **Plex** (http://your-ip:32400/web)
- Sign in with your Plex account
- Add library: `/data/Movies` and `/data/TV Shows`
- Enable hardware transcoding (Settings → Transcoder)

#### 6. **Jellyseerr** (http://your-ip:5055)
- Connect to Plex
- Configure Sonarr and Radarr

---

## 🌐 Service Access

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| qBittorrent | http://your-ip:8080 | admin / adminadmin |
| Prowlarr | http://your-ip:9696 | - |
| Sonarr | http://your-ip:8989 | - |
| Radarr | http://your-ip:7878 | - |
| Bazarr | http://your-ip:6767 | - |
| Jellyseerr | http://your-ip:5055 | - |
| Firefox | http://your-ip:3000 | - |
| Plex | http://your-ip:32400/web | Your Plex account |
| Portainer | http://your-ip:9000 | Set on first login |
| Heimdall | http://your-ip:8081 | - |
| Filebrowser | http://your-ip:8443 | admin / admin |

---

## 🔧 Troubleshooting

### VPN Not Connecting
```bash
# Check Gluetun logs
docker compose logs gluetun

# Common issues:
# 1. Invalid WireGuard private key
# 2. Surfshark server issues
# 3. Firewall blocking VPN ports

# Test VPN connection
docker exec gluetun wget -qO- ifconfig.me
```

### Services Can't Access Internet
```bash
# Verify Gluetun is healthy
docker compose ps gluetun

# Check if services are using Gluetun network
docker compose ps | grep "service:gluetun"

# Restart Gluetun
docker compose restart gluetun
```

### Permission Issues
```bash
# Fix ownership
sudo chown -R 1000:1000 $DOCKER_DATA_DIR
sudo chown -R 1000:1000 $MEDIA_PATH

# Check PUID/PGID in .env
id -u  # Should match PUID
id -g  # Should match PGID
```

### Plex Hardware Transcoding Not Working
```bash
# Verify /dev/dri is accessible
ls -la /dev/dri

# Check Plex has access
docker exec plex ls -la /dev/dri

# Ensure user 1000 is in render/video group
sudo usermod -aG render,video $(whoami)
```

### Check Container Health
```bash
# View all container statuses
docker compose ps

# Check specific service logs
docker compose logs -f <service-name>

# Restart unhealthy service
docker compose restart <service-name>
```

---

## 🔄 Maintenance

### Update Containers
```bash
# Watchtower handles automatic updates, but you can manually update:
docker compose pull
docker compose up -d
```

### Backup Configuration
```bash
# Backup Docker data directory
tar -czf media-stack-backup-$(date +%Y%m%d).tar.gz $DOCKER_DATA_DIR

# Backup to remote location
rsync -avz $DOCKER_DATA_DIR user@backup-server:/backups/
```

### Stop All Services
```bash
docker compose down
```

### Remove Everything (including volumes)
```bash
docker compose down -v
```

### View Resource Usage
```bash
docker stats
```

---

## 📝 Notes

- **VPN Kill Switch**: All download services route through Gluetun. If VPN disconnects, they lose internet access (by design)
- **Health Monitoring**: Deunhealth automatically restarts unhealthy containers
- **Resource Limits**: Adjust CPU/memory limits in docker-compose.yml as needed
- **Timezone**: All services use `TZ=Europe/London` - change in docker-compose.yml if needed

---

## 🔒 Security Recommendations

1. **Change default passwords** immediately after first login
2. **Use strong passwords** for all services
3. **Keep .env file secure** - never commit to version control
4. **Regular updates** - Watchtower handles this automatically
5. **Firewall rules** - Only expose necessary ports
6. **VPN always on** - Verify download services use VPN

---

## 📚 Additional Resources

- [Gluetun Documentation](https://github.com/qdm12/gluetun)
- [Sonarr Wiki](https://wiki.servarr.com/sonarr)
- [Radarr Wiki](https://wiki.servarr.com/radarr)
- [Prowlarr Wiki](https://wiki.servarr.com/prowlarr)
- [Plex Support](https://support.plex.tv)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## 🆘 Support

If you encounter issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review service logs: `docker compose logs <service-name>`
3. Verify environment variables in `.env`
4. Check Docker and Docker Compose versions

---

## 📄 License

This configuration is provided as-is for personal use.

---

**Happy Streaming! 🎬🍿**
