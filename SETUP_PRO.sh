#!/bin/bash

# =================================================================
# Aura Grid Pro (Private Edition) 部署脚本
# -----------------------------------------------------------------
# 功能：自动环境检测、私有仓库交互登录、持久化配置、无损升级支持
# =================================================================

set -e # 遇到错误立即停止执行

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==================================================${NC}"
echo -e "🏗️  ${GREEN}正在启动 Aura Grid Pro 生产环境部署程序...${NC}"
echo -e "${BLUE}==================================================${NC}"

# 1. 环境预检
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 必须使用 root 权限运行。请尝试: sudo bash${NC}"
    exit 1
fi

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}未检测到 Docker，正在自动安装...${NC}"
    curl -fsSL https://get.docker.com | bash -s docker
fi

# 检查/适配 docker-compose 命令
DOCKER_COMPOSE="docker compose"
if ! $DOCKER_COMPOSE version &> /dev/null; then
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        echo -e "${YELLOW}正在安装 docker-compose-plugin...${NC}"
        apt-get update && apt-get install -y docker-compose-plugin || yum install -y docker-compose-plugin
    fi
fi

# 2. 交互式凭证获取 (解决 unauthorized 问题的核心)
echo -e "\n🔑 ${YELLOW}正在配置私有镜像访问权限...${NC}"
echo -e "注：由于镜像托管在 GHCR 私有仓库，请提供授权凭证。"

# 只有在未登录或登录失效时才要求输入
while ! docker login ghcr.io &>/dev/null; do
    read -p "请输入 GitHub 用户名 (或项目提供的 ID): " GH_USER
    read -sp "请输入 GitHub Access Token (PAT): " GH_TOKEN
    echo -e "\n"
    
    if echo "$GH_TOKEN" | docker login ghcr.io -u "$GH_USER" --password-stdin; then
        echo -e "${GREEN}✅ 登录成功！${NC}"
        break
    else
        echo -e "${RED}❌ 登录失败，请检查用户名或 Token 是否正确。${NC}"
        echo -e "提示：请确保 Token 具有 'read:packages' 权限。"
    fi
done

# 3. 核心变量配置
WORKDIR=$(pwd)
ENV_FILE="${WORKDIR}/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "\n⚙️  ${YELLOW}正在生成生产环境配置文件 (.env)...${NC}"
    read -p "请输入您的项目 License Key (如果有): " LICENSE_KEY
    cat <<EOF > "$ENV_FILE"
# Aura Grid Pro Config
LICENSE=$LICENSE_KEY
GHCR_USER=$GH_USER
DEPLOY_TIME=$(date '+%Y-%m-%d %H:%M:%S')
EOF
else
    echo -e "✅ 检测到已有配置文件，跳过生成。"
fi

# 4. 生成 docker-compose.yml
# 注意：镜像版本建议使用变量，方便你以后维护
IMAGE_TAG="v1.7.19-PRO" 

cat <<EOF > docker-compose.yml
services:
  aura-grid:
    image: ghcr.io/24kbrother/aura-grid-pro:${IMAGE_TAG}
    container_name: aura-grid-pro
    restart: always
    env_file: .env
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

# 5. 执行同步与启动
echo -e "\n🚀 ${YELLOW}正在同步镜像并启动容器...${NC}"
$DOCKER_COMPOSE pull
$DOCKER_COMPOSE up -d

# 6. 生成升级工具 (方便用户后期维护)
cat <<EOF > UPDATE_PRO.sh
#!/bin/bash
echo "正在检查更新..."
docker login ghcr.io -u "$GH_USER" --password-stdin <<< "$GH_TOKEN"
$DOCKER_COMPOSE pull
$DOCKER_COMPOSE up -d
echo "✅ 更新完成！"
EOF
chmod +x UPDATE_PRO.sh

# 7. 部署报告
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\n${GREEN}==================================================${NC}"
echo -e "🎉 ${GREEN}Aura Grid Pro 部署成功！${NC}"
echo -e "--------------------------------------------------"
echo -e "🔹 访问地址: ${BLUE}http://${IP_ADDR}:8125${NC} (请确保端口已放行)"
echo -e "🔹 部署目录: ${WORKDIR}"
echo -e "🔹 升级管理: sudo ./UPDATE_PRO.sh"
echo -e "${GREEN}==================================================${NC}"
