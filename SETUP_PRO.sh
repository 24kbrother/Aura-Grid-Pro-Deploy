#!/bin/bash

# =================================================================
# Aura Grid Pro 生产环境统一部署程序 (兼容 Lite 无缝升级)
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

# --- 2. Lite 环境冲突检测 ---
WORKDIR=$(pwd)

# 三重指纹检测：覆盖所有历史 Lite 版本（v1.0.1 ~ 最新脚本版）
IS_LITE_DIR=false
if [ -f "./docker-compose.yml" ]; then
    if grep -qE 'aura-grid(-lite)?:|aura-internal|aura-lite-internal' ./docker-compose.yml 2>/dev/null \
       && ! grep -q 'aura-grid-pro' ./docker-compose.yml 2>/dev/null; then
        IS_LITE_DIR=true
    fi
fi
if docker ps --format '{{.Names}}' 2>/dev/null | grep -qE '^aura-grid(-lite)?$'; then
    IS_LITE_DIR=true
fi
if docker volume ls --format '{{.Name}}' 2>/dev/null | grep -qE '^aura-(db|lite-db)-data$'; then
    IS_LITE_DIR=true
fi

UPGRADE_MODE="fresh"  # fresh | parallel | overwrite

if [ "$IS_LITE_DIR" = "true" ]; then
    echo ""
    echo -e "╔══════════════════════════════════════════════════════╗"
    echo -e "║         ⚠️   检测到 Aura Grid Lite 环境！          ║"
    echo -e "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo -e "  当前目录或系统中存在正在运行的 ${YELLOW}Lite${NC} 版本。"
    echo -e "  请选择您的升级方式："
    echo ""
    echo -e "  ${GREEN}[1] 推荐：平行安装（Lite 与 Pro 共存，互不影响）${NC}"
    echo -e "      ${GREEN}→ 请 Ctrl+C 退出，在新目录中重新执行此脚本${NC}"
    echo -e "      ${GREEN}  例：mkdir ~/aura-pro && cd ~/aura-pro && bash ./SETUP_PRO.sh${NC}"
    echo ""
    echo -e "  [2] 覆盖升级（在当前目录替换 Lite 为 Pro）"
    echo -e "      ${RED}⚠️  重要警告：该操作具有一定风险！${NC}"
    echo -e "      ${RED}   请务必先进入 Lite Web 界面 → 系统设置，${NC}"
    echo -e "      ${RED}   完成「导出布局配置」或「导出全量工程备份」${NC}"
    echo -e "      ${RED}   再回到此处执行覆盖升级操作！${NC}"
    echo ""
    read -p "$(echo -e "  请输入 [1] 跳出 / [2] 覆盖升级：") " LITE_CHOICE < /dev/tty

    if [ "$LITE_CHOICE" = "2" ]; then
        # 二次确认
        echo ""
        echo -e "  ${RED}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}║          ⛔  最终确认 — 高风险操作                 ║${NC}"
        echo -e "  ${RED}╚══════════════════════════════════════════════════════╝${NC}"
        echo -e "  ${RED}  您即将停止 Lite 版本并覆盖其配置文件！${NC}"
        echo -e "  ${RED}  若未提前备份数据，配置数据将有丢失风险。${NC}"
        echo ""
        read -p "$(echo -e "  ${RED}确认继续？请输入大写 YES 确认，其他任意键取消：${NC} ") " FINAL_CONFIRM < /dev/tty
        if [ "$FINAL_CONFIRM" != "YES" ]; then
            echo -e "\n${GREEN}✅ 已取消覆盖操作，Lite 版本保持不变。${NC}"
            echo -e "   建议：在新目录执行脚本进行平行安装。"
            exit 0
        fi
        UPGRADE_MODE="overwrite"
        echo ""
        echo -e "${YELLOW}⚙️  正在停止并清理 Lite 容器...${NC}"
        docker stop aura-grid aura-grid-lite aura-redis aura-redis-lite 2>/dev/null || true
        docker rm   aura-grid aura-grid-lite aura-redis aura-redis-lite 2>/dev/null || true

        # 尝试从具名 Volume 导出 SQLite 数据库（兼容所有历史版本）
        mkdir -p ./data
        for VOL in aura-db-data aura-lite-db-data; do
            if docker volume inspect "$VOL" &>/dev/null; then
                echo -e "${YELLOW}📦 正在从 Volume [$VOL] 迁移数据库...${NC}"
                docker run --rm \
                    -v "$VOL":/source \
                    -v "$(pwd)/data":/dest \
                    alpine sh -c "cp -f /source/prod.db /dest/prod.db 2>/dev/null || echo '目录为空，跳过'" 2>/dev/null || true
                echo -e "${GREEN}✅ 数据库已迁移至 ./data/prod.db${NC}"
                break
            fi
        done
    else
        # 选 [1] 或任何非 2 输入 → 直接退出引导
        echo ""
        echo -e "${GREEN}✅ 已退出。请在新目录中重新执行脚本以完成平行安装。${NC}"
        echo -e "   例：${BLUE}mkdir ~/aura-pro && cd ~/aura-pro && bash ./SETUP_PRO.sh${NC}"
        exit 0
    fi
fi

# --- 3. 环境初始化与设备指纹处理 ---
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
