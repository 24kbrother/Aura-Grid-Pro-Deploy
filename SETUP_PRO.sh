#!/bin/bash

# =================================================================
# Aura Grid Pro 生产环境部署程序 (路径闭环版)
# =================================================================

# 预设参数
FIXED_USER="24kservice"
INPUT_TOKEN=$1
IMAGE="ghcr.io/24kbrother/aura-grid-pro:latest"
CENTRAL_API="https://api.vlanhub.com"

set -e#!/bin/bash

# =================================================================
# Aura Grid Pro 生产环境统一部署程序 (兼容 Lite 无缝升级)
# =================================================================

# 预设参数
FIXED_USER="24kservice"
INPUT_TOKEN=$1
VERSION="v1.8.0-PRO"
IMAGE_URL="ghcr.io/24kbrother/aura-grid-pro:${VERSION}"

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 交互输入工具函数
ask_input() {
    local prompt=$1
    local is_secret=$2
    local val
    if [ "$is_secret" = "true" ]; then
        read -sp "$(echo -e "${YELLOW}$prompt${NC}")" val < /dev/tty
    else
        read -p "$(echo -e "${YELLOW}$prompt${NC}")" val < /dev/tty
    fi
    echo "$val"
}

echo -e "${BLUE}==================================================${NC}"
echo -e "🏗️  ${GREEN}正在启动 Aura Grid Pro 部署程序 (2026 Build)${NC}"
echo -e "${BLUE}==================================================${NC}"

# --- 1. GHCR 登录校验 ---
echo -e "\n🔑 正在配置私有镜像访问权限..."

while true; do
    GH_TOKEN=${INPUT_TOKEN:-$(ask_input "请输入项目专属部署 Token: " "true")}
    [ -z "$INPUT_TOKEN" ] && echo ""

    if [ -z "$GH_TOKEN" ]; then
        echo -e "${RED}错误：Token 不能为空。${NC}"
        [ -n "$INPUT_TOKEN" ] && exit 1
        continue
    fi

    echo "正在校验权限..."
    if echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null; then
        echo -e "${GREEN}✅ 授权校验通过 (User: $FIXED_USER)${NC}"
        break
    else
        echo -e "${RED}❌ 授权失败！Token 可能无效或已过期。${NC}"
        if [ -n "$INPUT_TOKEN" ]; then
            exit 1
        fi
        echo "请重新尝试输入..."
    fi
done

# --- 2. 环境初始化与设备指纹处理 ---
WORKDIR=$(pwd)
echo -e "\n⚙️  正在当前目录 [${WORKDIR}] 初始化环境..."

# 创建核心挂载目录
mkdir -p ./data ./floorplans ./icons
chmod -R 777 ./data ./floorplans ./icons

# 检查/生成设备指纹以确保连续性
HWID_FILE="./data/device.id"
if [ -f "$HWID_FILE" ]; then
    EXISTING_HWID=$(cat "$HWID_FILE")
    echo -e "${GREEN}✅ 检测到已有设备指纹 (${EXISTING_HWID})，正在为您无缝继承...${NC}"
else
    # 生成一个新的标准 UUID
    NEW_HWID=$(cat /proc/sys/kernel/random/uuid)
    echo "$NEW_HWID" > "$HWID_FILE"
    echo -e "${GREEN}✨ 已生成全新设备指纹: ${NEW_HWID}${NC}"
fi

cat <<EOF > .env
# Aura Grid Pro Environment Configuration
GHCR_USER=$FIXED_USER
DEPLOY_PATH=$WORKDIR
# LICENSE 将在系统启动后通过 Web UI 配置
EOF

# --- 3. 生成精校版 Docker 编排 ---
echo -e "\n📦 生成编排文件..."

cat <<EOF > docker-compose.yml
services:
  aura-grid:
    image: ${IMAGE_URL}
    container_name: aura-grid-pro
    restart: always
    env_file: .env
    environment:
      - NODE_ENV=production
      - PORT=8500
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=file:/app/prisma/data/prod.db
      - FLOORPLANS_DIR=/app/floorplans
    ports:
      - "8125:8500"
    volumes:
      - ./data:/app/prisma/data
      - ./floorplans:/app/floorplans
      - ./icons:/app/icons
      # 💡 核心指纹映射：使得 Pro 系统的原生环境使用 Lite 固化指纹
      - ./data/device.id:/etc/machine-id:ro
    networks:
      - aura-net
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    container_name: aura-redis
    restart: always
    command: redis-server --save 60 1 --loglevel warning
    networks:
      - aura-net

networks:
  aura-net:
    driver: bridge
EOF

# --- 4. 执行部署 ---
echo -e "\n🚀 正在拉取生产镜像..."
docker compose pull

echo -e "🚀 正在启动容器服务..."
docker compose up -d

# --- 5. 生成升级脚本 ---
cat <<EOF > UPDATE_PRO.sh
#!/bin/bash
echo "正在执行 Aura Grid Pro 无损升级..."
echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null
docker compose pull && docker compose up -d --remove-orphans
echo "✅ 更新完成！"
EOF
chmod +x UPDATE_PRO.sh

# 获取本机 IP
IP_ADDR=$(hostname -I | awk '{print $1}')

echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 Aura Grid Pro 部署成功！"
echo -e "--------------------------------------------------"
echo -e "🔹 访问入口: ${BLUE}http://${IP_ADDR}:8125${NC}"
echo -e "🔹 请进入系统后，按照引导输入您的授权码 (License)"
echo -e "🔹 升级管理: sudo bash ./UPDATE_PRO.sh"
echo -e "${GREEN}==================================================${NC}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 交互输入工具函数
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

    echo "正在校验权限..."
    if echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null; then
        echo -e "${GREEN}✅ 授权校验通过${NC}"
        break
    else
        echo -e "${RED}❌ 授权失败！请检查 Token 是否正确。${NC}"
        [ -n "$INPUT_TOKEN" ] && exit 1
    fi
done

# --- 2. 环境初始化 ---
INSTALL_DIR=$(pwd)
echo -e "\n⚙️  正在初始化工作目录: $INSTALL_DIR"

# 确保本地目录存在
mkdir -p "$INSTALL_DIR/floorplans" "$INSTALL_DIR/icons" "$INSTALL_DIR/data"

# 生成 .env 配置文件
cat <<EOF > .env
PORT=8500
NODE_ENV=production
REDIS_URL=redis://aura-redis-pro:6379
# 💡 路径必须指向 /app/prisma/data/ 以对齐容器内的 chmod 指令
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
      - db_data:/app/prisma/data      # 💡 具名卷挂载到 prisma 目录下
      - ./floorplans:/app/floorplans
      - ./icons:/app/icons
      - ./data:/app/data              # 💡 物理路径用于存储 device.id 等
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
echo -e "\n🚀 正在拉取镜像并启动容器..."
docker compose pull
docker compose up -d

# --- 5. 生成升级脚本 ---
cat <<EOF > UPDATE_PRO.sh
#!/bin/bash
echo "正在执行无损升级..."
echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null
docker compose pull && docker compose up -d
echo "✅ 更新完成！"
EOF
chmod +x UPDATE_PRO.sh

IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 Aura Grid Pro 部署成功！"
echo -e "--------------------------------------------------"
echo -e "🔹 访问地址: http://${IP_ADDR}:8125"
echo -e "🔹 数据库文件位于具名卷 [aura-pro-db-data] 中"
echo -e "🔹 配置文件 (.env) 已持久化在当前目录"
echo -e "==================================================${NC}"
