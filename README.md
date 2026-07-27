# LumenDanmaku

**SwiftUI 弹幕轨道渲染组件（仅 UI）**

本仓库**只负责把已有弹幕画到屏幕上**，不负责从任何在线弹幕网络拉取、签名、缓存、转发或二次分发数据。

---

## 本仓库包含 / 不包含

| 包含 | **不包含** |
|------|------------|
| `DanmakuComment` 数据模型 | 任何默认服务器地址 |
| `DanmakuOverlay` 滚动/顶底布局 | AppId / AppSecret / 签名逻辑 |
| 轨道分配、seek 对齐、字号与透明度 | 网络客户端、代理、镜像、批量导出 |

> **不是**弹弹play开放弹幕网络（或其它弹幕服务）的官方/非官方 SDK。  
> **不是**可供任意应用复用的「在线弹幕接入模块」或转发网关。

---

## 设计意图

播放器若需要在线弹幕，应由**该应用自身**：

1. 向相应开放平台以**应用身份**完成审核与接入；  
2. 自行保管凭证（**推荐服务端中转**，切勿把 Secret 写入公开代码）；  
3. 将已获得的弹幕列表映射为 `[DanmakuComment]` 后交给本组件渲染。

本包刻意不实现网络层，以避免被误用为镜像、二次分发或未授权接入的基础设施。

---

## 使用

```swift
import LumenDanmaku

// comments 由宿主应用自行准备（本地文件 / 自建后端 / 该应用已授权的接口等）
let comments: [DanmakuComment] = /* ... */

DanmakuOverlay(
    comments: comments,
    time: playbackSeconds,   // 当前播放位置（建议 ≥30Hz 刷新或插值）
    opacity: 0.85,
    fontSize: 16
)
```

### 关于播放时钟

`time` 建议以不低于约 30Hz 更新。多数播放器进度回调只有 2–4Hz，直接传入会肉眼跳动；可用进度回调作锚点，再按墙钟插值到屏幕刷新率。

---

## 安装

Swift Package Manager：

```swift
.package(url: "https://github.com/ywddd/LumenDanmaku", from: "0.2.0")
```

要求 iOS 16+。

---

## 与 Lumen 播放器的关系

[Lumen](https://github.com/ywddd/CineLink)（流明）是独立的个人媒体库播放器应用。  
若 Lumen 使用在线弹幕，其网络与鉴权逻辑位于**该应用私有工程**内，**不在**本开源渲染包中。

---

## 变更说明（相对 0.1）

- **移除** `DanmakuService`（网络、签名、dandanplay 风格协议客户端）  
- **仅保留** 渲染与 `DanmakuComment` 模型  
- 文档明确：禁止将本仓库表述为通用在线弹幕 SDK / 转发模块  

---

## 许可

MIT
