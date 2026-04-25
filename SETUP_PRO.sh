#!/bin/bash

# =================================================================
# Aura Grid Pro 生产环境部署程序 (精简版 - 仅处理环境与镜像)
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

# 交互输入工具函数 (强制指向 TTY)
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
    # 优先使用命令行参数，否则交互输入
    GH_TOKEN=${INPUT_TOKEN:-$(ask_input "请输入项目专属部署 Token: " "true")}
    [ -z "$INPUT_TOKEN" ] && echo "" # 交互模式补回换行

    if [ -z "$GH_TOKEN" ]; then
        echo -e "${RED}错误：Token 不能为空。${NC}"
        [ -n "$INPUT_TOKEN" ] && exit 1
        continue
    fi

    echo "正在校验权限..."
    # 尝试登录并将错误输出重定向，保持界面整洁
    if echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null; then
        echo -e "${GREEN}✅ 授权校验通过 (User: $FIXED_USER)${NC}"
        break
    else
        echo -e "${RED}❌ 授权失败！Token 可能无效或已过期。${NC}"
        if [ -n "$INPUT_TOKEN" ]; then
            echo "请检查提供的 Token 参数。"
            exit 1
        fi
        echo "请重新尝试输入..."
    fi
done

# --- 2. 环境初始化 ---
WORKDIR=$(pwd)
echo -e "\n⚙️  正在当前目录 [${WORKDIR}] 初始化生产环境..."

# 生成空的或基础的 .env (License 由用户稍后在 Web 端输入)
cat <<EOF > .env
# Aura Grid Pro Environment Configuration
GHCR_USER=$FIXED_USER
DEPLOY_PATH=$WORKDIR
# LICENSE 将在系统启动后通过 Web UI 配置
EOF

# --- 3. 生成 Docker 编排 ---
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
echo -e "\n🚀 正在拉取生产镜像..."
docker compose pull

echo -e "🚀 正在启动容器服务..."
docker compose up -d

# --- 5. 生成升级脚本 (自动锁定凭证) ---
cat <<EOF > UPDATE_PRO.sh
#!/bin/bash
echo "正在执行 Aura Grid Pro 无损升级..."
echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null
docker compose pull && docker compose up -d
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
