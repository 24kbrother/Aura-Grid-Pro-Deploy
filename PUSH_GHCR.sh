#!/bin/bash
# ══════════════════════════════════════════════════════════
#  Shadow Smart Home — GitHub Container Registry (GHCR) Build & Push
# ══════════════════════════════════════════════════════════

GH_USER="24kbrother"
GH_REPO="aura-grid-pro"      
VERSION="v1.7.9-PRO"

echo "🏗️  Starting Build process for $VERSION..."

# Build the image locally first (no-cache to ensure all the latest patches are in)
docker build --no-cache -t aura-grid:$VERSION .

IMAGE_ID=$(docker images --filter "reference=aura-grid:$VERSION" -q | head -n 1)

if [ -z "$IMAGE_ID" ]; then
    echo "❌ Error: Build failed! No image ID found."
    exit 1
fi

echo "🚀 Preparing GHCR tags for $VERSION..."
docker tag $IMAGE_ID ghcr.io/$GH_USER/$GH_REPO:$VERSION
docker tag $IMAGE_ID ghcr.io/$GH_USER/$GH_REPO:latest

echo "📦 Pushing to GitHub Container Registry..."
# Requires prior docker login ghcr.io
docker push ghcr.io/$GH_USER/$GH_REPO:$VERSION
docker push ghcr.io/$GH_USER/$GH_REPO:latest

echo "------------------------------------------------------"
echo "✅ Build & Push Successful!"
echo "📍 Version URL: ghcr.io/$GH_USER/$GH_REPO:$VERSION"
echo "📍 Latest URL: ghcr.io/$GH_USER/$GH_REPO:latest"
echo "------------------------------------------------------"
