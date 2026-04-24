#!/bin/bash

# =================================================================
# 🛡️ Aura Guard - Pro 生产环境安装脚本 (v1.7.19)
# 
# 用途: 首次安装 Aura Grid Pro 版时的环境初始化与一键启动
# 特性: 包含 Redis 缓存、Docker 感知挂载及私有镜像鉴权
# 设计: 24k.brother & Antigravity (Gemini)
# =================================================================

# 颜色控制
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏗️  正在按生产标准开启 Aura Grid Pro 部署流程...${NC}"

# 1. 变量预设
VERSION="v1.7.19-PRO"
GH_USER="24kbrother"
GH_REPO="aura-grid-pro"
IMAGE="ghcr.io/$GH_USER/$GH_REPO:${VERSION}"
INSTALL_DIR=$(pwd)
CENTRAL_API="https://api.vlanhub.com"

# 2. 权限与环境检测
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}❌ 请以 root 权限运行 (sudo ./SETUP_PRO.sh)${NC}"
  exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ 未检测到 Docker，请先安装 Docker。${NC}"
    exit 1
fi

# 3. GHCR 私有镜像鉴权
echo -e "${BLUE}🔑 正在检查镜像访问权限...${NC}"
if ! docker system info | grep -q "ghcr.io"; then
    if [ -z "$GH_TOKEN" ]; then
        echo -e "${RED}⚠️  检测到尚未登录 GHCR，拉取私有镜像需要 GitHub Token。${NC}"
        read -p "请输入您的 GitHub PAT (Token): " GH_TOKEN
    fi
    
    if [ ! -z "$GH_TOKEN" ]; then
        echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ 登录失败，请核对 Token 权限。${NC}"
            exit 1
        fi
    fi
fi

# 4. 初始化物理目录与生成设备指纹 (HWID)
echo -e "${BLUE}📂 正在初始化物理映射目录与设备指纹...${NC}"
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/floorplans"
mkdir -p "$INSTALL_DIR/icons"
chmod -R 777 "$INSTALL_DIR/data" "$INSTALL_DIR/floorplans" "$INSTALL_DIR/icons"

# 定义 HWID 文件路径
HWID_FILE="$INSTALL_DIR/data/device.id"

# 检查是否存在 device.id
if [ -f "$HWID_FILE" ]; then
    # 如果存在，说明是覆盖安装或迁移，直接读取并显示
    EXISTING_HWID=$(cat "$HWID_FILE")
    echo -e "${GREEN}✅ 检测到已有设备指纹，授权将无损继承: ${EXISTING_HWID}${NC}"
else
    # 如果不存在，调用内核接口生成一个标准的 UUID v4
    NEW_HWID=$(cat /proc/sys/kernel/random/uuid)
    echo "$NEW_HWID" > "$HWID_FILE"
    echo -e "${GREEN}✨ 已生成全新设备指纹: ${NEW_HWID}${NC}"
fi

# 5. 自动生成生产环境 .env
echo -e "${BLUE}⚙️  正在生成生产环境配置文件 (.env)...${NC}"
cat <<EOF > "$INSTALL_DIR/.env"
# Aura Grid Pro - 核心设置
PORT=8125
NODE_ENV=production

# 存储路径对齐 (镜像内部标准)
DATABASE_URL=file:/app/prisma/data/prod.db
REDIS_URL=redis://redis:6379
FLOORPLANS_DIR=/app/floorplans

# 授权中心对接 (Aura Guard Central)
LICENSE_SERVER_URL=$CENTRAL_API
EOF

# 6. 生成生产级 docker-compose.yml
echo -e "${BLUE}📦 正在生成生产级 Docker 编排文件...${NC}"
cat <<EOF > "$INSTALL_DIR/docker-compose.yml"
# ══════════════════════════════════════════════════════════
#  Aura Grid Pro — Final Hardened Production Compose
#  Powered by Aura Guard v1.7.19
# ══════════════════════════════════════════════════════════

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
    environment:
      - PORT=8500
      - NODE_ENV=production
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=file:/app/prisma/data/prod.db
      - FLOORPLANS_DIR=/app/floorplans
      - LICENSE_SERVER_URL=$CENTRAL_API
    volumes:
      - db_data:/app/prisma/data
      - ./floorplans:/app/floorplans
      - ./icons:/app/icons
      - ./data:/app/data   # 💡 核心：把 device.id 生成在这里！
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

# 7. 拉取并启动
echo -e "${BLUE}🚀 正在执行镜像同步并启动容器...${NC}"
docker compose pull
docker compose up -d

# 8. 自动生成配套的升级运维脚本
echo -e "${BLUE}🛠️  正在生成系统升级工具 (UPDATE_PRO.sh)...${NC}"
cat <<EOF > "$INSTALL_DIR/UPDATE_PRO.sh"
#!/bin/bash
# ==========================================
# 🛡️ Aura Guard - Pro 生产环境无损升级脚本
# ==========================================
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 检查是否具备 Docker 权限
if ! docker info >/dev/null 2>&1; then
  echo -e "\${RED}❌ Docker 权限不足。请使用 sudo bash ./UPDATE_PRO.sh 运行此脚本。\${NC}"
  exit 1
fi

echo -e "\${BLUE}🔄 正在与 Aura Central 同步最新 Pro 镜像...\${NC}"
docker compose pull aura-grid

echo -e "\${BLUE}🚀 正在无缝重启容器应用更新...\${NC}"
docker compose up -d --remove-orphans aura-grid

echo -e "\${GREEN}✅ 升级完成！您的核心配置与 HWID 授权已无损继承。\${NC}"
EOF

# 9. 引导输出 (更新你的最后输出信息)
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 Aura Grid Pro (Hardened Edition) 部署成功！${NC}"
echo -e "--------------------------------------------------"
echo -e "🔹 访问入口: http://${IP_ADDR}:8125"
echo -e "🔹 核心数据已持久化至当前目录的 ./data 文件夹中"
echo -e "${GREEN}==================================================${NC}"
echo -e "💡 日常运维提示："
echo -e "   当系统提示有新版本时，请在当前目录执行以下命令进行无损升级："
echo -e "   ${BLUE}sudo bash ./UPDATE_PRO.sh${NC}"
