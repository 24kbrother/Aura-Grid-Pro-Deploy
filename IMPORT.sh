#!/bin/bash

# ══════════════════════════════════════════════════════════════════════
#  Shadow Smart Home — One-Click Import & Production Standalone
# ══════════════════════════════════════════════════════════════════════

IMAGE_TAR="../aura-grid-v1.6.2-pro.tar"
ENV_FILE="./.env"

echo "📦 Starting Shadow Home Import Process..."

# 0. Detect Docker Compose Command (v1 or v2)
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "❌ Error: Docker Compose is not installed."
    echo "   Please install Docker Compose before starting."
    exit 1
fi

# 1. Check for the Golden Image
if [ ! -f "$IMAGE_TAR" ]; then
    echo "❌ Missing image: ${IMAGE_TAR}"
    echo "   Please make sure you have built the Golden Image on your Mac first."
    exit 1
fi

# 2. Check for .env
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Initializing .env from example..."
    cp .env.example .env
    echo "⚠️  Please edit deploy/.env and add your HA_TOKEN and ACCESS_PASSWORD before continuing."
fi

# 3. Load the Docker Image
echo "📥 Loading Golden Image into Docker (this is fast)..."
docker load < "$IMAGE_TAR"

# 4. Normalize Permissions for NAS (Fixing ACLs)
echo "📏 Normalizing permissions for persistent storage..."
mkdir -p floorplans data
chmod -R 777 floorplans data
# Try to strip ACLs if setfacl is available
if command -v setfacl >/dev/null 2>&1; then
    setfacl -b floorplans data
fi

# 5. Launch
echo "🚀 Launching Production Stack..."
$DOCKER_COMPOSE -f docker-compose.prod.yml up -d

# 6. Success Output
# Simple IP detection for NAS (handles Synology 'hostname' differences)
SERVER_IP=$(hostname -i 2>/dev/null | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then SERVER_IP=$(hostname); fi

echo "------------------------------------------------------"
echo "✅ Shadow Smart Home is now running (Production Mode)!"
echo "📍 Access: http://${SERVER_IP}:8125"
echo "🖼️  Persistent assets: ./floorplans"
echo "------------------------------------------------------"
