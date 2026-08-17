# 🚀 Aura Grid Pro Release Notes

---

## 🌟 [v1.9.3-PRO] - 2026-08-16 (Current Golden Milestone)

### 🛎️ 1. 竖屏移动端 (Mobile) 门铃弹窗与设置 UI 手术级精修
- **门铃弹窗三行结构重塑**：重构门铃告警浮窗，主容器由笨重样式收敛为精致干练的 `rounded-2xl`（20px 工业磨砂圆角）。
  - **第 1 行（独立顶部 Header）**：琥珀色呼吸发光圆角图标 `Bell` + 标题“发现访客按门铃” + 摄像头名称与 `LIVE` 状态；右侧圆形关闭按钮 `X`。
  - **第 2 行（Camera 视频核心区）**：居于垂直居中核心区域，拥有独立 `rounded-xl` 容器，视野纯净完整；右下角微型化 `DOORBELL ACTIVE`（含呼吸红点）。
  - **第 3 行（底部操作 Footer）**：滑动解锁开门与 Loading 状态，移除了多余的硬编码文字。
- **设置菜单视觉圆角对齐**：移动端卡片默认类名对齐为 `rounded-2xl`，保持硬朗圆角质感；底部 HomeKit 风格椭圆导航栏自包含 `border-radius: 36px` 独立样式。

---

## [v1.9.1-pro] - 2026-08-04
- **Telegram 智能体长轮询并发死锁修复**：引入 `isCurrentlyPolling` 状态哨兵与异步自旋等待机制（Spin-Lock），确保配置重载时新旧轮询安全交接，并在 `try...finally` 中安全释放锁，保障 Telegram 机器人 7x24 小时稳定在线。

---

## [v1.9.0-pro] - 2026-07-29
- **MCP (Model Context Protocol) 智能网关集成**：暴露 `/api/v1/mcp` 端点，支持 `initialize`、`tools/list`、`tools/call`、`ping` 等全生命周期协议，无缝联动小智 AI 桌面终端与 ESP32 客户端。
- **AI Agent API Key 脱敏解耦**：重构配置直读机制，规避接口脱敏导致 AI 智能助手鉴权失效的问题。
- **竖屏登录防抖与 Option A 控温控光**：修复断线重连与身份过期处理逻辑；竖屏 Home 标签页优先响应楼层活跃灯光与温控实体。
- **后端能耗分析与温控自愈**：新增 Climate Auto Turn-on 辅助，优化离线能耗数据自愈机制。

---

## [v1.8.9-pro] - 2026-06-21
- **全新 iOS 26 竖屏中控架构合入**：单点视口感知分流，手机竖屏访问自动加载移动端专属界面。
- **HomeKit 椭圆胶囊导航**：底部毛玻璃胶囊导航栏（Home / Rooms / Energy / Alerts），激活态 Apple 橙（`#ff9f0a`）微光指示。
- **黑胶唱片媒体播放器**：Perfect Circle 旋转光盘，含真实 Spindle-hole 中孔材质与多源扬声器切换。
- **高阶温控度盘与热水器水准仪**：温控器 Dial 模式自适应霓虹色彩；热水器支持倒三角水准仪度盘和 0.5°C 精度增减。
- **后端 Area 房间数据持久化**：新增 Area 与 AreaEntity 级联存储，支持前端长按拖拽自由排序房间实体。

---

## [v1.8.6-pro] - 2026-05-31
- **公开免密镜像仓库分发**：全面迁移至公共镜像与阿里云极速通道，升级部署不再需要配置 GitHub Token。
- **三语国际化与首发探测**：补全英语、简体中文、繁体中文词条，支持首屏系统首选语言智能识别。

---

## 📦 版本信息 (Version Matrix)
- **Frontend**: `1.9.3` (`v1.9.3-PRO`)
- **Backend**: `1.9.3` (`v1.9.3-PRO`)
- **GHCR Image**: `ghcr.io/24kbrother/aura-grid-pro:latest` / `v1.9.3-pro`
- **Aliyun Image**: `crpi-z60uur6y0xgl3fgs.cn-chengdu.personal.cr.aliyuncs.com/aura-grid/aura-grid-pro:latest`
