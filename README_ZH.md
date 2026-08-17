[English](README.md) | **中文**

# 🌌 Aura Grid Pro - 商业级智能家居交互中台

[![Version](https://img.shields.io/badge/version-v1.9.3--PRO-blue.svg?style=flat-shadow)](https://github.com/24kbrother/Aura-Grid-Pro-Deploy)
[![License](https://img.shields.io/badge/license-Commercial-red.svg?style=flat-shadow)](https://vlanhub.com/buy)
[![Status](https://img.shields.io/badge/status-Production--Ready-green.svg?style=flat-shadow)](https://vlanhub.com/buy)

> **极致性能 · 高级审美 · 工业级可靠性的核心中控**  
> **当前黄金版本**: `v1.9.3-PRO`

**Aura Grid Pro** (商业版代号 **Shadow Smart Home**) 是一个专为 Home Assistant 打造的高性能独立交互内核。它通过将设备接入层与交互层彻底解耦，为追求零延迟、顶级审美、多端自适应和工业级安全性的专业项目与高端极客而生。

> [!NOTE]
> **重要说明**：PRO 黄金镜像托管于公开免密镜像仓库（`ghcr.io/24kbrother/aura-grid-pro`）及阿里云国内极速镜像通道。拉取和升级无需配置任何私有 Token，实现秒级无损更新！

---

## 🚀 一键部署与无损升级

只需一行命令，即可在您的服务器（群晖 NAS、PVE、Unraid、Linux 服务器等）上启动全新安装或无损更新：

### ⚡ 国内加速更新 / 安装（推荐 · 阿里云极速通道）
```bash
curl -sSL http://auragrid.cn/PULL_PRO_FORM_ALIYUN.sh | bash
```

### 🌐 官方全量通道（一键安装 / 升级）
```bash
curl -sSL http://auragrid.cn/PRO.sh | bash
```

> 备用 GitHub 节点：
> ```bash
> curl -fsSL https://raw.githubusercontent.com/24kbrother/Aura-Grid-Pro-Deploy/main/SETUP_PRO.sh | bash
> ```

---

## 💎 核心旗舰特性

### 📱 1. 全新 iOS 26 竖屏中控 (Mobile Native Core)
- **视口智能感知分流**：移动端访问自动载入专属竖屏中控，横竖屏 100% 独立控制且互不干扰。
- **HomeKit 毛玻璃椭圆导航**：悬浮毛玻璃底部导航栏（Home / Rooms / Energy / Alerts），丝滑自适应。
- **房间实体长按拖拽排序**：支持前端长按进入编辑模式，实时同步与持久化拖拽后的房间实体列表。
- **拟物化微件矩阵**：完美旋转的黑胶唱片媒体播放器、高精度双色温控 Dial、倒三角水准仪热水器度盘。

### 🤖 2. 智能管家 (AI Agent) 深度联动
- **多模型生态接入**：原生适配 OpenAI 兼容、DeepSeek、Claude、通义千问 (Qwen)、MiniMax、豆包 (Doubao) 等主流大模型。
- **Fast-Path 毫秒意图引擎**：本地正则与模糊意图匹配，高频开关/调光控制无需消耗 Token 即可秒级直出。
- **HomeTools 全屋实体工具库**：深度绑定 Home Assistant 全量实体状态机，实现自然语言情景分析与精准设备调度。

### 🔌 3. MCP (Model Context Protocol) 智能硬件网关
- **开放标准 JSON-RPC 端点**：暴露 `/api/v1/mcp` 端点，完整支持 `initialize`、`tools/list`、`tools/call`、`ping` 协议。
- **开源智能硬件生态联动**：无缝对接小智 AI 桌面终端、ESP32 语音客户端，打破传统大屏与桌面硬件的交互壁垒。

### 💬 4. 即时通讯 (IM) 双渠道打通
- **企业微信自建应用 (WeCom)**：支持加解密验签、被动文本回复与主动语音/控制指令解析，随时随地管理全屋。
- **Telegram 机器人**：支持 Long Polling 长轮询与 Webhook 双模式，内置用户白名单鉴权与防死锁自旋恢复。

### 🛎️ 5. 智能门铃实时视频弹窗 & 滑动开锁
- **访客感知自动弹出**：门铃触发秒级唤起高保真监控视频浮窗（`rounded-2xl` 磨砂质感），视野纯净完整。
- **安全滑动开锁**：支持底部一键滑动开锁与开锁中状态防重入，告别误触。

### 🎨 6. 影院级视觉美学 & 国际化
- **毛玻璃拟态 2.0**：深度定制的透明磨砂质感与流体微动效，让每一块屏幕都成为室内的数字艺术品。
- **Canvas 动态环境模拟**：实时背景光影渲染，根据窗外天气与时间自动切换阴晴雨雪。
- **三语国际化与首发探测**：完整支持简体中文、繁体中文与英文，具备系统首选语言智能探测能力。

### 🏢 7. 多楼层户型无限架构
- **无限楼层平滑切换**：支持任意楼层底图切换，每楼层拥有独立热区逻辑与级联状态汇总。
- **物理安全防误触锁**：楼层切换器与画布微件增加安全锁功能，防止壁挂平板日常误触。

### 🛡️ 8. Aura Guard 工业级安全防御
- **3-Strikes 熔断机制**：1 小时内连续 3 次登录失败自动触发 24 小时 IP 级封锁。
- **硬件指纹 (HWID) 绑定**：RSA 硬件防伪签名与影子审计，保障中控唯一性。
- **Node-RED 自动化联动**：安全事件秒级同步至 Home Assistant 手机端推送告警。

---

## 🛒 商业授权与 VIP 权益

Aura Grid Pro 采用正版买断制授权体系，提供专属技术支持与持续功能演进。

👉 **[前往官方授权通道获取 Pro 授权](https://vlanhub.com/buy)**

---

## 📞 帮助与技术支持

- **官方视频教程**: [Bilibili 官方空间](https://space.bilibili.com/1375690031)
- **在线文档中心**: [开发者指南与文档](https://24kbrother.github.io/aura-grid-deploy/)
- **VIP 专属客服**: `china_24kbro` (微信)
- **商业合作邮箱**: [24k.brother@gmail.com](mailto:24k.brother@gmail.com)

---
*© 2026 Aura Grid & Aura Guard Security. 保留所有权利。*
