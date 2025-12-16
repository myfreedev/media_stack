# Setup Guide

## One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/myfreedev/media_stack/refs/heads/main/install.sh | bash
```

## What You'll Need

1. **Surfshark WireGuard Key**: https://my.surfshark.com/vpn/manual-setup/main/wireguard
2. **Plex Claim Token** (optional): https://www.plex.tv/claim/

Everything else is auto-detected!

## Installation Steps

The script will automatically:

1. ✅ Install Git, Docker, Docker Compose
2. ✅ Ask for configuration (VPN key, paths, etc.)
3. ✅ Create directories
4. ✅ Deploy all containers
5. ✅ Show access URLs

## After Installation

Access services at `http://YOUR_IP:PORT`:
- qBittorrent: 8080
- Sonarr: 8989
- Radarr: 7878
- Plex: 32400/web
- Portainer: 9000

## Common Commands

```bash
# View logs
docker compose logs -f

# Stop
docker compose down

# Start
docker compose up -d

# Restart service
docker compose restart gluetun
```

## Troubleshooting

**VPN not working?**
```bash
docker compose logs gluetun
```

**Permission errors?**
```bash
sudo chown -R 1000:1000 /path/to/docker-data
sudo chown -R 1000:1000 /path/to/media
```

**Port conflicts?**
```bash
sudo lsof -i :8080
```

That's it! See [README.md](README.md) for more details.
