#!/bin/bash

# ══════════════════════════════════════════════════════════
#  Aura Grid Pro - Manual Installation Script
#  Usage: curl -sSL ... | bash -s -- <token>
# ══════════════════════════════════════════════════════════

set -e

TOKEN=$1

if [ -z "$TOKEN" ]; then
    echo -e "\033[31m错误: 未提供拉取授权 Token。\033[0m"
    echo "使用方法: bash INSTALL_PRO.sh <token>"
    exit 1
fi

echo -e "\033[34m[1/4] 环境预检查...\033[0m"
if ! command -v docker &> /dev/null; then
    echo "未检测到 Docker，请先安装 Docker。"
    exit 1
fi

# 询问代理配置
echo -n "是否需要配置 HTTP 代理来拉取镜像? (y/n, 默认 n): "
read NEED_PROXY

if [ "$NEED_PROXY" == "y" ]; then
    echo -n "请输入代理地址 (例如 http://127.0.0.1:7890): "
    read PROXY_ADDR
    export http_proxy=$PROXY_ADDR
    export https_proxy=$PROXY_ADDR
    echo "代理已设置: $PROXY_ADDR"
fi

echo -e "\033[34m[2/4] 正在登录私有仓库 (GHCR)...\033[0m"
echo "$TOKEN" | docker login ghcr.io -u 24kbrother --password-stdin

echo -e "\033[34m[3/4] 正在准备环境并生成配置文件 (docker-compose.yml)...\033[0m"
WORKDIR=$(pwd)
mkdir -p "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons"
chmod -R 777 "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons"

# --- 虚拟硬件指纹逻辑 (与 SETUP_PRO.sh 保持绝对一致) ---
HWID_FILE="$WORKDIR/data/device.id"
if [ ! -f "$HWID_FILE" ]; then
    if [ -f /proc/sys/kernel/random/uuid ]; then
        NEW_HWID=$(cat /proc/sys/kernel/random/uuid)
    elif command -v uuidgen &>/dev/null; then
        NEW_HWID=$(uuidgen)
    else
        NEW_HWID=$(od -x /dev/urandom | head -n 1 | awk '{print $2$3"-"$4"-"$5"-"$6"-"$7$8$9}')
    fi
    echo "$NEW_HWID" > "$HWID_FILE"
fi

cat > docker-compose.yml <<EOF
# Aura Grid Pro - Production Compose (Generated)
services:
  redis:
    image: redis:7-alpine
    container_name: aura-redis-pro
    restart: unless-stopped
    volumes:
      - redis_data:/data
    command: redis-server --save 60 1 --loglevel warning
    networks:
      - aura-pro-internal

  aura-grid:
    image: ghcr.io/24kbrother/aura-grid-pro:latest
    container_name: aura-grid-pro
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 8500
      REDIS_URL: redis://redis:6379
      DATABASE_URL: file:/app/prisma/data/prod.db
      FLOORPLANS_DIR: /app/floorplans
    volumes:
      - db_data:/app/prisma/data
      - ./floorplans:/app/floorplans
      - ./icons:/app/icons
      - ./data:/app/data
      - ./data/device.id:/etc/machine-id:ro
    ports:
      - "8125:8500"
    networks:
      - aura-pro-internal
    depends_on:
      - redis

networks:
  aura-pro-internal:
    driver: bridge

volumes:
  redis_data:
    name: aura-pro-redis-data
  db_data:
    name: aura-pro-db-data
EOF

echo -e "\033[34m[4/4] 正在拉取镜像并启动服务...\033[0m"
docker compose pull
docker compose up -d

echo -e "\033[32m✅ Aura Grid Pro 部署完成！\033[0m"
echo "访问地址: http://<你的IP>:8125"
