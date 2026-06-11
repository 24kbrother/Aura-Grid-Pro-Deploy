#!/bin/bash
# =================================================================
#  Aura Grid Pro — Aliyun ACR Pull & Tag Alignment Tool
#  Usage: ./PULL_PRO_FORM_ALIYUN.sh
# =================================================================

ALIYUN_IMAGE="crpi-z60uur6y0xgl3fgs.cn-chengdu.personal.cr.aliyuncs.com/aura-grid/aura-grid-pro:latest"
GHCR_IMAGE="ghcr.io/24kbrother/aura-grid-pro:latest"

echo -e "\033[1;34m[*] 正在通过阿里云极速通道拉取最新 PRO 镜像...\033[0m"
if docker pull "$ALIYUN_IMAGE"; then
    echo -e "\033[1;34m[*] 正在本地对齐官方容器标识...\033[0m"
    if docker tag "$ALIYUN_IMAGE" "$GHCR_IMAGE"; then
        echo -e "\033[0;32m[SUCCESS] 镜像拉取并打标对齐成功！\033[0m"
        echo -e "🔹 原始镜像: $ALIYUN_IMAGE"
        echo -e "🔹 对齐镜像: $GHCR_IMAGE"
    else
        echo -e "\033[0;31m[ERROR] 镜像本地打标对齐失败。\033[0m"
        exit 1
    fi
else
    echo -e "\033[0;31m[ERROR] 从阿里云极速通道拉取镜像失败，请检查网络。\033[0m"
    exit 1
fi
