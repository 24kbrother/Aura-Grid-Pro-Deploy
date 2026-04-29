#!/bin/bash

# =================================================================
# 👑 Aura Grid Pro 生产环境多态一键安装/升级程序 (2026 坚不可摧版)
# 支持：
#   1. 检测到 Lite 全自动安全热升级 (无损继承)
#   2. 从未安装 Lite 的全新正版首装
# =================================================================

# 预设参数
FIXED_USER="24kservice"
INPUT_TOKEN=$1
VERSION="latest"
IMAGE_URL="ghcr.io/24kbrother/aura-grid-pro:${VERSION}"


set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- 0. 权限与 NAS 命令行降级防御 ---
DOCKER_CMD="docker"
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
        DOCKER_CMD="sudo docker"
    fi
fi

# 兼容老旧版本 Docker 的 docker-compose/docker compose 判定
COMPOSE_CMD="$DOCKER_CMD compose"
if ! $DOCKER_CMD compose version &>/dev/null; then
    if command -v docker-compose &>/dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "${RED}❌ 未检测到 docker compose 核心组件，请先安装 Docker 环境。${NC}"
        exit 1
    fi
fi

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
echo -e "🏗️  ${GREEN}正在启动 Aura Grid Pro 交付管理程序${NC}"
echo -e "${BLUE}==================================================${NC}"

