#!/bin/bash
# ══════════════════════════════════════════════════════════
#  Aura Grid Pro — Private GHCR Push Service
#  Usage: ./PUSH_PRO.sh <GITHUB_PAT>
# ══════════════════════════════════════════════════════════

GH_USER="24kbrother"
GH_REPO="Aura-Grid-Pro"      
VERSION="v1.7.0-PRO"

# 1. Check for token
PAT=$1
if [ -z "$PAT" ]; then
    echo "❌ Error: Please provide a GitHub Personal Access Token (PAT)."
    echo "Usage: ./PUSH_PRO.sh <YOUR_TOKEN>"
    exit 1
fi

# 2. Login to GHCR
echo "🔑 Logging in to GitHub Container Registry..."
echo "$PAT" | docker login ghcr.io -u "$GH_USER" --password-stdin

if [ $? -ne 0 ]; then
    echo "❌ Login failed. Please check your token and name."
    exit 1
fi

# 3. Detect Image
# Priority: 1. Tagged with version, 2. Latest local

IMAGE_ID=$(docker images --filter "reference=aura-grid:$VERSION" -q | head -n 1)
if [ -z "$IMAGE_ID" ]; then
    IMAGE_ID=$(docker images --filter "reference=aura-grid:latest" -q | head -n 1)
fi

if [ -z "$IMAGE_ID" ]; then
    echo "❌ Error: Could not find 'aura-grid' image locally."
    echo "Hint: Run docker-compose build first."
    exit 1
fi

echo "🚀 Tagging image $IMAGE_ID..."
TARGET_IMAGE="ghcr.io/$GH_USER/$GH_REPO:$VERSION"
LATEST_IMAGE="ghcr.io/$GH_USER/$GH_REPO:latest"

docker tag $IMAGE_ID "$TARGET_IMAGE"
docker tag $IMAGE_ID "$LATEST_IMAGE"

# 4. Push
echo "📦 Pushing to Private Registry..."
docker push "$TARGET_IMAGE"
docker push "$LATEST_IMAGE"

echo "------------------------------------------------------"
echo "✅ Push Successful!"
echo "📍 Registry: $TARGET_IMAGE"
echo "📍 Latest:   $LATEST_IMAGE"
echo "------------------------------------------------------"
echo "⚠️  Reminder: Please ensure the package visibility is set to PRIVATE in GitHub settings."
echo "------------------------------------------------------"

# Logout
docker logout ghcr.io
