#!/bin/bash
echo "正在执行 Aura Grid Pro 无损升级..."
# 可选代理加速（直接回车跳过）
read -p "是否需要配置代理拉取镜像？(直接回车跳过，或输入如 http://127.0.0.1:7890): " PROXY_URL < /dev/tty
if [ -n "$PROXY_URL" ]; then
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    echo "✅ 代理已设置: $PROXY_URL"
fi
docker compose pull && docker compose up -d --remove-orphans
echo "✅ 更新完成！"
