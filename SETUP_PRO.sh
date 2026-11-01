#!/bin/bash

# =================================================================
# Aura Grid Pro 旗舰版 — 生产环境一键多态部署与智能运维中枢
# 适用平台: Linux / macOS / Docker / 群晖 / 威联通 / 极空间 / 飞牛等 NAS
# 官方仓库: https://github.com/24kbrother/Aura-Grid-Pro-Deploy
# 官方网站: https://auragrid.cn
# 兼容标准: 100% POSIX sh / dash / bash 跨平台自适应
# 智能特性:
#   1. 权限自适应提权: 自动识别普通用户与 sudo 环境，无感适配
#   2. NAS 架构雷达探测: 自动推荐大容量存储池路径，杜绝系统小分区爆盘
#   3. 双轨雷达寻径: 无论在任意路径执行，均可秒级定位历史安装物理目录
#   4. 自感知无感升级: 发现已有 PRO 实例时，默认回车直接原地/穿透完成更新
#   5. 跨代无损升级: 自动嗅探 Lite 版并无损继承数据库、配置与硬件指纹 (HWID)
#   6. 双网络模式: 默认 Host 直通 (激活 mDNS 局域网毫秒级探活) 与 Bridge 隔离
# =================================================================

# 0. 自动 Shell 提升引擎 (当用户使用 sh 显式执行时，自动无缝升级至 bash)
if [ -z "$BASH_VERSION" ]; then
    if command -v bash >/dev/null 2>&1 && [ -f "$0" ]; then
        exec bash "$0" "$@"
    fi
fi

set -e

