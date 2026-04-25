#!/bin/bash

# =================================================================
# Aura Grid Pro 一键部署脚本
# 适用环境: 飞牛NAS, Debian, Ubuntu, CentOS
# =================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

echo -e "${GREEN}>>> 开始部署 Aura Grid Pro...${NC}"

# 1. 权限检查
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 请使用 root 权限运行此脚本 (sudo -i)。${NC}"
    exit 1
fi

# 2. 检查 Docker 环境
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}检测到未安装 Docker，正在尝试安装...${NC}"
    curl -fsSL https://get.docker.com | bash -s docker
else
    echo -e "${GREEN}[OK] Docker 已安装${NC}"
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}检测到未安装 Docker-compose，正在自动配置...${NC}"
    # 兼容飞牛/Debian 的快速安装
    apt-get update && apt-get install -y docker-compose-plugin
    alias docker-compose='docker compose'
fi

# 3. 确定安装路径 (针对飞牛NAS优化)
CURRENT_DIR=$(pwd)
echo -e "${YELLOW}当前安装目录: ${CURRENT_DIR}${NC}"

# 4. 获取授权码 (增强交互性)
echo -e "${GREEN}请输入您的 Aura Grid Pro 授权码 (License Key):${NC}"
read -p "Key: " LICENSE_KEY

if [ -z "$LICENSE_KEY" ]; then
    echo -e "${RED}错误: 授权码不能为空，安装终止。${NC}"
    exit 1
fi

# 5. 写入配置文件
echo -e "${YELLOW}正在生成配置文件...${NC}"
cat <<EOF > .env
# Aura Grid Pro 配置文件
LICENSE=$LICENSE_KEY
DEPLOY_PATH=$CURRENT_DIR
EOF

# 6. 生成 docker-compose.yml (根据你的项目需求调整)
# 这里假设你的项目需要拉取镜像
cat <<EOF > docker-compose.yml
version: '3.8'
services:
  aura-grid:
    image: 24kbrother/aura-grid-pro:latest
    container_name: aura-grid-pro
    restart: always
    env_file: .env
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

# 7. 启动服务
echo -e "${GREEN}正在拉取镜像并启动容器...${NC}"
docker compose pull
docker compose up -d

# 8. 检查结果
if [ $? -eq 0 ]; then
    echo "------------------------------------------------"
    echo -e "${GREEN}部署成功！${NC}"
    echo -e "管理后台请查看项目文档说明。"
    echo -e "安装目录: ${CURRENT_DIR}"
    echo "------------------------------------------------"
else
    echo -e "${RED}部署过程中出现问题，请检查网络或日志。${NC}"
fi
