# 第三方声明

`Boring Notch CN` 是 Boring Notch 的非官方 fork。本文件用于说明第三方项目、第三方服务名称和商标使用边界。

## 上游项目

- 上游项目：Boring Notch
- 上游仓库：<https://github.com/TheBoredTeam/boring.notch>
- 本 fork 源码：<https://github.com/Superuser-fank/boring-notch-cn>
- 本项目继续遵循 GPLv3，许可证全文见 [LICENSE](./LICENSE)。

## 主要第三方开源项目

本项目直接或间接使用了以下开源项目。完整许可证原文见 [THIRD_PARTY_LICENSES](./THIRD_PARTY_LICENSES)，Swift Package 版本锁定见 `boringNotch.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`。

- MediaRemoteAdapter：用于 macOS 15.4+ 的 Now Playing 媒体信息适配。
- NotchDrop：原版 Shelf 功能的重要参考项目。
- Sparkle：应用更新框架。
- Lottie：动画渲染。
- Defaults：用户偏好存储。
- KeyboardShortcuts：快捷键录制。
- LaunchAtLogin：登录项控制。
- AsyncXPCConnection：XPC 通信。
- Swift Collections、Swift Syntax、SwiftUI Introspect、SkyLightWindow、Pow、MacroVisionKit 等 Swift Package 依赖。

## 第三方服务和商标

`网易云音乐`、`Apple Music`、`Spotify`、`YouTube Music` 等名称仅用于说明 Boring Notch CN 可尝试读取或控制的媒体来源。

本项目不是上述服务的官方客户端、插件或合作项目；本项目与这些第三方服务及其权利人没有从属、授权、背书或赞助关系。所有相关名称、图标、商标和服务标识归各自权利人所有。

## 分发说明

如果你再分发本项目的二进制包，请同时提供对应源码，保留 GPLv3 许可证声明，并保留本文件和第三方许可证文件。