# 颜色与输出函数 (严格兼容 dash/sh 终端)
print_msg() {
    printf "%b\n" "$1"
}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_gemini_banner() {
    local edition="$1"
    local sub_info="$2"
    printf "\n"
    printf "%b\n" "  \033[38;2;64;182;248m█\033[38;2;69;179;248m█\033[38;2;73;176;248m█\033[38;2;78;173;248m█\033[38;2;82;170;248m█\033[38;2;87;167;248m╗\033[0m \033[38;2;96;161;248m█\033[38;2;100;158;248m█\033[38;2;105;155;248m╗\033[0m   \033[38;2;123;143;248m█\033[38;2;127;140;248m█\033[38;2;131;139;248m╗\033[38;2;135;139;248m█\033[38;2;139;138;248m█\033[38;2;143;138;248m█\033[38;2;147;137;249m█\033[38;2;151;137;249m█\033[38;2;155;136;249m█\033[38;2;159;136;249m╗\033[0m  \033[38;2;170;134;250m█\033[38;2;174;134;250m█\033[38;2;178;133;251m█\033[38;2;182;133;251m█\033[38;2;186;132;251m█\033[38;2;190;132;251m╗\033[0m      \033[38;2;212;124;224m█\033[38;2;216;123;219m█\033[38;2;219;122;215m█\033[38;2;222;121;211m█\033[38;2;225;120;206m█\033[38;2;228;119;202m█\033[38;2;232;118;198m╗\033[0m \033[38;2;238;115;189m█\033[38;2;241;114;185m█\033[38;2;244;113;181m█\033[38;2;244;113;178m█\033[38;2;244;113;175m█\033[38;2;245;113;172m█\033[38;2;245;113;169m╗\033[0m \033[38;2;246;113;163m█\033[38;2;247;113;160m█\033[38;2;247;113;157m╗\033[38;2;247;113;154m█\033[38;2;248;113;151m█\033[38;2;248;113;148m█\033[38;2;249;113;145m█\033[38;2;249;113;142m█\033[38;2;250;113;139m█\033[38;2;250;113;136m╗\033[0m "
    printf "%b\n" " \033[38;2;60;185;248m█\033[38;2;64;182;248m█\033[38;2;69;179;248m╔\033[38;2;73;176;248m═\033[38;2;78;173;248m═\033[38;2;82;170;248m█\033[38;2;87;167;248m█\033[38;2;91;164;248m╗\033[38;2;96;161;248m█\033[38;2;100;158;248m█\033[38;2;105;155;248m║\033[0m   \033[38;2;123;143;248m█\033[38;2;127;140;248m█\033[38;2;131;139;248m║\033[38;2;135;139;248m█\033[38;2;139;138;248m█\033[38;2;143;138;248m╔\033[38;2;147;137;249m═\033[38;2;151;137;249m═\033[38;2;155;136;249m█\033[38;2;159;136;249m█\033[38;2;162;135;250m╗\033[38;2;166;135;250m█\033[38;2;170;134;250m█\033[38;2;174;134;250m╔\033[38;2;178;133;251m═\033[38;2;182;133;251m═\033[38;2;186;132;251m█\033[38;2;190;132;251m█\033[38;2;193;131;249m╗\033[0m    \033[38;2;209;125;228m█\033[38;2;212;124;224m█\033[38;2;216;123;219m╔\033[38;2;219;122;215m═\033[38;2;222;121;211m═\033[38;2;225;120;206m═\033[38;2;228;119;202m═\033[38;2;232;118;198m╝\033[0m \033[38;2;238;115;189m█\033[38;2;241;114;185m█\033[38;2;244;113;181m╔\033[38;2;244;113;178m═\033[38;2;244;113;175m═\033[38;2;245;113;172m█\033[38;2;245;113;169m█\033[38;2;246;113;166m╗\033[38;2;246;113;163m█\033[38;2;247;113;160m█\033[38;2;247;113;157m║\033[38;2;247;113;154m█\033[38;2;248;113;151m█\033[38;2;248;113;148m╔\033[38;2;249;113;145m═\033[38;2;249;113;142m═\033[38;2;250;113;139m█\033[38;2;250;113;136m█\033[38;2;251;113;133m╗\033[0m"
    printf "%b\n" " \033[38;2;60;185;248m█\033[38;2;64;182;248m█\033[38;2;69;179;248m█\033[38;2;73;176;248m█\033[38;2;78;173;248m█\033[38;2;82;170;248m█\033[38;2;87;167;248m█\033[38;2;91;164;248m║\033[38;2;96;161;248m█\033[38;2;100;158;248m█\033[38;2;105;155;248m║\033[0m   \033[38;2;123;143;248m█\033[38;2;127;140;248m█\033[38;2;131;139;248m║\033[38;2;135;139;248m█\033[38;2;139;138;248m█\033[38;2;143;138;248m█\033[38;2;147;137;249m█\033[38;2;151;137;249m█\033[38;2;155;136;249m█\033[38;2;159;136;249m╔\033[38;2;162;135;250m╝\033[38;2;166;135;250m█\033[38;2;170;134;250m█\033[38;2;174;134;250m█\033[38;2;178;133;251m█\033[38;2;182;133;251m█\033[38;2;186;132;251m█\033[38;2;190;132;251m█\033[38;2;193;131;249m║\033[0m    \033[38;2;209;125;228m█\033[38;2;212;124;224m█\033[38;2;216;123;219m║\033[0m  \033[38;2;225;120;206m█\033[38;2;228;119;202m█\033[38;2;232;118;198m█\033[38;2;235;117;193m╗\033[38;2;238;115;189m█\033[38;2;241;114;185m█\033[38;2;244;113;181m█\033[38;2;244;113;178m█\033[38;2;244;113;175m█\033[38;2;245;113;172m█\033[38;2;245;113;169m╔\033[38;2;246;113;166m╝\033[38;2;246;113;163m█\033[38;2;247;113;160m█\033[38;2;247;113;157m║\033[38;2;247;113;154m█\033[38;2;248;113;151m█\033[38;2;248;113;148m║\033[0m  \033[38;2;250;113;139m█\033[38;2;250;113;136m█\033[38;2;251;113;133m║\033[0m"
    printf "%b\n" " \033[38;2;60;185;248m█\033[38;2;64;182;248m█\033[38;2;69;179;248m╔\033[38;2;73;176;248m═\033[38;2;78;173;248m═\033[38;2;82;170;248m█\033[38;2;87;167;248m█\033[38;2;91;164;248m║\033[38;2;96;161;248m█\033[38;2;100;158;248m█\033[38;2;105;155;248m║\033[0m   \033[38;2;123;143;248m█\033[38;2;127;140;248m█\033[38;2;131;139;248m║\033[38;2;135;139;248m█\033[38;2;139;138;248m█\033[38;2;143;138;248m╔\033[38;2;147;137;249m═\033[38;2;151;137;249m═\033[38;2;155;136;249m█\033[38;2;159;136;249m█\033[38;2;162;135;250m╗\033[38;2;166;135;250m█\033[38;2;170;134;250m█\033[38;2;174;134;250m╔\033[38;2;178;133;251m═\033[38;2;182;133;251m═\033[38;2;186;132;251m█\033[38;2;190;132;251m█\033[38;2;193;131;249m║\033[0m    \033[38;2;209;125;228m█\033[38;2;212;124;224m█\033[38;2;216;123;219m║\033[0m   \033[38;2;228;119;202m█\033[38;2;232;118;198m█\033[38;2;235;117;193m║\033[38;2;238;115;189m█\033[38;2;241;114;185m█\033[38;2;244;113;181m╔\033[38;2;244;113;178m═\033[38;2;244;113;175m═\033[38;2;245;113;172m█\033[38;2;245;113;169m█\033[38;2;246;113;166m╗\033[38;2;246;113;163m█\033[38;2;247;113;160m█\033[38;2;247;113;157m║\033[38;2;247;113;154m█\033[38;2;248;113;151m█\033[38;2;248;113;148m║\033[0m  \033[38;2;250;113;139m█\033[38;2;250;113;136m█\033[38;2;251;113;133m║\033[0m"
    printf "%b\n" " \033[38;2;60;185;248m█\033[38;2;64;182;248m█\033[38;2;69;179;248m║\033[0m  \033[38;2;82;170;248m█\033[38;2;87;167;248m█\033[38;2;91;164;248m║\033[38;2;96;161;248m╚\033[38;2;100;158;248m█\033[38;2;105;155;248m█\033[38;2;109;152;248m█\033[38;2;114;149;248m█\033[38;2;118;146;248m█\033[38;2;123;143;248m█\033[38;2;127;140;248m╔\033[38;2;131;139;248m╝\033[38;2;135;139;248m█\033[38;2;139;138;248m█\033[38;2;143;138;248m║\033[0m  \033[38;2;155;136;249m█\033[38;2;159;136;249m█\033[38;2;162;135;250m║\033[38;2;166;135;250m█\033[38;2;170;134;250m█\033[38;2;174;134;250m║\033[0m  \033[38;2;186;132;251m█\033[38;2;190;132;251m█\033[38;2;193;131;249m║\033[0m    \033[38;2;209;125;228m╚\033[38;2;212;124;224m█\033[38;2;216;123;219m█\033[38;2;219;122;215m█\033[38;2;222;121;211m█\033[38;2;225;120;206m█\033[38;2;228;119;202m█\033[38;2;232;118;198m╔\033[38;2;235;117;193m╝\033[38;2;238;115;189m█\033[38;2;241;114;185m█\033[38;2;244;113;181m║\033[0m  \033[38;2;245;113;172m█\033[38;2;245;113;169m█\033[38;2;246;113;166m║\033[38;2;246;113;163m█\033[38;2;247;113;160m█\033[38;2;247;113;157m║\033[38;2;247;113;154m█\033[38;2;248;113;151m█\033[38;2;248;113;148m█\033[38;2;249;113;145m█\033[38;2;249;113;142m█\033[38;2;250;113;139m█\033[38;2;250;113;136m╔\033[38;2;251;113;133m╝\033[0m"
    printf "%b\n" " \033[38;2;60;185;248m╚\033[38;2;64;182;248m═\033[38;2;69;179;248m╝\033[0m  \033[38;2;82;170;248m╚\033[38;2;87;167;248m═\033[38;2;91;164;248m╝\033[0m \033[38;2;100;158;248m╚\033[38;2;105;155;248m═\033[38;2;109;152;248m═\033[38;2;114;149;248m═\033[38;2;118;146;248m═\033[38;2;123;143;248m═\033[38;2;127;140;248m╝\033[0m \033[38;2;135;139;248m╚\033[38;2;139;138;248m═\033[38;2;143;138;248m╝\033[0m  \033[38;2;155;136;249m╚\033[38;2;159;136;249m═\033[38;2;162;135;250m╝\033[38;2;166;135;250m╚\033[38;2;170;134;250m═\033[38;2;174;134;250m╝\033[0m  \033[38;2;186;132;251m╚\033[38;2;190;132;251m═\033[38;2;193;131;249m╝\033[0m     \033[38;2;212;124;224m╚\033[38;2;216;123;219m═\033[38;2;219;122;215m═\033[38;2;222;121;211m═\033[38;2;225;120;206m═\033[38;2;228;119;202m═\033[38;2;232;118;198m╝\033[0m \033[38;2;238;115;189m╚\033[38;2;241;114;185m═\033[38;2;244;113;181m╝\033[0m  \033[38;2;245;113;172m╚\033[38;2;245;113;169m═\033[38;2;246;113;166m╝\033[38;2;246;113;163m╚\033[38;2;247;113;160m═\033[38;2;247;113;157m╝\033[38;2;247;113;154m╚\033[38;2;248;113;151m═\033[38;2;248;113;148m═\033[38;2;249;113;145m═\033[38;2;249;113;142m═\033[38;2;250;113;139m═\033[38;2;250;113;136m╝\033[0m "
    printf "%b\n" "\033[38;2;71;85;105m──────────────────────────────────────────────────────────────────\033[0m"
    printf "%b\n" " ${edition}"
    printf "%b\n" " ${sub_info}"
    printf "%b\n" "\033[38;2;71;85;105m──────────────────────────────────────────────────────────────────\033[0m"
    printf "\n"
}

