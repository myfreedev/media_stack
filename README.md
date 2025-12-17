# 🎬 Media Stack with VPN

The ultimate automated media server stack with VPN protection. Beautiful CLI installer handles everything!

## 🚀 One-Command Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/install.sh)
```

**The installer will:**
- ✅ Install all dependencies (Docker, Docker Compose, Git)
- ✅ **Auto-download preconfigured templates** (qBittorrent, etc.)
- ✅ Guide you through configuration with beautiful prompts
- ✅ Create directories automatically
- ✅ Deploy all 16 containers behind a VPN
- ✅ Display access URLs and credentials

**Files are installed to:** `~/media-stack/`

---

## 📦 What's Included

### 🔒 VPN-Protected Services (via Gluetun)
| Service | Port | Description |
|---------|------|-------------|
| **qBittorrent** | 8080 | Torrent client (Preconfigured!) |
| **Prowlarr** | 9696 | Indexer manager |
| **Sonarr** | 8989 | TV show automation |
| **Radarr** | 7878 | Movie automation |
| **Bazarr** | 6767 | Subtitle automation |
| **Jellyseerr** | 5055 | Request management |
| **Brave Browser** | 3000 | Secure VPN Browser (HTTPS) |
| **FlareSolverr** | 8191 | Cloudflare bypass |

### 🌐 Direct Access Services
| Service | Port | Description |
|---------|------|-------------|
| **Plex** | 32400 | Media server |
| **Portainer** | 9000 | Docker management |
| **Homepage** | 3001 | Modern Dashboard (Auto-discovery) |
| **Filebrowser** | 8443 | File manager |

---

## ⚙️ Configuration Guide

### 1. Preconfigured Templates
The installer automatically downloads optimized configurations from GitHub.
- **Enabled by default**: Select 'Y' during installation.
- **Includes**: qBittorrent (VueTorrent UI, anonymous mode, paths set).
- **Default Credentials**: `admin` / `MediaStack@S3cure`

### 2. Manual Configuration Required
Some services require personal accounts and must be configured manually.

#### 🎥 Plex Media Server
1. Go to `http://YOUR_IP:32400/web`
2. Sign in with your Plex account.
3. Add Libraries:
   - **Movies**: `/data/Movies` (or your chosen path)
   - **TV Shows**: `/data/TV Shows`

#### 🍿 Jellyseerr
1. Go to `http://YOUR_IP:5055`
2. Sign in with Plex.
3. Connect **Sonarr**:
   - URL: `http://sonarr:8989` (use container name!)
   - API Key: Retrieve from Sonarr (Settings > General > Security)
4. Connect **Radarr**:
   - URL: `http://radarr:7878`
   - API Key: Retrieve from Radarr (Settings > General > Security)

---

## 🔑 Access & Credentials

| Service | Username | Password |
|---------|----------|----------|
| **qBittorrent** | admin | `MediaStack@S3cure` (Template)<br>`adminadmin` (Default) |
| **Brave** | admin | `MediaStack@S3cure` |
| **Filebrowser** | admin | `admin` |
| **Plex** | (Your Account) | - |
| **Portainer** | (Set on login) | - |

> **⚠️ IMPORTANT**: Change all default passwords immediately after logging in!

---

## 🕹️ Quick Reference

### Docker Commands
Run these from `~/media-stack/`:

```bash
# Start Stack
docker compose up -d

# Stop Stack
docker compose down

# View Logs
docker compose logs -f

# Update Containers
docker compose pull && docker compose up -d

# Restart Specific Service
docker compose restart gluetun
```

### 📁 Directory Structure
```
~/media-stack/              # configs (.env, docker-compose.yml)
~/docker-data/              # Service data (database, configs)
~/media/                    # Media files (Movies, TV, Downloads)
```

---

## 🛠️ Troubleshooting

### Jellyseerr Can't Connect
- Use container names (e.g., `http://sonarr:8989`), NOT IPs or localhost.
- Check if Sonarr/Radarr are running: `docker compose ps`

### VPN Issues
- Check Gluetun logs: `docker compose logs gluetun`
- Verify your WireGuard private key in `.env`.

### Permission Issues
- Fix ownership of data directories:
  ```bash
  sudo chown -R 1000:1000 ~/docker-data ~/media
  ```

---

## 🆘 Support
- **Issues**: [GitHub Issues](https://github.com/myfreedev/media_stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/myfreedev/media_stack/discussions)

**Made with ❤️ for the self-hosting community**
