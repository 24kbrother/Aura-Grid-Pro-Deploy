# 🚀 Shadow Smart Home 部署指南 (发布版)

感谢你使用 Shadow Smart Home 智能家居外挂中台系统！本指南将引导你如何在一分钟内完成全量容器化部署。

## 📋 环境要求
- **Docker** & **Docker Compose V2**
- 一个正在运行的 **Home Assistant** 实例（且在同一局域网下）

---

## ⚡ 快速部署步骤

### 1. 解压发布包
将 `.tar.gz` 文件上传到目标服务器，并执行：
```bash
# 解压文件 (以 v1.1.0 为例)
tar -xzf Aura-grid-v1.1.0-release.tar.gz

# 进入项目目录
cd Aura-grid-v1.1.0-release
```

### 2. 基础环境配置
进入交付文件夹并初始化你的环境变量：
```bash
cd deploy

# 复制配置文件模板
cp .env.example .env

# 编辑配置文件，设置你的访问密码
# 修改这行：ACCESS_PASSWORD=你的安全密码
nano .env
```

### 3. 一键启动集群
使用 Docker Compose 自动完成构建、组网和启动：
```bash
docker compose up -d
```
*提示：首次启动会自动下载镜像并进行前端编译，视网络情况可能需要 3-5 分钟。*

### 4. 首次使用与 HA 对接
1. 访问：`http://服务器IP:8125`
2. 使用你在 `.env` 中定义的密码登录。
3. 进入 **Settings (设置)** -> **System (系统)**。
4. 填入你的 **Home Assistant URL** 和 **Long-lived Access Token**，点击保存。
5. 系统会自动热重连并加载你的设备。

---

## 🛠️ 常用运维命令
- **查看实时日志**：`docker compose logs -f`
- **停止所有服务**：`docker compose down`
- **更新并重新构建**：`docker compose up -d --build`
- **完全重置数据**：`docker compose down -v`

---
*Shadow Smart Home — 重新定义你的智能家居仪表盘*
