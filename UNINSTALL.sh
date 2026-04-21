#!/bin/bash

# ══════════════════════════════════════════════════════════════════════
#  Aura Grid (Shadow Home) — 一键卸载与环境清理脚本
# ══════════════════════════════════════════════════════════════════════

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 本项目专属 Docker 卷名称 (必须与 docker-compose.yml 一致)
PROJECT_VOLUMES=(
    "aura-pro-db-data"
    "aura-pro-redis-data"
)

# 兼容性：老用户可能使用的旧版卷名
LEGACY_VOLUMES=(
    "shadow-db-data"
    "shadow-redis-data"
)

echo -e "${YELLOW}⚠️  正在启动 Aura Grid Pro 环境清理与卸载程序 (支持旧版兼容)...${NC}"

# 0. 检测 Docker Compose 命令
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}❌ 错误: 未检测到 Docker Compose，请手动清理容器。${NC}"
    exit 1
fi

# 1. 停止并移除容器、网络及匿名卷
echo -e "${GREEN}🛑 正在停止容器并移除网络...${NC}"
if [ -f "docker-compose.prod.yml" ]; then
    $DOCKER_COMPOSE -f docker-compose.prod.yml down --volumes --remove-orphans
elif [ -f "docker-compose.yml" ]; then
    $DOCKER_COMPOSE down --volumes --remove-orphans
else
    echo -e "${YELLOW}⚠️  未找到 docker-compose 文件，跳过容器停止阶段。${NC}"
fi

# 2. 移除 Aura Grid 相关镜像
echo -e "${GREEN}🧹 正在清理 Aura Grid 相关镜像...${NC}"
IMAGES=$(docker images --format "{{.Repository}} {{.ID}}" | grep "aura-grid" | awk '{print $2}' | sort -u)
if [ -n "$IMAGES" ]; then
    echo "发现相关镜像，正在移除..."
    docker image rm -f $IMAGES 2>/dev/null
else
    echo "✨ 未发现 Aura Grid 相关镜像。"
fi

# 3. 强力全局清理 (危险区)
echo ""
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}🛑  高危操作确认：DOCKER 系统全局大扫除${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}注意：以下操作将执行 'docker system prune'，它的影响范围是全局的：${NC}"
echo -e " 1. 会删除【所有】已停止的容器（不仅限于 Aura Grid）。"
echo -e " 2. 会删除【所有】未被使用的 Docker 网络。"
echo -e " 3. 会删除【所有】虚悬镜像（Dangling Images）。"
echo -e " 4. 会清理【所有】构建缓存。"
echo ""
echo -e "${RED}警告：如果您还有其他正在运行或临时关闭的项目，此操作可能导致其数据/配置丢失。${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

read -p "❓ 您是否要执行此全局清理操作？(y/N): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}♻️  正在执行全局大扫除...${NC}"
    docker system prune -f 2>/dev/null
    echo -e "${GREEN}✅ 全局清理完成。${NC}"
else
    echo -e "${YELLOW}⏩ 已跳过全局清理，仅卸载了 Aura Grid 本身。${NC}"
fi

# 4. 项目专属数据持久化清理 (精准定点)
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "🛠️  数据持久化清理 (恢复出厂设置)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "正在扫描本项目关联的专属数据卷..."

# 合并所有需要扫描的卷
ALL_TARGET_VOLS=("${PROJECT_VOLUMES[@]}" "${LEGACY_VOLUMES[@]}")
FOUND_VIRTUAL_VOLS=0

for vol in "${ALL_TARGET_VOLS[@]}"; do
    if docker volume inspect "$vol" >/dev/null 2>&1; then
        # 针对旧版卷给出提示
        if [[ " ${LEGACY_VOLUMES[@]} " =~ " ${vol} " ]]; then
            echo -e " - ${YELLOW}找到旧版遗留卷: ${vol}${NC}"
        else
            echo -e " - ${GREEN}找到专属数据卷: ${vol}${NC}"
        fi
        FOUND_VIRTUAL_VOLS=1
    fi
done

if [ $FOUND_VIRTUAL_VOLS -eq 1 ]; then
    echo ""
    read -p "❓ 您是否要【彻底删除】上述所有数据库卷？(y/N): " vol_confirm
    if [[ "$vol_confirm" =~ ^[Yy]$ ]]; then
        for vol in "${ALL_TARGET_VOLS[@]}"; do
            if docker volume inspect "$vol" >/dev/null 2>&1; then
                echo -e "♻️  正在移除卷: $vol"
                docker volume rm -f "$vol" >/dev/null 2>&1
            fi
        done
        echo -e "${GREEN}✅ 所有关联数据卷已全部清理。${NC}"
    else
        echo -e "${YELLOW}⏩ 已保留数据卷。如需重新安装，您的旧数据仍会生效。${NC}"
    fi
else
    echo "✨ 未检测到任何已挂载的专属或遗留数据卷。"
fi

# 5. 宿主机物理文件清理 (完全恢复出厂设置)
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "📂  检测到宿主机本地持久化映射目录 (Bind Mounts)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
LOCAL_DIRS=("data" "floorplans" "icons")
FOUND_DIRS=()

for dir in "${LOCAL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        FOUND_DIRS+=("$dir")
    fi
done

if [ ${#FOUND_DIRS[@]} -gt 0 ]; then
    echo -e "当前目录下发现持久化文件夹: ${GREEN}${FOUND_DIRS[*]}${NC}"
    echo -e "------------------------------------------------------"
    echo -e "💡 ${BOLD}保留 (默认)${NC}: 保留激活授权、地板图、自定义图标和所有布局配置。"
    echo -e "🔥 ${RED}删除 (Factory Reset)${NC}: 彻底清空所有本地数据，下次安装需从零开始（需重新激活）。"
    echo -e "------------------------------------------------------"
    
    read -p "❓ 是否要彻底删除这些宿主机目录？[y/N] (默认保留): " delete_local
    if [[ "$delete_local" =~ ^[Yy]$ ]]; then
        for dir in "${FOUND_DIRS[@]}"; do
            echo -e "♻️  正在移除目录: $dir"
            rm -rf "$dir"
        done
        echo -e "${GREEN}✅ 宿主机本地持久化文件已全部清理成真空状态。${NC}"
    else
        echo -e "${GREEN}✅ 数据已保护：您的本地配置、底图和授权令牌已安全保留。${NC}"
    fi
else
    echo "✨ 未发现任何相关的宿主机持久化文件夹。"
fi

echo -e "\n${BOLD}${GREEN}===============================================${NC}"
echo -e "${BOLD}${GREEN}         Aura Grid Pro 卸载/清理流程结束          ${NC}"
echo -e "${BOLD}${GREEN}===============================================${NC}"
