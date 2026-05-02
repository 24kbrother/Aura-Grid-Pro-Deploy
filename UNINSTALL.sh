cat << 'EOF' > UNINSTALL.sh
#!/bin/bash
# Aura Grid 深度清理 V2.1
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'
TARGET_VOLUMES=("aura-pro-db-data" "aura-pro-redis-data" "aura-db-data" "aura-redis-data" "shadow-db-data" "shadow-redis-data")
echo -e "${YELLOW}⚠️  正在启动 Aura Grid Pro 深度清理程序...${NC}"
if docker compose version >/dev/null 2>&1; then DOCKER_COMPOSE="docker compose"; else DOCKER_COMPOSE="docker-compose"; fi
echo -e "${GREEN}🛑 正在关停所有相关容器...${NC}"
$DOCKER_COMPOSE down --volumes --remove-orphans >/dev/null 2>&1
FORCE_TARGETS=("aura-grid-pro" "aura-redis-pro" "aura-grid-lite" "aura-redis-lite")
for c in "${FORCE_TARGETS[@]}"; do docker rm -f "$c" >/dev/null 2>&1; done
echo -e "\n${YELLOW}🛠️  正在扫描并清理数据卷 (含匿名哈希卷)...${NC}"
for vol in $(docker volume ls -q); do
    if [[ " ${TARGET_VOLUMES[@]} " =~ " ${vol} " ]] || [ ${#vol} -eq 64 ]; then
        echo -e "♻️  正在移除卷: ${GREEN}${vol}${NC}"
        docker volume rm -f "$vol" >/dev/null 2>&1
    fi
done
echo ""
read -p "❓ 是否执行 Docker 系统全局清理 (Prune)？(y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    docker system prune -af --volumes
fi
read -p "❓ 是否删除本地配置目录 (data/floorplans)？(y/N): " del_dir
if [[ "$del_dir" =~ ^[Yy]$ ]]; then
    rm -rf data floorplans icons
fi
echo -e "\n${BOLD}${GREEN}✅ 清理流程结束！${NC}"
EOF

chmod +x UNINSTALL.sh
./UNINSTALL.sh