# --- 0.5 临时网络代理加速（可选） ---
echo -e "\n🌐 代理加速配置 (直接回车可跳过)："
read -p "$(echo -e "${YELLOW}国内环境拉取若较慢，请输入代理服务器地址 (例如 http://127.0.0.1:7890): ${NC}")" PROXY_URL < /dev/tty
if [ -n "$PROXY_URL" ]; then
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    echo -e "${GREEN}✅ 已为当前安装流载入临时网络代理。${NC}\n"
fi


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

    echo "正在校验云端部署授权..."
    if echo "$GH_TOKEN" | $DOCKER_CMD login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null; then
        echo -e "${GREEN}✅ 授权校验通过 (User: $FIXED_USER)${NC}"
        break
    else
        echo -e "${RED}❌ 授权失败！Token 可能无效或已过期。${NC}"
        if [ -n "$INPUT_TOKEN" ]; then
            exit 1
        fi
        continue
    fi
done

# --- 2. 状态嗅探与环境动态决策 ---
echo -e "\n🔍 正在进行系统环境拓扑扫描..."

# A. 嗅探是否有 Lite 正在运行，并拔出其真实的宿主机挂载目录
LITE_CONTAINER=$($DOCKER_CMD ps -q -f name=aura-grid)
LITE_DIR=""

if [ -n "$LITE_CONTAINER" ]; then
    LITE_PHYSICAL_PATH=$($DOCKER_CMD inspect --format='{{range .Mounts}}{{if eq .Destination "/app/data"}}{{.Source}}{{end}}{{end}}' "$LITE_CONTAINER" 2>/dev/null || true)
    if [ -n "$LITE_PHYSICAL_PATH" ]; then
        LITE_DIR=$(dirname "$LITE_PHYSICAL_PATH")
    fi
fi

if [ -z "$LITE_DIR" ] && [ -f "./docker-compose.yml" ]; then
    if grep -q 'ghcr.io/24kbrother/aura-grid:' ./docker-compose.yml 2>/dev/null; then
        LITE_DIR=$(pwd)
    fi
fi

if [ -n "$LITE_DIR" ] && [ -d "$LITE_DIR" ]; then
    echo -e "╔══════════════════════════════════════════════════════╗"
    echo -e "║        ⚡   检测到 AURA-LITE 版历史痕迹！          ║"
    echo -e "╚══════════════════════════════════════════════════════╝"
    echo -e "  已成功锁定您的历史安装物理路径: ${BLUE}${LITE_DIR}${NC}"
    echo -e "  我们将执行 ${GREEN}【一键安全热升级】${NC}："
    echo -e "  ✨ 自动迁移您的历史全量数据库、户型图和自定义图标。"
    echo -e "  ✨ 设备指纹完美继承，绝不触发 30 天封锁死锁。"
    echo -e " --------------------------------------------------------"
    read -p "$(echo -e "  按 ${YELLOW}任意键${NC} 开启无缝跨代升级，或 Ctrl+C 退出：") " </dev/tty

    cd "$LITE_DIR"
    WORKDIR=$(pwd)

    echo -e "${YELLOW}⚙️  正在停止并解耦 LITE 容器实例...${NC}"
    $DOCKER_CMD stop aura-grid aura-redis 2>/dev/null || true
    $DOCKER_CMD rm   aura-grid aura-redis 2>/dev/null || true

    if $DOCKER_CMD volume inspect aura-db-data &>/dev/null; then
        echo -e "${YELLOW}📦 正在为您的历史配置建立独立迁移...${NC}"
        mkdir -p ./data
        $DOCKER_CMD run --rm \
            -v aura-db-data:/source \
            -v "$(pwd)/data":/dest \
            alpine sh -c "cp -f /source/prod.db /dest/prod.db 2>/dev/null || true" 2>/dev/null || true
    fi
else
    # 【场景二】全新首装模式
    # 💡 无条件为全新安装环境创建并收拢至专用子目录 ./aura-pro，坚决不弄脏当前目录
    mkdir -p ./aura-pro
    cd ./aura-pro
    WORKDIR=$(pwd)
    echo -e "${GREEN}✨ 未检测到历史安装，当前将开启【PRO 专属正版首装】模式。${NC}"
    echo -e "📂 本次服务将被安全安装在物理路径: ${BLUE}${WORKDIR}${NC}"
fi



# --- 3. 部署统一配置准备 ---
mkdir -p "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons"
chmod -R 777 "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons"

HWID_FILE="$WORKDIR/data/device.id"
if [ ! -f "$HWID_FILE" ]; then
    # 多级 UUID 物理兼容回退
    if [ -f /proc/sys/kernel/random/uuid ]; then
        NEW_HWID=$(cat /proc/sys/kernel/random/uuid)
    elif command -v uuidgen &>/dev/null; then
        NEW_HWID=$(uuidgen)
    else
        NEW_HWID=$(od -x /dev/urandom | head -n 1 | awk '{print $2$3"-"$4"-"$5"-"$6"-"$7$8$9}')
    fi
    echo "$NEW_HWID" > "$HWID_FILE"
fi

cat <<EOF > "$WORKDIR/.env"
GHCR_USER=$FIXED_USER
DEPLOY_PATH=$WORKDIR
EOF

# --- 4. 生成 PRO 版一致性编排文件 ---
cat <<EOF > "$WORKDIR/docker-compose.yml"
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
      - ./data/device.id:/etc/machine-id:ro
    networks:
      - aura-net
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    container_name: aura-redis-pro
    restart: always
    command: redis-server --save 60 1 --loglevel warning
    volumes:
      - redis_pro_data:/data
    networks:
      - aura-net

networks:
  aura-net:
    driver: bridge

volumes:
  redis_pro_data:
    name: aura-redis-pro-data
EOF

# --- 5. 执行一键启动 ---
echo -e "\n🚀 正在拉取最新的 PRO 黄金镜像..."
$COMPOSE_CMD pull

echo -e "🚀 正在启动 Aura Grid Pro 服务组..."
$COMPOSE_CMD up -d

cat <<EOF > "$WORKDIR/UPDATE_PRO.sh"
#!/bin/bash
echo "正在执行 Aura Grid Pro 无损更新..."
if command -v sudo &>/dev/null; then
    sudo docker login ghcr.io -u "$FIXED_USER" -p "$GH_TOKEN" &>/dev/null
    sudo docker compose pull && sudo docker compose up -d --remove-orphans
else
    docker login ghcr.io -u "$FIXED_USER" -p "$GH_TOKEN" &>/dev/null
    docker compose pull && docker compose up -d --remove-orphans
fi
echo "✅ 更新完成！"
EOF
chmod +x "$WORKDIR/UPDATE_PRO.sh"

# 优雅多端 IP 获取 (兼容纯净版 BusyBox grep)
IP_ADDR=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
if [ -z "$IP_ADDR" ]; then
    IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
[ -z "$IP_ADDR" ] && IP_ADDR="127.0.0.1"

echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 Aura Grid Pro 部署交接成功！"
echo -e "--------------------------------------------------"
echo -e "🔹 访问入口: ${BLUE}http://${IP_ADDR}:8125${NC}"
echo -e "🔹 安装目录: ${BLUE}${WORKDIR}${NC}"
echo -e "🔹 升级更新: bash ./UPDATE_PRO.sh"
echo -e "${GREEN}==================================================${NC}"
