# Boring Notch CN

Boring Notch CN 是 [Boring Notch](https://github.com/TheBoredTeam/boring.notch) 的公开源码 fork，面向中文用户做了设置页汉化，并增加了网易云音乐、QQ 音乐、中国日历信息、国内常用聊天应用快捷投递等本地体验优化。

本项目不是 TheBoredTeam 官方发布，也不是任何音乐或聊天服务的官方客户端、插件或合作项目。`网易云音乐`、`QQ 音乐`、`Apple Music`、`Spotify`、`YouTube Music`、`微信`、`QQ`、`钉钉`、`飞书` 等名称仅用于说明兼容的媒体来源或可投递目标；本项目与这些第三方服务没有从属、授权、背书或赞助关系。

## 下载

最新版本请到 GitHub Release 下载：

<https://github.com/Superuser-fank/boring-notch-cn/releases>

当前公开构建使用 Apple Development 证书签名，但未进行 Developer ID notarization。首次打开如果被 macOS Gatekeeper 拦截，安装后可以执行：

```bash
xattr -dr com.apple.quarantine "/Applications/Boring Notch CN.app"
```

## 主要变化

- 设置页简体中文本地化。
- 媒体来源增加网易云音乐和 QQ 音乐。
- 首次选择音乐来源和设置页音乐来源按中文用户常用顺序展示；在系统通用“正在播放”不可用时，会优先选择本机已安装的网易云音乐或 QQ 音乐。
- 媒体设置页增加诊断卡片、“复制诊断信息”和中文建议处理步骤，帮助检查播放器运行状态、正在播放数据、控制能力和关键权限状态。
- 通用设置页增加中文“权限与安装自检”，可查看辅助功能、日历、提醒事项、相机权限状态，并处理 Gatekeeper 拦截。
- 关于页增加“下载与安装”入口，可打开 GitHub Release 下载页并复制解除 macOS 拦截命令。
- 首次欢迎页显示中文非官方 fork 说明，避免误认为 TheBoredTeam 官方发布或付费 Pro 版本。
- 日历增加中文月份/星期、农历、常见中国节日、2026 年中国法定休假和补班提示，可在设置页关闭。
- 文件架快速分享增加微信、QQ、钉钉、飞书快捷投递，并补充隔空投送、系统分享菜单的中文显示和操作提示；聊天应用投递会复制到剪贴板并打开对应应用，需要手动选择联系人和发送。
- 首次启动引导、更新弹窗、提示卡、菜单栏、刘海快捷菜单、权限授权说明、软件更新、媒体控制布局、媒体来源选项、电池/HUD/下载提示、文件架空状态、文件架操作菜单和图片处理弹窗改为中文。
- 保留原版 Boring Notch 的刘海交互、媒体控制、日历、提醒事项、电池、HUD、文件架等能力。
- Release 包和 App 显示名使用 `Boring Notch CN`，主品牌名不包含第三方服务名称。

## 系统要求

- macOS 14 Sonoma 或更新版本。
- Apple Silicon 或 Intel Mac。
- 需要按功能授予辅助功能、日历、提醒事项等系统权限。

## 安装

1. 从 Release 页面下载 `BoringNotchCN-2.7.3-unnotarized.dmg`。
2. 打开 DMG。
3. 将 `Boring Notch CN.app` 拖入 `/Applications`。
4. 如果 macOS 阻止启动，执行上面的 `xattr` 命令后重新打开。

## 从源码构建

准备环境：

- Xcode 16 或更新版本。
- macOS 14 或更新版本。

构建未 notarize 的 DMG：

```bash
DEVELOPMENT_TEAM=YOURTEAMID UNNOTARIZED=1 ./scripts/build_release.sh
```

构建产物会输出到 `dist/`。

如果你有付费 Apple Developer Program 和 Developer ID Application 证书，可以参考 [RELEASE.md](./RELEASE.md) 进行 Developer ID 签名和 notarization。

## 开源许可证

本项目基于 Boring Notch 修改，继续遵循 GPLv3 发布。

- GPLv3 许可证全文：[LICENSE](./LICENSE)
- 对应源码：<https://github.com/Superuser-fank/boring-notch-cn/tree/v2.7.3-cn.19>
- 第三方声明：[THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)
- 第三方许可证原文：[THIRD_PARTY_LICENSES](./THIRD_PARTY_LICENSES)

如果你分发二进制包，需要同时提供对应源码、保留 GPLv3 许可声明，并保留第三方项目的许可和署名。

## 第三方项目

本项目直接或间接使用了多个开源项目，包括但不限于：

- Boring Notch：上游项目。
- MediaRemoteAdapter：用于 macOS 15.4+ 的 Now Playing 媒体信息适配。
- NotchDrop：原版 Shelf 功能的重要参考项目。
- Sparkle、Lottie、Defaults、KeyboardShortcuts、LaunchAtLogin、AsyncXPCConnection、Swift Collections、Swift Syntax、SwiftUI Introspect、SkyLightWindow、Pow、MacroVisionKit 等 Swift Package 依赖。

完整说明见 [THIRD_PARTY_NOTICES.md](./THIRD_PARTY_NOTICES.md)。
