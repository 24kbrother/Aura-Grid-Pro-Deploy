# ██████████████████████████████████████████████████████████
#    Shadow Smart Home Platform
#    🚀 One-Command Deployment Guide
# ██████████████████████████████████████████████████████████

## Prerequisites

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- Docker Compose V2
- Access to your Home Assistant server on the local network

---

## Quick Start (3 steps)

### Step 1 — Configure your environment

```bash
# Navigate to the deployment folder
cd deploy

# Copy the example config file
cp .env.example .env

# Open .env in any text editor and set:
#   ACCESS_PASSWORD = a password you'll share with authorized users
```

---

### Step 2 — Launch the platform

```bash
docker compose up -d
```

This pulls images, builds the frontend, and starts 3 services:
- `shadow-frontend` (Vue dashboard, port 8080)
- `shadow-backend` (NestJS API, port 8500)
- `shadow-redis` (state cache)

First build takes **3-5 minutes**. Subsequent starts take **~10 seconds**.

---

### Step 3 — Open the dashboard

```
http://your-server-ip:8125
```

Log in with the `ACCESS_PASSWORD` you set, then go to **Settings → System** to configure your HA connection.

---

## Network Notes

| Host OS | HA Reach | Notes |
|:--------|:---------|:------|
| **Linux (NAS, server)** | ✅ Perfect | `network_mode: host` works natively |
| **Mac (Docker Desktop)** | ⚠️ Limited | Use `host.docker.internal` instead of `localhost` for HA_URL |
| **Windows (Docker Desktop)** | ⚠️ Limited | Same as Mac above |

---

## Useful Commands

```bash
# View live logs
docker-compose logs -f

# Stop everything
docker-compose down

# Rebuild after code update
docker-compose up -d --build

# Reset all data (⚠️ destructive)
docker-compose down -v
```

---

## Data Persistence & Floorplans

All user data is stored in Docker persistent volumes:
- `shadow-redis-data` — entity state cache
- `shadow-db-data` — layout config, settings, and project data
- `./deploy/floorplans` (Bind Mount) — **User-Uploaded Floorplans**
- `./deploy/icons` (Bind Mount) — **Custom SVG Icons**

### 🖼️ Managing Assets
Simply drop your images into the `deploy/floorplans` directory or your custom SVG icons into `deploy/icons` on your server. They will be immediately available in the UI without needing to rebuild or restart containers.

Your configuration **survives container restarts** automatically.

## 🛡️ Pro Private Distribution (Maintenance Only)

For staff-led upgrades using the private GitHub Container Registry (GHCR):

1. **Build the latest image**:
   ```bash
   docker compose build
   ```

2. **Push to Private Registry**:
   ```bash
   # Requires a GitHub Personal Access Token (PAT) with write:packages scope
   ./PUSH_PRO.sh <YOUR_GITHUB_PAT>
   ```

3. **Stealth Upgrade (Server-side)**:
   This feature allows the container to self-update by pulling the latest image. 
   
   **Prerequisites**:
   - The image must contain the `docker-cli` (Aura Grid Pro images include this by default).
   - You **MUST** mount `/var/run/docker.sock:/var/run/docker.sock` in your `docker-compose.yml`.
   - Access via the **Advanced Maintenance** section in the Dashboard UI.

---

*Shadow Smart Home — Pro Edition*

