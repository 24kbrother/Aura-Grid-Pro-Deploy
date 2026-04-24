# 🧠 Aura Grid Pro - 商业级智能家居交互中台

> **极致性能 · 高级审美 · 工业级可靠性的核心中控**
> **Current Version**: v1.7.19-PRO

Aura Grid Pro (商业版代号 **Shadow Smart Home**) 不是另一个简单的 Home Assistant 仪表盘，而是一个**独立的中台式交互内核**。它采用了“影子系统 (Shadow System)”的架构理念，将设备的接入与交互层彻底解耦，为追求极致流畅度和审美体验的极客与专业工程项目而生。

---

## ✨ 核心特性 (Key Features)

### 🚀 真正意义上的“零延迟”体验
*   **状态常驻内存**：后端基于 NestJS + WebSocket 与 HA 同步，前端通过 Socket.io 实时推送，彻底告别 Lovelace 的加载焦虑。
*   **10Hz 状态节流**：独家 `ShallowRef` 响应式隔离技术，即使全屋 2000+ 实体高频变化，UI 依然稳如磐石。

### 🎨 影院级视觉美学
*   **Glassmorphism 2.0**：深度定制的毛玻璃背景体系与微动效库，让 iPad 变成家里的一件艺术品。
*   **60fps 动态背景**：根据窗外天气、时间动态渲染的 Canvas 环境背景，赋予系统“呼吸感”。

### 📱 专为 iPad 深度优化
*   **原生交互手势**：长按（Long Press）触发二级控制逻辑，完美对齐 iOS 使用直觉。
*   **PWA 沉浸式体验**：全屏无边框，隐藏所有浏览器干扰，点击主屏幕即可像 App 一样启动。

### 🏗️ 多楼层户型架构
*   **无限楼层支持**：每个楼层拥有独立底图（Floorplan）与热区交互逻辑。
*   **跨层统计**：从楼层专属到全局汇总的四级级联统计逻辑，一眼洞察全屋状态。

### 🔋 工业级资产管理
*   **电池管家**：自动扫描并智能排序低电量设备，红色微光告警。
*   **物理安全锁**：针对挂墙 iPad 设计的“交互锁”，防止误触与意外设置丢失。
*   **事件回忆录**：侧边栏流式呈现家庭全天动态日志。

---

## 🛠️ 部署指南 (Deployment)

Aura Grid Pro 采用金镜像打包，支持 ARM64/AMD64 架构。

### 1. 环境依赖
*   已安装 Docker & Docker Compose。
*   Home Assistant 服务器（已开启 Long-lived Access Token）。

### 2. 生产环境拉取
由于本版本为 Pro 专用，镜像存储于私有 GitHub Container Registry。请在 `docker-compose.yml` 中配置您的 GitHub PAT 后，执行以下命令进行热升级：

```bash
docker pull ghcr.io/24kbrother/aura-grid:latest
```

---

## 🔄 版本追踪
本仓库 (`Aura-Grid-Pro-Deploy`) 仅用于 Pro 版本的**发版通告**与**更新追踪**。

*   **版本检测**：大屏系统会自动通过 GitHub API 访问本仓库的 `Releases` 获取最新推送。
*   **更新日志**：请关注本仓库的 [Release List](https://github.com/24kbrother/Aura-Grid-Pro-Deploy/releases)。

---

## 🤝 帮助与支持
*   **官方教程**: [Bilibili 空间](https://space.bilibili.com/1375690031)
*   **商业合作**: 请通过仓库主页联系作者。

---
*Powered by Aura Grid Engine. Designed for the Future.*
