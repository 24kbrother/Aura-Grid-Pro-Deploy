#!/bin/bash
# =================================================================
# Aura Grid Pro 生产环境无损管道升级脚本
# =================================================================

GH_TOKEN=$1

# 1. 鉴权校验
if [ -z "$GH_TOKEN" ]; then
    echo -e "\033[0;31m[ERROR] 缺少必要的专属升级 Token，操作被拒绝。\033[0m"
    echo -e "\033[0;33m[TIP] 请在大屏前端面板点击“获取专属升级指令”以包含临时令牌。\033[0m"
    exit 1
fi

echo -e "\033[0;34m==============================================================\033[0m"
echo -e "\033[1;36m         欢迎使用 Aura Grid Pro VIP专属云端自动更新系统          \033[0m"
echo -e "\033[0;34m==============================================================\033[0m"

# 2. 交互告知与前置拦截
echo -e "\033[1;33m[重要提示]\033[0m"
echo -e "本程序将自动探测并拉取最新生产级 Golden Image。为保障数据安全："
echo -e "  1. 若您曾手动修改过 docker-compose 编排文件，升级可能会产生冲突。"
echo -e "  2. 强烈建议在执行更新前，前往大屏页面手动点击「导出全量工程备份」。"
echo -e ""
echo -e "\033[1;34m[VIP 售后与技术支持通道]\033[0m"
echo -e "  Email: 24k.brother@gmail.com"
echo -e "  WeChat: china_24kbro"
echo -e "\033[0;34m==============================================================\033[0m"

read -p "是否已做好备份并准备执行更新？(请输入 yes 继续): " CONFIRM </dev/tty
if [ "$CONFIRM" != "yes" ]; then
    echo -e "\033[0;31m[ABORT] 用户取消升级。请在安全备份后重新发起。\033[0m"
    exit 0
fi

# 2.5 临时网络代理加速（可选）
read -p "是否需要配置临时 HTTP 代理加速拉取？(直接回车跳过，若需要请输入如 http://127.0.0.1:7890 ): " PROXY_URL </dev/tty
if [ -n "$PROXY_URL" ]; then
    export http_proxy=$PROXY_URL
    export https_proxy=$PROXY_URL
    export HTTP_PROXY=$PROXY_URL
    export HTTPS_PROXY=$PROXY_URL
    echo -e "[INFO] 临时网络代理配置成功。"
fi

# 3. 授权身份防丢失保护 (HWID + JWT)
if [ -d "./data" ]; then
    [ -f "./data/device.id" ] && cp ./data/device.id ./device.id.bak
    [ -f "./data/license.jwt" ] && cp ./data/license.jwt ./license.jwt.bak
fi

# 4. 私有镜像鉴权
echo -e "\n\033[1;34m[*] 正在验证私有仓库拉取权限...\033[0m"
FIXED_USER="24kservice"
if echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null; then
    echo -e "\033[0;32m[+] 鉴权通过，成功接入云端仓库。\033[0m"
else
    echo -e "\033[0;31m[-] 鉴权失败：Token 无效或已过期，请重新获取。\033[0m"
    [ -f "./device.id.bak" ] && rm -f ./device.id.bak
    exit 1
fi

# 4.5 确保物理挂载目录存在 (解决群晖等系统 bind mount 失败问题)
echo -e "\033[1;34m[*] 正在检查物理目录完整性...\033[0m"
mkdir -p ./data ./floorplans ./icons
chmod -R 777 ./data ./floorplans ./icons 2>/dev/null || true

# 5. 自动探测并升级 docker-compose.yml 镜像标签
COMPOSE_FILE="docker-compose.yml"
if [ -f "$COMPOSE_FILE" ]; then
    if grep -q "ghcr.io/24kbrother/aura-grid-pro" "$COMPOSE_FILE"; then
        echo -e "\033[1;34m[*] 正在适配本地容器版本标识...\033[0m"
        sed -i.original -E 's|(image:[[:space:]]*ghcr\.io/24kbrother/aura-grid-pro):.*|\1:latest|g' "$COMPOSE_FILE"
    fi
fi

# 6. 执行镜像更新
if docker compose -p aura-grid-pro pull && docker compose -p aura-grid-pro up -d --remove-orphans; then
    echo -e "\n\033[0;32m[SUCCESS] Aura Grid Pro 生产镜像已顺利升级完成。\033[0m"
    
    # 7. 还原身份并销毁临时文件
    [ -f "./device.id.bak" ] && mv ./device.id.bak ./data/device.id
    [ -f "./license.jwt.bak" ] && mv ./license.jwt.bak ./data/license.jwt
    [ -f "${COMPOSE_FILE}.original" ] && rm -f "${COMPOSE_FILE}.original"
else
    echo -e "\033[0;31m[ERROR] 升级过程中断，正在为您紧急恢复身份保护层...\033[0m"
    [ -f "./device.id.bak" ] && mv ./device.id.bak ./data/device.id
    [ -f "./license.jwt.bak" ] && mv ./license.jwt.bak ./data/license.jwt
    exit 1
fi
