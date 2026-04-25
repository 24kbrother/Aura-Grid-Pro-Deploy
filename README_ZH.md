[English](README.md) | **中文**

# Aura Grid Pro - 商业级智能家居交互中台

> **极致性能 · 高级审美 · 工业级可靠性的核心中控**
> **当前版本**: v1.8.0-PRO

Aura Grid Pro (商业版代号 **Shadow Smart Home**) 是一个独立的高性能交互内核。它通过将设备接入层与交互层彻底解耦，为追求零延迟、顶级审美和工业级安全性的专业项目与高端极客而生。

---

## 核心特性

### 真正的零延迟体验
- **状态常驻内存**: 基于 NestJS 与 Socket.io，实现秒级的状态同步与反馈，彻底告别传统网页的加载焦虑。
- **10Hz 状态节流**: 采用专有的响应式隔离技术，即使全屋 1500+ 实体高频变化，UI 依然保持 60fps 的稳定渲染。

### 影院级视觉美学
- **毛玻璃 2.0**: 深度定制的毛玻璃体系与微动效库，让每一块屏幕都成为室内的艺术品。
- **动态环境模拟**: 基于 Canvas 的实时背景渲染，根据窗外天气与时间自动切换光影感。

### 工业级资产与安全
- **Aura Guard v1.1.0**: 企业级安全护航系统，支持 3 次尝试失败自动封禁 IP，并与 Node-RED 联动实现实时告警。
- **物理交互锁**: 专为挂墙式平板设计，有效防止误触及意外配置变更。
- **多楼层户型架构**: 支持无限楼层底图切换，拥有独立的热区逻辑与级联状态统计。

---

## 部署与升级

Aura Grid Pro 采用金镜像打包，完美兼容 AMD64 与 ARM64 架构。

### 一键部署与无损升级
执行以下统一脚本，系统会自动识别当前环境，执行全新安装或保留配置的无损升级。

```bash
curl -sSL https://raw.githubusercontent.com/24kbrother/Aura-Grid-Pro-Deploy/main/SETUP_PRO.sh | bash
```

---

## 帮助与支持
- **官方教程**: [Bilibili 空间](https://space.bilibili.com/1375690031)
- **商业合作**: 24k.brother@gmail.com

---
*Powered by Aura Grid Engine. Designed for the Future.*
