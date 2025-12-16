# Media Stack - Quick Reference

## 🚀 Common Commands

### Start/Stop Stack
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart specific service
docker compose restart <service-name>

# Restart all services
docker compose restart
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f gluetun
docker compose logs -f sonarr

# Last 100 lines
docker compose logs --tail=100 <service-name>
```

### Check Status
```bash
# List all containers
docker compose ps

# Check health status
docker compose ps | grep healthy

# View resource usage
docker stats
```

### Updates
```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d

# Remove old images
docker image prune -a
```

## 🔍 Troubleshooting Commands

### VPN Issues
```bash
# Check VPN connection
docker exec gluetun wget -qO- ifconfig.me

# View Gluetun logs
docker compose logs -f gluetun

# Restart VPN
docker compose restart gluetun
```

### Permission Issues
```bash
# Fix ownership (replace paths with your actual paths)
sudo chown -R 1000:1000 /path/to/docker-data
sudo chown -R 1000:1000 /path/to/media

# Check current permissions
ls -la /path/to/docker-data
```

### Container Shell Access
```bash
# Access container shell
docker exec -it <container-name> /bin/bash
# or
docker exec -it <container-name> /bin/sh

# Examples:
docker exec -it sonarr /bin/bash
docker exec -it qbittorrent /bin/bash
```

### Network Issues
```bash
# Inspect network
docker network inspect media_network

# Check container network
docker inspect <container-name> | grep -A 20 Networks
```

## 📊 Monitoring

### Check Container Health
```bash
# All containers health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Specific container
docker inspect --format='{{.State.Health.Status}}' <container-name>
```

### Disk Usage
```bash
# Docker disk usage
docker system df

# Detailed view
docker system df -v

# Clean up
docker system prune -a --volumes
```

## 🔧 Maintenance

### Backup
```bash
# Backup configuration
tar -czf backup-$(date +%Y%m%d).tar.gz \
  docker-compose.yml \
  .env \
  /path/to/docker-data

# Restore
tar -xzf backup-YYYYMMDD.tar.gz
```

### Clean Up
```bash
# Remove stopped containers
docker compose rm

# Remove unused images
docker image prune -a

# Remove unused volumes (CAREFUL!)
docker volume prune

# Full cleanup (CAREFUL!)
docker system prune -a --volumes
```

## 🌐 Service URLs

Replace `your-ip` with your server's IP address:

- **qBittorrent**: http://your-ip:8080
- **Prowlarr**: http://your-ip:9696
- **Sonarr**: http://your-ip:8989
- **Radarr**: http://your-ip:7878
- **Bazarr**: http://your-ip:6767
- **Jellyseerr**: http://your-ip:5055
- **Firefox**: http://your-ip:3000
- **Plex**: http://your-ip:32400/web
- **Portainer**: http://your-ip:9000
- **Heimdall**: http://your-ip:8081
- **Filebrowser**: http://your-ip:8443

## 🔑 Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| qBittorrent | admin | adminadmin |
| Filebrowser | admin | admin |
| Portainer | (set on first login) | - |
| Others | (no default auth) | - |

**⚠️ Change all default passwords immediately!**

## 📝 Environment Variables

Edit `.env` file:
```bash
nano .env
```

Required variables:
- `DOCKER_DATA_DIR` - Path to Docker data
- `MEDIA_PATH` - Path to media files
- `SURFSHARK_WIREGUARD_KEY` - VPN private key
- `USERNAME` - Your Linux username
- `SERVER_IP` - Server IP address
- `PLEX_CLAIM_TOKEN` - Plex claim token

## 🆘 Emergency Commands

### Stop Everything Immediately
```bash
docker compose down
```

### Kill All Containers
```bash
docker kill $(docker ps -q)
```

### Reset Specific Service
```bash
# Stop service
docker compose stop <service-name>

# Remove container
docker compose rm -f <service-name>

# Remove data (CAREFUL!)
sudo rm -rf /path/to/docker-data/<service-name>

# Recreate
docker compose up -d <service-name>
```

## 📞 Getting Help

1. Check logs: `docker compose logs -f <service-name>`
2. Verify .env variables are set correctly
3. Check network connectivity: `docker exec gluetun ping 8.8.8.8`
4. Verify VPN: `docker exec gluetun wget -qO- ifconfig.me`
5. Review README.md troubleshooting section
