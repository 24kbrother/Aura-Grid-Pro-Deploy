#!/bin/bash
# =================================================================
# Aura Grid Pro 生产环境无损管道升级脚本
# =================================================================

# 1. 提取传入的 Token 参数
GH_TOKEN=$1

# 校验参数是否为空
if [ -z "$GH_TOKEN" ]; then
    echo -e "\033[0;31m❌ 错误：缺少必要的专属升级 Token，操作被拒绝。\033[0m"
    echo -e "\033[0;33m💡 请在前端面板重新获取升级指令，或联系作者索取有效 Token。\033[0m"
    exit 1
fi

echo "⚙️ 正在执行 Aura Grid Pro 高阶无损升级程序..."

# 固定私有仓库用户名
FIXED_USER="24kservice"

# 2. 尝试登录 GitHub 私有镜像仓库
echo "🔐 正在验证私有仓库拉取权限..."
if echo "$GH_TOKEN" | docker login ghcr.io -u "$FIXED_USER" --password-stdin &>/dev/null; then
    echo "✅ 权限鉴权成功，正在拉取最新镜像..."
else
    echo -e "\033[0;31m❌ 错误：Token 鉴权失败，该令牌可能已过期或无效！\033[0m"
    exit 1
fi

# 3. 拉取并重载容器
if docker compose pull && docker compose up -d --remove-orphans; then
    echo -e "\033[0;32m🎉 恭喜！Aura Grid Pro 生产镜像已成功就地升级！\033[0m"
else
    echo -e "\033[0;31m❌ 错误：容器编排或镜像拉取过程中断。\033[0m"
    exit 1
fi
