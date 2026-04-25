#!/bin/bash

# =================================================================
# Aura Grid Pro 生产环境部署程序 (支持管道运行)
# =================================================================

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "🏗️  正在启动 Aura Grid Pro 部署..."

# 交互输入函数：专门处理 curl | bash 带来的 TTY 缺失问题
ask_input() {
    local prompt=$1
    local is_secret=$2
    local val
    # 强制从当前终端设备读取，而不是从管道读取
    if [ "$is_secret" = "true" ]; then
        read -sp "$(echo -e "${YELLOW}$prompt${NC}")" val < /dev/tty
    else
        read -p "$(echo -e "${YELLOW}$prompt${NC}")" val < /dev/tty
    fi
    echo "$val"
}

# --- 登录校验逻辑 ---
echo -e "\n🔑 正在配置私有镜像访问权限..."

while true; do
    GH_USER=$(ask_input "请输入 GitHub 用户名: " "false")
    echo "" # 换行
    GH_TOKEN=$(ask_input "请输入 GitHub Access Token (PAT): " "true")
    echo ""

    if [ -z "$GH_USER" ] || [ -z "$GH_TOKEN" ]; then
        echo -e "${RED}错误：用户名和 Token 不能为空。${NC}"
        continue
    fi

    echo "尝试登录 ghcr.io..."
    if echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin; then
        echo -e "${GREEN}✅ 登录成功！${NC}"
        break
    else
        echo -e "${RED}❌ 登录失败，请检查输入或网络。${NC}"
        echo -e "提示：中国大陆用户如遇超时，请检查系统代理或镜像加速设置。"
    fi
done

# --- 配置文件生成 ---
WORKDIR=$(pwd)
echo -e "\n⚙️  正在初始化配置文件..."
# 这里如果还需要输入 License，也用 ask_input
LICENSE_KEY=$(ask_input "请输入项目授权码 (License): " "false")
echo ""

cat <<EOF > .env
LICENSE=$LICENSE_KEY
GHCR_USER=$GH_USER
EOF

# --- 编排与启动 ---
cat <<EOF > docker-compose.yml
services:
  aura-grid:
    image: ghcr.io/24kbrother/aura-grid-pro:v1.7.19-PRO
    container_name: aura-grid-pro
    restart: always
    env_file: .env
    ports:
      - "8125:8125"
    volumes:
      - ./data:/app/data
EOF

echo -e "🚀 正在拉取镜像并启动..."
docker compose pull
docker compose up -d

echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 部署完成！访问地址: http://$(hostname -I | awk '{print $1}'):8125"
echo -e "${GREEN}==================================================${NC}"