# 镜像地址定义
ALIYUN_IMAGE="crpi-z60uur6y0xgl3fgs.cn-chengdu.personal.cr.aliyuncs.com/aura-grid/aura-grid-pro:latest"
GHCR_IMAGE="ghcr.io/24kbrother/aura-grid-pro:latest"

# 终端输入兼容函数 (自适应交互终端、管道模式与非交互自动化环境)
ask_user() {
    local prompt="$1"
    local default_val="$2"
    local val=""
    if [ -t 0 ]; then
        read -p "$prompt" val || true
    elif (exec </dev/tty) 2>/dev/null; then
        read -p "$prompt" val </dev/tty 2>/dev/null || true
    else
        read val 2>/dev/null || true
    fi
    echo "${val:-$default_val}"
}

# 智能探测主流 NAS 存储架构与推荐安全安装目录 (防系统盘爆满)
detect_recommended_dir() {
    local app_name="$1"
    
    # 1. 群晖 Synology DSM (/volume1/docker 等大容量存储池)
    for v in /volume1 /volume2 /volume3 /volume4; do
        if [ -d "$v/docker" ]; then
            echo "$v/docker/$app_name"; return
        elif [ -d "$v" ]; then
            echo "$v/$app_name"; return
        fi
    done

    # 2. 飞牛 fnOS (基于 Debian，存储池在 /vol1, /vol2 等)
    for v in /vol1 /vol2 /vol3 /vol4; do
        if [ -d "$v/docker" ]; then
            echo "$v/docker/$app_name"; return
        elif [ -d "$v" ]; then
            echo "$v/$app_name"; return
        fi
    done

    # 3. 威联通 QNAP (/share/Container 等)
    for s in /share/Container /share/CACHEDEV1_DATA/Container /share/CACHEDEV2_DATA/Container; do
        if [ -d "$s" ]; then
            echo "$s/$app_name"; return
        fi
    done

    # 4. 绿联 UGOS / UGOS Pro (/mnt/media_rw, /mnt/storage 等)
    for m in /mnt/storage* /mnt/media_rw*; do
        if [ -d "$m/docker" ]; then
            echo "$m/docker/$app_name"; return
        elif [ -d "$m" ]; then
            echo "$m/$app_name"; return
        fi
    done

    # 5. Linux 通用最佳实践目录 (/opt)
    if [ -d "/opt" ]; then
        echo "/opt/$app_name"; return
    fi

    # 6. 回退兜底：当前用户执行目录下的子目录
    echo "$(pwd)/$app_name"
}

print_gemini_banner "\033[38;2;56;189;248m\033[1mAURA GRID PRO\033[0m \033[38;2;148;163;184m·\033[0m \033[38;2;226;232;240m智慧空间全屋数字孪生控制中枢\033[0m \033[38;2;148;163;184m·\033[0m \033[38;2;244;114;182m[ 旗舰商业版 ]\033[0m" "\033[38;2;148;163;184m官方主站:\033[0m \033[38;2;56;189;248mhttps://auragrid.cn\033[0m \033[38;2;100;116;139m|\033[0m \033[38;2;148;163;184m文档中心:\033[0m \033[38;2;192;132;252mhttps://auragrid.cn/docs/\033[0m"
print_msg " [INFO] 包含全量空间孪生微件、多楼层无级流转、APNs 勿扰强推与安全保险库。"
print_msg " 官方技术支持与授权服务: WeChat: china_24kbro | Email: 24k.brother@gmail.com"
print_msg "\033[38;2;71;85;105m──────────────────────────────────────────────────────────────────\033[0m\n"

