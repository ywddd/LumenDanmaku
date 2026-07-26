# LumenDanmaku

弹幕客户端模块（Swift / SwiftUI）。

## 定位

一个**通用弹幕客户端库**，不绑定任何特定服务商：

- **不内置任何 API 凭证**，也不含任何服务商的默认地址
- 服务器地址与凭证由调用方传入（通常来自最终用户的设置界面）
- 未配置时不发起任何网络请求
- 本库不提供、不托管、不代理弹幕数据

## 免责声明

本库仅实现客户端协议，**不提供任何弹幕数据**。

使用者需自行向所选服务商申请接入凭证，并自行遵守该服务商的服务条款、
接入协议与配额限制。因使用本库访问第三方服务而产生的任何责任，
由使用者自行承担。

## 功能

- 签名鉴权：`Base64(SHA256(AppId + Timestamp + Path + AppSecret))`
- 按标题 + 集数匹配剧集并拉取弹幕
- SwiftUI 渲染层：
  - 贪心轨道分配，弹幕互不重叠，屏幕饱和时丢弃
  - 时间窗口二分查找，只渲染屏幕内条目（上限 120 条）
  - 位置由播放时钟推导而非定时器，seek / 变速后自动对齐

## 使用

```swift
import LumenDanmaku

// 1. 配置：值来自最终用户的设置界面，不要硬编码
DanmakuService.configure(
    server: userServerURL,      // 任意兼容 dandanplay 风格 API 的服务
    appId: userAppId,
    appSecret: userAppSecret
)

// 2. 加载
guard DanmakuService.isConfigured else { return }
let comments = try await DanmakuService.load(title: "剧名", episode: 3)

// 3. 渲染（叠在播放器画面之上）
DanmakuOverlay(
    comments: comments,
    time: playbackSeconds,      // 当前播放位置
    opacity: 0.85,
    fontSize: 16
)
```

### 关于播放时钟

`time` 建议以不低于 30Hz 的频率更新。多数播放器的进度回调只有 2~4Hz，
直接传入会让弹幕肉眼可见地跳动；实践中可用进度回调作为锚点，
再按墙钟插值到屏幕刷新率。

## 安装

Swift Package Manager：

```swift
.package(url: "https://github.com/ywddd/LumenDanmaku", from: "0.1.0")
```

要求 iOS 16+。

## 许可

MIT
