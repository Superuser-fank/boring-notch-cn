# 支持说明

本项目是非官方社区 fork，不提供商业 SLA。请优先通过 GitHub Issues 反馈问题。

## 常见问题

### macOS 提示无法打开或已损坏

当前公开 DMG 使用 Apple Development 证书签名，但没有 Developer ID notarization。安装到 `/Applications` 后可以执行：

```bash
xattr -dr com.apple.quarantine "/Applications/Boring Notch CN.app"
```

然后重新打开应用。

### 网易云音乐或 QQ 音乐没有显示播放信息

这些来源依赖 macOS 正在播放数据。请先确认：

- 对应播放器已经打开。
- 已经开始播放一首歌。
- 设置页的媒体来源选择了正确播放器，或选择“系统正在播放”。
- 设置页“媒体诊断”里显示的 Bundle 是否来自当前播放器。

诊断信息不会包含歌曲名、歌手名、联系人或文件内容，可以复制后贴到 Issue。

### 权限相关问题

部分功能需要 macOS 权限：

- 辅助功能：媒体键/HUD/部分系统控制。
- 日历和提醒事项：日历视图。
- 相机：刘海镜像。

可以在设置页“通用”的“权限与安装自检”中检查。

## 反馈渠道

- Bug：<https://github.com/Superuser-fank/boring-notch-cn/issues/new/choose>
- 功能建议：<https://github.com/Superuser-fank/boring-notch-cn/issues/new/choose>
- Release 下载：<https://github.com/Superuser-fank/boring-notch-cn/releases>
