#!/bin/bash
# ══════════════════════════════════════════════════════════
#  Shadow Smart Home — One-Click Deployment / Update
#  This script ensures a clean build with all latest configs.
# ══════════════════════════════════════════════════════════

# 0. Detect Docker Compose Command (v1 or v2)
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "❌ Error: Docker Compose is not installed."
    exit 1
fi

echo "🧹 Cleaning up old containers and volumes..."
$DOCKER_COMPOSE down

echo "🏗️  Normalizing permissions (Fixing NAS ACLs/403 issues)..."
# Attempt to strip ACLs if setfacl is available
if command -v setfacl &> /dev/null; then
    setfacl -b -R ./floorplans 2>/dev/null || true
fi
# Force the floorplans directory to be globally accessible
chmod -R 777 ./floorplans 2>/dev/null || true

echo "🏗️  Rebuilding Unified Shadow Home Image..."
# --no-cache ensures we build the latest frontend and backend artifacts
$DOCKER_COMPOSE build --no-cache

echo "🚀 Starting services..."
$DOCKER_COMPOSE up -d

echo "------------------------------------------------------"
echo "✅ Shadow Smart Home is now running (Unified Mode)!"
echo "📍 Access Everything: http://$(hostname -I | awk '{print $1}'):8500"
echo "🖼️  Persistent assets directory: ./floorplans"
echo "------------------------------------------------------"
