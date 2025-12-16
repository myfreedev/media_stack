# 🎬 Media Stack with VPN

Automated media server stack with VPN protection. Beautiful CLI installer handles everything!

## 🚀 One-Command Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/install.sh)
```

> **💡 Tip:** To ensure you get the absolute latest version (bypass CDN cache), add a timestamp:
> ```bash
> bash <(curl -fsSL "https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/install.sh?$(date +%s)")
> ```

**That's it!** The installer will:
- ✅ Install all dependencies (Docker, Docker Compose, Git)
- ✅ Download required files
- ✅ Guide you through configuration with beautiful prompts
- ✅ Create directories automatically
- ✅ Deploy all 16 containers
- ✅ Display access URLs

**No manual steps required!**

## 📦 What's Included

### VPN-Protected (via Gluetun)
- **qBittorrent** - Torrent client (Port 8080)
- **Prowlarr** - Indexer manager (Port 9696)
- **Sonarr** - TV show automation (Port 8989)
- **Radarr** - Movie automation (Port 7878)
- **Bazarr** - Subtitle automation (Port 6767)
- **Jellyseerr** - Request management (Port 5055)
- **Firefox** - VPN browser (Port 3000)
- **FlareSolverr** - Cloudflare bypass (Port 8191)

### Direct Access
- **Plex** - Media server (Port 32400)
- **Portainer** - Docker management (Port 9000)
- **Heimdall** - Dashboard (Port 8081)
- **Filebrowser** - File manager (Port 8443)

## ⚙️ Configuration

You'll need:
1. **Surfshark WireGuard Key** - Get from [Surfshark Dashboard](https://my.surfshark.com/vpn/manual-setup/main/wireguard)
2. **Plex Claim Token** (optional) - Get from [plex.tv/claim](https://www.plex.tv/claim/)

The script will auto-detect your server IP and prompt for storage paths.

## 🔧 Manual Setup

If you prefer manual installation:

```bash
# Clone repository
git clone https://github.com/myfreedev/media_stack.git
cd media_stack

# Run setup
./setup.sh
```

## 📝 Environment Variables

Create `.env` file (or let setup.sh do it):

```bash
DOCKER_DATA_DIR=/path/to/docker-data
MEDIA_PATH=/path/to/media
SURFSHARK_WIREGUARD_KEY=your_key_here
USERNAME=youruser
SERVER_IP=192.168.1.100
PLEX_CLAIM_TOKEN=claim-xxx
```

## 🌐 Access Services

After deployment, access at `http://YOUR_SERVER_IP:PORT`:

| Service | Port | Default Login |
|---------|------|---------------|
| qBittorrent | 8080 | admin / adminadmin |
| Prowlarr | 9696 | - |
| Sonarr | 8989 | - |
| Radarr | 7878 | - |
| Bazarr | 6767 | - |
| Jellyseerr | 5055 | - |
| Plex | 32400 | Your Plex account |
| Portainer | 9000 | Set on first login |
| Heimdall | 8081 | - |
| Filebrowser | 8443 | admin / admin |

**⚠️ Change default passwords immediately!**

## 🔄 Management

```bash
# View logs
docker compose logs -f

# Stop all services
docker compose down

# Restart all services
docker compose up -d

# Restart specific service
docker compose restart sonarr

# Update containers
docker compose pull && docker compose up -d
```

## 🛠️ Troubleshooting

### VPN not connecting
```bash
# Check Gluetun logs
docker compose logs gluetun

# Verify WireGuard key is correct in .env
```

### Services can't access internet
```bash
# Restart Gluetun
docker compose restart gluetun
```

### Permission issues
```bash
# Fix ownership (replace paths with yours)
sudo chown -R 1000:1000 /path/to/docker-data
sudo chown -R 1000:1000 /path/to/media
```

## 📚 Additional Info

- **VPN Kill Switch**: Download services only work when VPN is connected
- **Health Monitoring**: Deunhealth automatically restarts unhealthy containers
- **Auto Updates**: Watchtower keeps containers up to date
- **Network**: All services use isolated Docker network (172.20.0.0/16)

## 🔒 Security Notes

1. Change all default passwords
2. Don't commit `.env` file to git
3. Keep VPN credentials secure
4. Regularly update containers

## 📄 License

MIT License - Use freely

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/myfreedev/media_stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/myfreedev/media_stack/discussions)

---

**Made with ❤️ for the self-hosting community**
