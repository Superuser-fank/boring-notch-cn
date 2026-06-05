# 发布指南

本文说明如何构建和发布 `Boring Notch CN`。

## 发布原则

- App 和 DMG 的主品牌名使用 `Boring Notch CN`，不把任何第三方服务名称放进主品牌。
- GitHub 源码仓库保持公开，满足 GPLv3 对应源码分发要求。
- Release 页面必须明确 GPLv3、源码链接、第三方声明和非官方 fork 身份。
- 网易云音乐等名称只在“支持的媒体来源”或第三方声明中出现。

## 构建要求

- Xcode 位于 `/Applications/Xcode.app`。
- 公开源码仓库：<https://github.com/Superuser-fank/boringnotch-netease>
- 本地有可用代码签名证书。

未 notarize 分发只需要 Apple Development 证书，但用户首次打开可能需要手动移除 quarantine。

标准公开分发建议使用付费 Apple Developer Program、Developer ID Application 证书，并完成 notarization。

## 构建未 notarize DMG

查看 Team ID：

```bash
security find-identity -v -p codesigning
```

构建：

```bash
DEVELOPMENT_TEAM=YOURTEAMID UNNOTARIZED=1 ./scripts/build_release.sh
```

DMG 会输出到 `dist/`，默认文件名类似：

```text
BoringNotchCN-2.7.3-unnotarized.dmg
```

用户安装后如被 Gatekeeper 拦截，可执行：

```bash
xattr -dr com.apple.quarantine "/Applications/Boring Notch CN.app"
```

## 构建 Developer ID DMG

```bash
DEVELOPMENT_TEAM=YOURTEAMID ./scripts/build_release.sh
```

## Notarize

推荐先把 notary 凭据保存到 Keychain：

```bash
xcrun notarytool store-credentials boringnotch-cn \
  --apple-id "you@example.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"
```

然后构建、提交 notarization 并 staple：

```bash
DEVELOPMENT_TEAM=YOURTEAMID NOTARIZE=1 NOTARY_PROFILE=boringnotch-cn ./scripts/build_release.sh
```

## GitHub Release

发布脚本会：

- 推送当前分支。
- 创建或更新 tag。
- 上传 DMG。
- 写入 Release notes，包含 GPLv3、源码链接和第三方声明。

示例：

```bash
TAG=v2.7.3-cn.2 ./scripts/publish_github.sh
```

## Sparkle 更新

自动更新目前保持禁用，直到本 fork 拥有自己的 Sparkle appcast 和 EdDSA key。不要复用上游 Boring Notch 的 appcast 或 public key。

## GPLv3

本项目基于 Boring Notch 修改，继续遵循 GPLv3。分发二进制时必须提供对应源码、保留许可证声明，并保留第三方项目的许可和署名。
