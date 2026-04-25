#!/bin/bash

# =================================================================
# Aura Grid Pro 生产环境部署程序 (路径对齐版)
# =================================================================

FIXED_USER="24kservice"
INPUT_TOKEN=$1
IMAGE="ghcr.io/24kbrother/aura-grid-pro:v1.7.19-PRO"
CENTRAL_API="https://api.vlanhub.com"

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ask_input() {
    local prompt=$1
    local val
    read -p "$(echo -e "${YELLOW}$prompt${NC}")" val < /dev/tty
    echo "$val"
}

echo -e "${BLUE}==================================================${NC}"
echo -e "🏗️  正在启动 Aura Grid Pro 部署程序"
echo -e "${BLUE}==================================================${NC}"

# --- 1. GHCR 登录校验 ---
while true; do
    GH_TOKEN=${INPUT_TOKEN:-$(ask_input "请输入项目专属部署 Token: ")}
    if [ -z "$GH_TOKEN" ]; then
        echo -e "${RED}错误：Token 不能为空。${NC}"
        [ -n "$INPUT_TOKEN" ] && exit 1
        continue
    fi
    if echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null; then
        echo -e "${GREEN}✅ 授权校验通过${NC}"
        break
    else
        echo -e "${RED}❌ 授权失败！${NC}"
        [ -n "$INPUT_TOKEN" ] && exit 1
    fi
done

# --- 2. 环境初始化 ---
INSTALL_DIR=$(pwd)
mkdir -p "$INSTALL_DIR/floorplans" "$INSTALL_DIR/icons" "$INSTALL_DIR/data"

cat <<EOF > .env
PORT=8500
NODE_ENV=production
REDIS_URL=redis://aura-redis-pro:6379
DATABASE_URL="file:/app/prisma/data/prod.db"
FLOORPLANS_DIR=/app/floorplans
LICENSE_SERVER_URL=$CENTRAL_API
GHCR_USER=$FIXED_USER
EOF

# --- 3. 生成 Docker 编排文件 ---
cat <<EOF > docker-compose.yml
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
    image: $IMAGE
    container_name: aura-grid-pro
    restart: unless-stopped
    env_file: .env
    volumes:
      - db_data:/app/prisma/data
      - ./floorplans:/app/floorplans
      - ./icons:/app/icons
      - ./data:/app/data
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

# --- 4. 执行部署 ---
echo -e "\n🚀 正在拉取镜像并启动..."
docker compose pull
docker compose up -d

# --- 5. 生成升级脚本 ---
cat <<EOF > UPDATE_PRO.sh
#!/bin/bash
echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null
docker compose pull && docker compose up -d
echo "✅ 更新完成！"
EOF
chmod +x UPDATE_PRO.sh

IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 部署成功！"
echo -e "🔹 访问地址: http://${IP_ADDR}:8125"
echo -e "==================================================${NC}"
