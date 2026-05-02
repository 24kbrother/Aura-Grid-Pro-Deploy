cat << 'EOF' > UNINSTALL.sh
#!/bin/bash

# ══════════════════════════════════════════════════════════════════════
#  Aura Grid (Shadow Home) — 全能深度卸载与环境清理脚本 (V2.1)
# ══════════════════════════════════════════════════════════════════════

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# 兼容所有已知版本的数据卷名称
TARGET_VOLUMES=(
    "aura-pro-db-data"
    "aura-pro-redis-data"
    "aura-db-data"
    "aura-redis-data"
    "shadow-db-data"
    "shadow-redis-data"
)

echo -e "${YELLOW}⚠️  正在启动 Aura Grid Pro 深度清理程序 (支持 LITE/PRO 兼容)...${NC}"

# 1. 停止容器
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${GREEN}🛑 正在关停所有相关容器...${NC}"
$DOCKER_COMPOSE down --volumes --remove-orphans >/dev/null 2>&1

# 强制清理可能残留的容器
FORCE_TARGETS=("aura-grid-pro" "aura-redis-pro" "aura-grid-lite" "aura-redis-lite")
for c in "${FORCE_TARGETS[@]}"; do
    docker rm -f "$c" >/dev/null 2>&1
done

# 2. 深度清理数据卷 (核心修复)
echo -e "\n${YELLOW}🛠️  正在扫描并清理数据卷 (Volumes)...${NC}"
for vol in $(docker volume ls -q); do
    # 检查是否在我们的黑名单中，或者是匿名卷(哈希值长度通常为64)
    if [[ " ${TARGET_VOLUMES[@]} " =~ " ${vol} " ]] || [ ${#vol} -eq 64 ]; then
        echo -e "♻️  正在强力移除卷: ${GREEN}${vol}${NC}"
        docker volume rm -f "$vol" >/dev/null 2>&1
    fi
done

# 3. 询问是否执行 Docker 全局清理 (清理虚悬镜像和缓存)
echo ""
read -p "❓ 是否执行 Docker 系统全局清理 (Prune) 以释放空间？(y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    docker system prune -af --volumes
    echo -e "${GREEN}✅ 全局清理完成。${NC}"
fi

# 4. 物理目录清理
echo ""
echo -e "${YELLOW}📂 检测到宿主机本地文件夹: data/ floorplans/ icons/${NC}"
read -p "❓ 是否删除这些本地配置目录 (删除后需重新激活)？(y/N): " del_dir
if [[ "$del_dir" =~ ^[Yy]$ ]]; then
    rm -rf data floorplans icons
    echo -e "${GREEN}✅ 本地目录已清空。${NC}"
fi

echo -e "\n${BOLD}${GREEN}===============================================${NC}"
echo -e "${BOLD}${GREEN}     Aura Grid 环境已彻底擦除 (干净如初)      ${NC}"
echo -e "${BOLD}${GREEN}===============================================${NC}"
EOF

chmod +x UNINSTALL.sh
./UNINSTALL.sh
