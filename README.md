# LumenDanmaku

SwiftUI 弹幕轨道渲染组件，仅包含本地数据模型与 UI。

本组件不负责从在线服务拉取、签名、缓存、转发或二次分发数据。

## 包含内容

| 包含 | 不包含 |
|---|---|
| `DanmakuComment` 数据模型 | 默认服务器地址 |
| `DanmakuOverlay` 滚动 / 顶部 / 底部布局 | AppId、AppSecret 和签名逻辑 |
| 轨道分配、seek 对齐、字号与透明度 | 网络客户端、代理、镜像和批量导出 |

## 集成原则

需要在线弹幕时，应由宿主应用：

1. 通过合法渠道获得数据访问权限。
2. 安全保管凭证，避免把 Secret 写入公开客户端代码。
3. 将已授权的数据映射为 `[DanmakuComment]`。
4. 把模型交给本组件渲染。

## 使用

```swift
import LumenDanmaku

let comments: [DanmakuComment] = loadAuthorizedComments()

DanmakuOverlay(
    comments: comments,
    time: playbackSeconds,
    opacity: 0.85,
    fontSize: 16
)
```

### 播放时钟

`time` 建议以不低于约 30Hz 更新。若播放器进度回调频率较低，可用回调作锚点，再按墙钟插值到屏幕刷新率。拖动、暂停、恢复或倍率变化后应重新锚定。

## 安装

Swift Package Manager：

```swift
.package(url: "https://github.com/ywddd/LumenDanmaku", from: "0.2.0")
```

也可以把本仓库作为本地 Swift Package加入工程。要求 iOS 16及以上。

## 与主应用的边界

[Lumen](https://github.com/ywddd/Lumen)可把已合法取得的弹幕数据传给本组件。在线服务地址、鉴权与网络请求不属于本开源包。

## 许可

MIT，详见 [LICENSE](LICENSE)。
