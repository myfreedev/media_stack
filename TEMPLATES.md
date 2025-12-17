# Preconfigured ARR Stack Templates

## Overview

The media stack installer now supports **preconfigured templates** for ARR services, allowing you to deploy with pre-configured settings and default credentials.

## Quick Start

During installation, you'll be prompted:

```
⚙️  Preconfigured ARR Stack Templates
Use preconfigured settings for ARR services?
Includes: Radarr, Sonarr, Prowlarr, Qbittorrent, Jellyseerr
Default credentials: admin / MediaStack@S3cure

Use preconfigured templates? (Y/n):
```

- Press **Y** (or Enter) to use templates
- Press **N** to configure services manually

## What's Included

### Currently Available
- **qBittorrent**: Fully configured with VueTorrent UI, download paths, and security settings

### Coming Soon
- Radarr
- Sonarr
- Prowlarr
- Jellyseerr

## Default Credentials

When templates are enabled:
- **Username**: `admin`
- **Password**: `MediaStack@S3cure`

> ⚠️ **IMPORTANT**: Change these default passwords after first login!

## Template Location

Templates are stored in: `/Users/stebu.johny/git/media_stack/docker-data-templates/`

To add your own templates:
1. Create a directory: `docker-data-templates/[service-name]/`
2. Add your preconfigured files
3. The installer will copy them to `${DOCKER_DATA_DIR}/[service-name]/`

## Manual Deployment

To manually deploy templates on an existing installation:

```bash
# Edit .env and set USE_TEMPLATES=true
nano .env

# Stop containers
docker-compose down

# Remove existing config (backup first!)
rm -rf ${DOCKER_DATA_DIR}/qbittorrent

# Re-run installer (or manually copy templates)
./install.sh
```

## Security Best Practices

1. **Change default passwords immediately** after installation
2. Use **strong, unique passwords** for each service
3. Consider using a **password manager**
4. Enable **two-factor authentication** where available

## Disabling Templates

To install without templates:
- Select **N** when prompted during installation
- Or set `USE_TEMPLATES=false` in your `.env` file
