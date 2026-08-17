#!/bin/bash
# =================================================================
#  Aura Grid Pro — Aliyun ACR Pull & Auto-Update Tool
#  Usage: curl -sSL http://auragrid.cn/PULL_PRO_FORM_ALIYUN.sh | bash
# =================================================================

ALIYUN_IMAGE="crpi-z60uur6y0xgl3fgs.cn-chengdu.personal.cr.aliyuncs.com/aura-grid/aura-grid-pro:latest"
GHCR_IMAGE="ghcr.io/24kbrother/aura-grid-pro:latest"

echo -e "\033[1;34m[*] 正在通过阿里云极速通道拉取最新 PRO 镜像...\033[0m"
if docker pull "$ALIYUN_IMAGE"; then
    echo -e "\033[1;34m[*] 正在本地对齐官方容器标识...\033[0m"
    if docker tag "$ALIYUN_IMAGE" "$GHCR_IMAGE"; then
        # 清理阿里云临时长标签
        docker rmi "$ALIYUN_IMAGE" >/dev/null 2>&1 || true

        echo -e "\033[0;32m[SUCCESS] 最新镜像已成功就绪！\033[0m"
        echo -e "🔹 镜像标识: \033[1;32m$GHCR_IMAGE\033[0m"
        echo ""
    else
        echo -e "\033[0;31m[ERROR] 镜像本地打标对齐失败。\033[0m"
        exit 1
    fi
else
    echo -e "\033[0;31m[ERROR] 从阿里云极速通道拉取镜像失败，请检查网络。\033[0m"
    exit 1
fi

# ─── 智能更新询问交互 ─────────────────────────────────────────────
echo -e "\033[1;33m----------------------------------------------------------------\033[0m"
echo -e "🚀 镜像已拉取完毕。是否现在立即重启并更新容器到最新版？"
echo -e "👉 \033[1;32m按 [回车] 或输入 Y 立即更新\033[0m | \033[0;37m输入 N 或按 Ctrl+C 稍后手动更新\033[0m"
echo -e "\033[1;33m----------------------------------------------------------------\033[0m"

# 从 /dev/tty 读取输入，完美支持 curl | bash 模式
CONFIRM="Y"
if [ -t 0 ]; then
    read -p "请选择 [Y/n] (默认: Y): " INPUT_CHOICE
else
    if [ -e /dev/tty ]; then
        read -p "请选择 [Y/n] (默认: Y): " INPUT_CHOICE </dev/tty
    fi
fi

CHOICE="${INPUT_CHOICE:-Y}"

if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "\033[1;34m[*] 正在启动/重建 Aura Grid Pro 容器...\033[0m"
    
    # 智能匹配 compose 命令
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif docker-compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "\033[0;31m[!] 未检测到 docker compose 命令，请手动执行更新。\033[0m"
        exit 0
    fi

    # 执行更新
    if $COMPOSE_CMD up -d; then
        echo ""
        echo -e "\033[0;32m🎉 Aura Grid Pro 已成功更新并运行最新版本！\033[0m"
        
        # 新容器已启动，此时安全清理被淘汰的 <none> 旧镜像
        echo -e "\033[1;34m[*] 正在自动释放旧版本镜像空间...\033[0m"
        docker image prune -f >/dev/null 2>&1 || true
        echo -e "\033[0;32m✔ 系统空间已自动优化清理完毕！\033[0m"
    else
        echo -e "\033[0;31m[!] 容器启动遇到问题，请检查当前目录下的 docker-compose.yml。\033[0m"
    fi
else
    echo ""
    echo -e "\033[0;36m[已跳过自动更新]\033[0m 如需稍后手动启动新镜像，请在配置文件目录下运行："
    echo -e "   \033[1;37mdocker compose up -d\033[0m"
fi