# 1. 权限自适应探测与智能提权引擎 (严格兼容普通非 root 用户与 NAS 环境)
DOCKER_CMD="docker"
CURRENT_UID=$(id -u 2>/dev/null || echo 0)

if [ "$CURRENT_UID" -ne 0 ]; then
    if docker ps >/dev/null 2>&1; then
        DOCKER_CMD="docker"
    elif command -v sudo >/dev/null 2>&1; then
        DOCKER_CMD="sudo docker"
        if ! sudo -n true 2>/dev/null; then
            print_msg "${YELLOW}[!] 当前普通用户执行 Docker 需要管理员授权，请输入 sudo 密码:${NC}"
            sudo -v || {
                print_msg "${RED}[ERROR] sudo 认证失败，请确认密码。${NC}"
                exit 1
            }
        fi
    else
        print_msg "${RED}==================================================================${NC}"
        print_msg "${RED}[ERROR] 权限不足：当前用户 [$(whoami)] 没有操作 Docker 的权限。${NC}"
        print_msg "${RED}==================================================================${NC}"
        print_msg " 排查与建议:"
        print_msg "  1. 请切换至 root 账户后重试: sudo -i"
        print_msg "  2. 或将当前用户加入 docker 组: sudo usermod -aG docker $(whoami)"
        print_msg "${RED}==================================================================${NC}\n"
        exit 1
    fi
fi

if ! command -v docker >/dev/null 2>&1 && ! command -v sudo >/dev/null 2>&1; then
    print_msg "${RED}[ERROR] 未检测到 Docker 环境，请先安装 Docker。${NC}"
    exit 1
fi

COMPOSE_CMD="$DOCKER_CMD compose"
if ! $DOCKER_CMD compose version >/dev/null 2>&1; then
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        print_msg "${RED}[ERROR] 未检测到 docker compose 核心组件，请先安装 Docker Compose。${NC}"
        exit 1
    fi
fi

# 2. 双轨雷达环境探测：首先嗅探宿主机现有 PRO 实例
EXISTING_PRO_DIR=""
EXISTING_PRO_CONTAINER=$($DOCKER_CMD ps -a -q -f name=^aura-grid-pro$ 2>/dev/null || true)

