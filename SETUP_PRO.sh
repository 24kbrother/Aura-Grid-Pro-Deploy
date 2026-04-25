#!/bin/bash

# =================================================================
# Aura Grid Pro 生产环境部署程序 (2026 稳定版)
# =================================================================

# 预设参数
FIXED_USER="24kservice"
INPUT_TOKEN=$1

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 交互输入工具函数 (强制指向 TTY，输入内容可见)
ask_input() {
    local prompt=$1
    local val
    read -p "$(echo -e "${YELLOW}$prompt${NC}")" val < /dev/tty
    echo "$val"
}

echo -e "${BLUE}==================================================${NC}"
echo -e "🏗️  ${GREEN}正在启动 Aura Grid Pro 部署程序${NC}"
echo -e "${BLUE}==================================================${NC}"

# --- 1. GHCR 登录校验 ---
echo -e "\n🔑 正在配置私有镜像访问权限..."

while true; do
    # 优先使用命令行参数，否则交互输入
    if [ -z "$INPUT_TOKEN" ]; then
        GH_TOKEN=$(ask_input "请输入项目专属部署 Token: ")
    else
        GH_TOKEN=$INPUT_TOKEN
    fi

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
        echo -e "${RED}❌ 授权失败！Token 错误或已失效。${NC}"
        if [ -n "$INPUT_TOKEN" ]; then
            echo "请检查提供的参数是否正确。"
            exit 1
        fi
        echo "请重新尝试输入..."
    fi
done

# --- 2. 环境初始化 ---
WORKDIR=$(pwd)
echo -e "\n⚙️  正在初始化工作目录: ${WORKDIR}"

# 生成 .env 配置文件 (完全对齐你的生产环境需求)
cat <<EOF > .env
# 基础配置
PORT=8125
NODE_ENV=production

# 授权与安全 (用户进入系统后配置)
HA_URL=
HA_TOKEN=
ACCESS_PASSWORD=

# 数据库连接 (映射到容器内的 /app/data 目录)
DATABASE_URL="file:/app/data/prod.db"

# Redis 连接 (对应下方 docker-compose 中的服务名)
REDIS_URL="redis://aura-redis:6379"

# 部署元数据
GHCR_USER=$FIXED_USER
EOF

# --- 3. 生成 Docker 编排文件 ---
IMAGE_URL="ghcr.io/24kbrother/aura-grid-pro:v1.7.19-PRO"

cat <<EOF > docker-compose.yml
services:
  aura-grid:
    image: ${IMAGE_URL}
    container_name: aura-grid-pro
    restart: always
    env_file: .env
    ports:
      - "8125:8125"
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    networks:
      - aura-net
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    container_name: aura-redis
    restart: always
    networks:
      - aura-net

networks:
  aura-net:
    driver: bridge
EOF

# --- 4. 执行部署 ---
echo -e "\n🚀 正在拉取私有镜像..."
docker compose pull

echo -e "🚀 正在启动服务容器..."
docker compose up -d

# --- 5. 生成升级脚本 (自动锁定凭证) ---
cat <<EOF > UPDATE_PRO.sh
#!/bin/bash
echo "正在执行 Aura Grid Pro 无损升级..."
# 使用部署时的 Token 重新登录以确保权限
echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null
docker compose pull && docker compose up -d
echo "✅ 更新完成！"
EOF
chmod +x UPDATE_PRO.sh

# 获取内网 IP 地址
IP_ADDR=$(hostname -I | awk '{print $1}')

echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 Aura Grid Pro 部署成功！"
echo -e "--------------------------------------------------"
echo -e "🔹 访问入口: ${BLUE}http://${IP_ADDR}:8125${NC}"
echo -e "🔹 授权配置: 请在浏览器打开上方链接后输入 License"
echo -e "🔹 维护更新: sudo bash ./UPDATE_PRO.sh"
echo -e "${GREEN}==================================================${NC}"