if [ -n "$EXISTING_PRO_CONTAINER" ]; then
    # 轨 A: Compose 物理工作区 Label
    LABEL_DIR=$($DOCKER_CMD inspect -f '{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$EXISTING_PRO_CONTAINER" 2>/dev/null || true)
    if [ -n "$LABEL_DIR" ] && [ -d "$LABEL_DIR" ]; then
        EXISTING_PRO_DIR="$LABEL_DIR"
    fi

    # 轨 B: 挂载点物理路径反推
    if [ -z "$EXISTING_PRO_DIR" ]; then
        MOUNT_SRC=$($DOCKER_CMD inspect --format='{{range .Mounts}}{{if eq .Destination "/app/data"}}{{.Source}}{{end}}{{end}}' "$EXISTING_PRO_CONTAINER" 2>/dev/null || true)
        if [ -z "$MOUNT_SRC" ]; then
            MOUNT_SRC=$($DOCKER_CMD inspect --format='{{range .Mounts}}{{if eq .Destination "/app/prisma/data"}}{{.Source}}{{end}}{{end}}' "$EXISTING_PRO_CONTAINER" 2>/dev/null || true)
        fi
        if [ -n "$MOUNT_SRC" ]; then
            CANDIDATE_DIR=$(dirname "$MOUNT_SRC")
            if [ -d "$CANDIDATE_DIR" ]; then
                EXISTING_PRO_DIR="$CANDIDATE_DIR"
            fi
        fi
    fi
fi

# 轨 C: 当前目录自查
if [ -z "$EXISTING_PRO_DIR" ] && [ -f "./docker-compose.yml" ]; then
    if grep -q 'aura-grid-pro:' ./docker-compose.yml 2>/dev/null; then
        EXISTING_PRO_DIR=$(pwd)
    fi
fi

# 双重校验：检查物理编排文件 docker-compose.yml 是否真实存在
IS_VALID_EXISTING_PRO=false
if [ -n "$EXISTING_PRO_DIR" ] && [ -d "$EXISTING_PRO_DIR" ] && [ -f "$EXISTING_PRO_DIR/docker-compose.yml" ]; then
    IS_VALID_EXISTING_PRO=true
elif [ -n "$EXISTING_PRO_CONTAINER" ]; then
    # 存在孤儿残留容器，但物理目录或 docker-compose.yml 已丢失
    print_msg "${YELLOW}[!] 雷达检测到宿主机存在残留的旧容器 aura-grid-pro，但物理编排文件已丢失或被移除。${NC}"
    print_msg "${BLUE}[*] 正在自动清理该残留容器，以确保全新部署环境整洁...${NC}"
    $DOCKER_CMD rm -f aura-grid-pro aura-redis-pro >/dev/null 2>&1 || true
    EXISTING_PRO_DIR=""
fi

# 3. 智能分流与 PRO 任意目录自感知无缝升级
if [ "$IS_VALID_EXISTING_PRO" = "true" ]; then
    PRO_STATUS=$($DOCKER_CMD inspect -f '{{.State.Status}}' "$EXISTING_PRO_CONTAINER" 2>/dev/null || echo "running")
    print_msg "${GREEN}[+] 雷达探测到宿主机已部署 Aura Grid Pro 实例！${NC}"
    print_msg "  • 物理安装目录: ${BLUE}${EXISTING_PRO_DIR}${NC}"
    print_msg "  • 容器当前状态: ${CYAN}${PRO_STATUS}${NC}"
    print_msg " ------------------------------------------------------------------"
    print_msg " 请选择执行操作:"
    print_msg "  ${CYAN}[1] 一键极速平滑更新至最新版本${NC} (推荐: 自动穿透至原目录，保留原配置、授权与全部数据) [默认]"
    print_msg "  ${CYAN}[2] 在当前路径全新安装一个新实例${NC} (重新生成编排与全新初始化)"
    print_msg "  ${CYAN}[3] 退出操作${NC}"
    print_msg " ------------------------------------------------------------------"
    ACTION_CHOICE=$(ask_user "请输入选项 [1/2/3] (直接回车默认: 1): " "1")

    if [ "$ACTION_CHOICE" = "1" ]; then
        print_msg "\n${BLUE}[*] 正在自动穿透至安装目录: ${EXISTING_PRO_DIR}${NC}"
        cd "$EXISTING_PRO_DIR"

        # 保护性备份指纹与授权凭证
        if [ -d "./data" ]; then
            [ -f "./data/device.id" ] && cp ./data/device.id ./data/device.id.bak 2>/dev/null || true
            [ -f "./data/license.jwt" ] && cp ./data/license.jwt ./data/license.jwt.bak 2>/dev/null || true
        fi

        # 极速拉取并打标
        UPDATE_SUCCESS=false
        print_msg "${BLUE}[*] 默认启用阿里云国内极速通道拉取最新 PRO 镜像...${NC}"
        if $DOCKER_CMD pull "$ALIYUN_IMAGE"; then
            print_msg "${BLUE}[*] 正在本地对齐官方容器标识...${NC}"
            $DOCKER_CMD tag "$ALIYUN_IMAGE" "$GHCR_IMAGE"
            $DOCKER_CMD rmi "$ALIYUN_IMAGE" >/dev/null 2>&1 || true
            UPDATE_SUCCESS=true
        else
            print_msg "${YELLOW}[WARNING] 阿里云通道拉取遇到网络波动，正在尝试官方 GitHub 链路...${NC}"
            if $COMPOSE_CMD pull; then
                UPDATE_SUCCESS=true
            fi
        fi

        if [ "$UPDATE_SUCCESS" != "true" ]; then
            print_msg "${RED}[ERROR] 镜像拉取失败，请检查网络连接后重试。${NC}"
            exit 1
        fi

        print_msg "${BLUE}[*] 正在平滑更新重启容器 (保留您的历史配置、授权与全部数据)...${NC}"
        if $COMPOSE_CMD up -d; then
            print_msg "\n${GREEN}[SUCCESS] Aura Grid Pro 已成功更新并运行最新版本！${NC}"
            
            # 安全释放旧镜像
            print_msg "${BLUE}[*] 正在自动清理被替换的旧版本镜像...${NC}"
            $DOCKER_CMD image prune -f >/dev/null 2>&1 || true
            print_msg "${GREEN}[SUCCESS] 磁盘空间已自动优化清理完毕！${NC}"

            IP_ADDR=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
            if [ -z "$IP_ADDR" ]; then
                IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
            fi
            [ -z "$IP_ADDR" ] && IP_ADDR="127.0.0.1"

            print_msg "\n${GREEN}==================================================${NC}"
            print_msg " 访问入口: ${BLUE}http://${IP_ADDR}:8125${NC}"
            print_msg " 工作目录: ${BLUE}${EXISTING_PRO_DIR}${NC}"
            print_msg "${GREEN}==================================================${NC}\n"
            exit 0
        else
            print_msg "${RED}[ERROR] 容器重启失败，请检查 ${EXISTING_PRO_DIR}/docker-compose.yml。${NC}"
            exit 1
        fi
    elif [ "$ACTION_CHOICE" = "3" ]; then
        print_msg "${GREEN}[INFO] 已安全退出。${NC}\n"
        exit 0
    else
        print_msg "${YELLOW}[*] 用户选择重新安装流程，继续初始化向导...${NC}\n"
    fi
fi

# 4. 全新安装流程：Step 1 镜像下载源选择
print_msg "${YELLOW}[1/2] 请选择镜像下载通道 (Download Mirror):${NC}"
print_msg "  ${CYAN}[1] 阿里云国内极速通道${NC} (推荐: 国内服务器、极空间/群晖/飞牛等 NAS 环境) [默认]"
print_msg "  ${CYAN}[2] GitHub 官方通道${NC} (推荐: 海外 VPS、已配置代理环境)"
print_msg " ------------------------------------------------------------------"
MIRROR_CHOICE=$(ask_user "请输入选项 [1/2] (直接回车默认: 1): " "1")

if [ "$MIRROR_CHOICE" != "2" ]; then
    MIRROR_CHOICE="1"
    print_msg "${GREEN}[+] 已选择: 阿里云国内极速通道${NC}\n"
else
    print_msg "${GREEN}[+] 已选择: GitHub 官方通道${NC}\n"
fi

# 5. 全新安装流程：Step 2 网络运行模式选择
print_msg "${YELLOW}[2/2] 请选择网络运行模式 (Network Mode):${NC}"
print_msg "  ${CYAN}[1] Host 宿主直通模式${NC} (推荐: 开启 mDNS 毫秒级探活，手机 App 免配置秒连) [默认]"
print_msg "  ${CYAN}[2] Bridge 桥接隔离模式${NC} (传统端口映射 8125，隔离度高；手机端需手动输入 IP)"
print_msg " ------------------------------------------------------------------"
NET_CHOICE=$(ask_user "请输入选项 [1/2] (直接回车默认: 1): " "1")

if [ "$NET_CHOICE" != "2" ]; then
    NET_CHOICE="1"
    print_msg "${GREEN}[+] 已选择: Host 宿主直通模式 (mDNS 局域网探活已激活)${NC}\n"
else
    print_msg "${GREEN}[+] 已选择: Bridge 桥接隔离模式${NC}\n"
fi

# 6. 状态嗅探与环境动态决策 (跨代 Lite 无损升级 vs 全新首装目录规划)
print_msg "${BLUE}[*] 正在进行系统环境拓扑扫描...${NC}"

LITE_CONTAINER=$($DOCKER_CMD ps -a -q -f name=^aura-grid$ 2>/dev/null || true)
LITE_DIR=""

if [ -n "$LITE_CONTAINER" ]; then
    LITE_PHYSICAL_PATH=$($DOCKER_CMD inspect --format='{{range .Mounts}}{{if eq .Destination "/app/data"}}{{.Source}}{{end}}{{end}}' "$LITE_CONTAINER" 2>/dev/null || true)
    if [ -n "$LITE_PHYSICAL_PATH" ]; then
        LITE_DIR=$(dirname "$LITE_PHYSICAL_PATH")
    fi
fi

if [ -z "$LITE_DIR" ] && [ -f "./docker-compose.yml" ]; then
    if grep -q 'aura-grid:' ./docker-compose.yml 2>/dev/null; then
        LITE_DIR=$(pwd)
    fi
fi

if [ -n "$LITE_DIR" ] && [ -d "$LITE_DIR" ]; then
    print_msg "\n+------------------------------------------------------+"
    print_msg "|        检测到 AURA-LITE 版历史安装环境               |"
    print_msg "+------------------------------------------------------+"
    print_msg " 已锁定历史物理目录: ${BLUE}${LITE_DIR}${NC}"
    print_msg " 即将执行 [一键安全跨代无损升级]:"
    print_msg "  - 自动迁移历史全量数据库、空间户型图和自定义图标"
    print_msg "  - 硬件指纹 (HWID) 严格继承，杜绝授权安全保护期冲突\n"

    cd "$LITE_DIR"
    WORKDIR=$(pwd)

    print_msg "${YELLOW}[*] 正在停止并解耦 LITE 旧容器...${NC}"
    $DOCKER_CMD stop aura-grid aura-redis >/dev/null 2>&1 || true
    $DOCKER_CMD rm   aura-grid aura-redis >/dev/null 2>&1 || true

    if $DOCKER_CMD volume inspect aura-db-data >/dev/null 2>&1; then
        print_msg "${YELLOW}[*] 正在为历史数据库建立提取迁移...${NC}"
        mkdir -p ./data
        $DOCKER_CMD run --rm \
            -v aura-db-data:/source \
            -v "$(pwd)/data":/dest \
            alpine sh -c "cp -f /source/prod.db /dest/prod.db 2>/dev/null || true" >/dev/null 2>&1 || true
    fi
else
    # 【全新首装模式 - 智能 NAS 存储路径推荐与决策】
    REC_DIR=$(detect_recommended_dir "aura-pro")
    CURRENT_DEFAULT="$(pwd)/aura-pro"

    # 若推荐的大存储池路径与当前路径不同，提供智能选择
    if [ "$REC_DIR" != "$CURRENT_DEFAULT" ] && [ -d "$(dirname "$REC_DIR")" ]; then
        print_msg "${BLUE}[*] 正在扫描宿主机存储架构与大容量磁盘...${NC}"
        print_msg "${GREEN}[+] 推荐数据存储池: ${CYAN}${REC_DIR}${NC} (大容量安全分区，防系统盘爆满)"
        print_msg " ------------------------------------------------------------------"
        print_msg " 请确认服务部署物理路径:"
        print_msg "  ${CYAN}[1] 使用系统推荐路径: ${REC_DIR}${NC} [默认推荐]"
        print_msg "  ${CYAN}[2] 部署在当前目录下: ${CURRENT_DEFAULT}${NC}"
        print_msg "  ${CYAN}[3] 自定义输入其他绝对路径${NC}"
        print_msg " ------------------------------------------------------------------"
        PATH_CHOICE=$(ask_user "请输入选项 [1/2/3] (直接回车默认: 1): " "1")

        if [ "$PATH_CHOICE" = "2" ]; then
            WORKDIR="$CURRENT_DEFAULT"
        elif [ "$PATH_CHOICE" = "3" ]; then
            CUSTOM_INPUT=$(ask_user "请输入您指定的绝对路径 (例如 /data/aura-pro): " "")
            if [ -n "$CUSTOM_INPUT" ]; then
                WORKDIR="$CUSTOM_INPUT"
            else
                WORKDIR="$REC_DIR"
            fi
        else
            WORKDIR="$REC_DIR"
        fi
    else
        WORKDIR="$CURRENT_DEFAULT"
    fi

    mkdir -p "$WORKDIR" 2>/dev/null || sudo mkdir -p "$WORKDIR"
    cd "$WORKDIR"
    print_msg "${GREEN}[+] 当前为 [PRO 专属正版全新首装] 模式${NC}"
    print_msg " 服务物理安装路径: ${BLUE}${WORKDIR}${NC}"
fi

# 7. 初始化目录结构与硬件指纹 (HWID)
mkdir -p "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons" 2>/dev/null || sudo mkdir -p "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons"
chmod -R 777 "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons" 2>/dev/null || sudo chmod -R 777 "$WORKDIR/data" "$WORKDIR/floorplans" "$WORKDIR/icons"

HWID_FILE="$WORKDIR/data/device.id"
if [ -d "$HWID_FILE" ]; then
    rm -rf "$HWID_FILE" 2>/dev/null || sudo rm -rf "$HWID_FILE"
fi

if [ -f "$HWID_FILE" ]; then
    EXISTING_HWID=$(cat "$HWID_FILE")
    print_msg "${GREEN}[+] 检测到已有硬件指纹: ${EXISTING_HWID}${NC}"
else
    if [ -f /proc/sys/kernel/random/uuid ]; then
        NEW_HWID=$(cat /proc/sys/kernel/random/uuid)
    elif command -v uuidgen >/dev/null 2>&1; then
        NEW_HWID=$(uuidgen)
    else
        NEW_HWID="aura-pro-$(od -x /dev/urandom 2>/dev/null | head -n 1 | awk '{print $2$3$4$5}' || date +%s)"
    fi
    echo "$NEW_HWID" > "$HWID_FILE"
    print_msg "${GREEN}[+] 已生成全新硬件指纹: ${NEW_HWID}${NC}"
fi

# 8. 根据网络模式动态生成 PRO 统一 Docker Compose 编排文件
print_msg "${BLUE}[*] 正在生成 Docker Compose 编排文件...${NC}"

if [ "$NET_CHOICE" = "1" ]; then
    # 【模式 1】Host 直通模式 (推荐: mDNS 毫秒级广播探活 + 127.0.0.1 Redis 保护)
    cat <<EOF > "$WORKDIR/docker-compose.yml"
services:
  redis:
    image: redis:7-alpine
    container_name: aura-redis-pro
    restart: unless-stopped
    volumes:
      - redis_pro_data:/data
    command: redis-server --save 60 1 --loglevel warning
    ports:
      - "127.0.0.1:6379:6379"
    networks:
      - aura-pro-internal

  aura-grid:
    image: ${GHCR_IMAGE}
    container_name: aura-grid-pro
    restart: unless-stopped
    network_mode: host
    environment:
      - NODE_ENV=production
      - PORT=8125
      - REDIS_URL=redis://127.0.0.1:6379
      - DATABASE_URL=file:/app/prisma/data/prod.db
      - FLOORPLANS_DIR=/app/floorplans
    volumes:
      - ./data:/app/prisma/data
      - ./floorplans:/app/floorplans
      - ./icons:/app/icons
      - ./data/device.id:/etc/machine-id:ro
    depends_on:
      - redis

networks:
  aura-pro-internal:
    driver: bridge

volumes:
  redis_pro_data:
    name: aura-redis-pro-data
EOF
else
    # 【模式 2】Bridge 桥接模式 (传统隔离，8125 端口映射)
    cat <<EOF > "$WORKDIR/docker-compose.yml"
services:
  redis:
    image: redis:7-alpine
    container_name: aura-redis-pro
    restart: unless-stopped
    volumes:
      - redis_pro_data:/data
    command: redis-server --save 60 1 --loglevel warning
    networks:
      - aura-pro-internal

  aura-grid:
    image: ${GHCR_IMAGE}
    container_name: aura-grid-pro
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - PORT=8500
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=file:/app/prisma/data/prod.db
      - FLOORPLANS_DIR=/app/floorplans
    ports:
      - "8125:8500"
    volumes:
      - ./data:/app/prisma/data
      - ./floorplans:/app/floorplans
      - ./icons:/app/icons
      - ./data/device.id:/etc/machine-id:ro
    networks:
      - aura-pro-internal
    depends_on:
      - redis

networks:
  aura-pro-internal:
    driver: bridge

volumes:
  redis_pro_data:
    name: aura-redis-pro-data
EOF
fi

# 9. 执行镜像拉取并打标对齐
print_msg "\n${BLUE}[*] 正在拉取最新的 PRO 镜像...${NC}"

# 安全清理历史同名旧容器
$DOCKER_CMD rm -f aura-grid-pro aura-redis-pro >/dev/null 2>&1 || true

PULL_SUCCESS=false

if [ "$MIRROR_CHOICE" = "1" ]; then
    print_msg "${BLUE}[*] 正在通过阿里云国内极速通道拉取最新镜像...${NC}"
    if $DOCKER_CMD pull "$ALIYUN_IMAGE"; then
        print_msg "${BLUE}[*] 正在本地对齐官方标准容器标识...${NC}"
        $DOCKER_CMD tag "$ALIYUN_IMAGE" "$GHCR_IMAGE"
        $DOCKER_CMD rmi "$ALIYUN_IMAGE" >/dev/null 2>&1 || true
        PULL_SUCCESS=true
    else
        print_msg "${YELLOW}[WARNING] 阿里云通道拉取遇到网络波动，正在自动降级为官方 GitHub 链路...${NC}"
    fi
fi

if [ "$PULL_SUCCESS" = "false" ]; then
    print_msg "${BLUE}[*] 正在通过官方 GitHub 镜像源拉取...${NC}"
    if ! $COMPOSE_CMD pull; then
        print_msg "${RED}[ERROR] 镜像拉取失败，请检查网络环境或代理配置。${NC}"
        exit 1
    fi
fi

# 10. 启动服务与状态自检
print_msg "${BLUE}[*] 正在启动 Aura Grid Pro 服务组...${NC}"
if ! $COMPOSE_CMD up -d; then
    print_msg "\n${RED}==================================================${NC}"
    print_msg "[ERROR] 容器启动失败！"
    print_msg "可能原因: 端口 8125 或 6379 已被宿主机其他服务占用。"
    print_msg "排查建议: 执行 'netstat -tunlp | grep 8125' 检查端口占用。"
    print_msg "${RED}==================================================${NC}"
    exit 1
fi

sleep 2
if [ "$($DOCKER_CMD inspect -f '{{.State.Running}}' aura-grid-pro 2>/dev/null)" != "true" ]; then
    print_msg "${RED}[WARNING] 容器创建后未能持续运行，请执行 '$DOCKER_CMD logs aura-grid-pro' 查看详细日志。${NC}"
    exit 1
fi

# 11. 在当前目录就地生成本地专属更新脚本 UPDATE_PRO.sh
cat <<'EOF' > "$WORKDIR/UPDATE_PRO.sh"
#!/bin/bash
# =================================================================
# Aura Grid Pro — 本地专属一键无损更新工具
# 国内网络环境强烈推荐使用本脚本更新，秒级拉取极速完成
# =================================================================

# 自动 Shell 提升
if [ -z "$BASH_VERSION" ]; then
    if command -v bash >/dev/null 2>&1 && [ -f "$0" ]; then
        exec bash "$0" "$@"
    fi
fi

set -e

ALIYUN_IMAGE="crpi-z60uur6y0xgl3fgs.cn-chengdu.personal.cr.aliyuncs.com/aura-grid/aura-grid-pro:latest"
GHCR_IMAGE="ghcr.io/24kbrother/aura-grid-pro:latest"

printf "%b\n" "\033[1;34m==============================================================\033[0m"
printf "%b\n" "\033[1;35m      Aura Grid Pro VIP专属极速无损自动更新程序       \033[0m"
printf "%b\n" "\033[1;34m==============================================================\033[0m"

# 保护性备份正版硬件指纹与授权凭证
if [ -d "./data" ]; then
    [ -f "./data/device.id" ] && cp ./data/device.id ./data/device.id.bak 2>/dev/null || true
    [ -f "./data/license.jwt" ] && cp ./data/license.jwt ./data/license.jwt.bak 2>/dev/null || true
fi

# 优先从阿里云极速通道拉取并打标
UPDATE_SUCCESS=false
printf "%b\n" "\n\033[1;34m[*] 默认启用阿里云国内极速通道拉取最新 PRO 镜像...\033[0m"
if docker pull "$ALIYUN_IMAGE"; then
    printf "%b\n" "\033[1;34m[*] 正在本地对齐官方容器标识...\033[0m"
    docker tag "$ALIYUN_IMAGE" "$GHCR_IMAGE"
    docker rmi "$ALIYUN_IMAGE" >/dev/null 2>&1 || true
    UPDATE_SUCCESS=true
else
    printf "%b\n" "\033[1;33m[WARNING] 阿里云通道拉取未成功，正在尝试官方 GitHub 链路...\033[0m"
    if docker compose pull 2>/dev/null || docker-compose pull; then
        UPDATE_SUCCESS=true
    fi
fi

if [ "$UPDATE_SUCCESS" != "true" ]; then
    printf "%b\n" "\033[0;31m[ERROR] 镜像拉取失败，请检查网络后重试。\033[0m"
    exit 1
fi

printf "%b\n" "\033[1;34m[*] 正在平滑更新重启容器 (保留原网络模式、授权与全部数据)...\033[0m"
if docker compose up -d 2>/dev/null || docker-compose up -d; then
    printf "%b\n" "\n\033[0;32m[SUCCESS] Aura Grid Pro 已成功更新并运行最新版本！\033[0m"
    
    # 自动安全释放旧镜像空间
    printf "%b\n" "\033[1;34m[*] 正在自动释放旧版本镜像空间...\033[0m"
    docker image prune -f >/dev/null 2>&1 || true
    printf "%b\n" "\033[0;32m[SUCCESS] 系统磁盘空间已自动优化清理完毕！\033[0m"
else
    printf "%b\n" "\033[0;31m[ERROR] 容器重启失败，请检查 docker-compose.yml。\033[0m"
    exit 1
fi
EOF
chmod +x "$WORKDIR/UPDATE_PRO.sh" 2>/dev/null || sudo chmod +x "$WORKDIR/UPDATE_PRO.sh"

# 12. 获取宿主机访问 IP 并输出部署成功看板
IP_ADDR=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
if [ -z "$IP_ADDR" ]; then
    IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
[ -z "$IP_ADDR" ] && IP_ADDR="127.0.0.1"

print_msg "\n${GREEN}==================================================${NC}"
print_msg "[SUCCESS] Aura Grid Pro 部署完成！"
print_msg "--------------------------------------------------"
print_msg "  访问入口: ${BLUE}http://${IP_ADDR}:8125${NC}"
print_msg "  安装目录: ${BLUE}${WORKDIR}${NC}"
if [ "$NET_CHOICE" = "1" ]; then
    print_msg "  网络模式: ${GREEN}Host 直通模式${NC} (mDNS 探活已激活，手机 App 局域网秒连)"
else
    print_msg "  网络模式: ${CYAN}Bridge 桥接模式${NC} (端口映射 8125，手机端请手动输入 IP)"
fi
print_msg "--------------------------------------------------"
print_msg " [升级维护指引] 国内网络环境强烈推荐使用极速更新脚本:"
print_msg "  • 本地更新命令: ${CYAN}bash ./UPDATE_PRO.sh${NC}"
print_msg "  • 远程一行更新: ${CYAN}curl -sSL http://auragrid.cn/UPDATE_PRO.sh | bash${NC}"
print_msg "  提示: 请妥善保管专属授权码，首次访问控制台时录入激活。"
print_msg "${GREEN}==================================================${NC}\n"
