# 贡献说明

感谢你愿意改进 Boring Notch CN。这个仓库是 Boring Notch 的非官方中文 fork，目标是保持上游核心体验，同时补齐中文用户常见的安装、设置、媒体来源、日历和文件投递体验。

## 提交前确认

- 主品牌名保持 `Boring Notch CN`，不要把任何第三方服务名称放进 App 主品牌、仓库名或 Release 标题。
- 网易云音乐、QQ 音乐、微信、QQ、钉钉、飞书等名称只能用于说明兼容来源或投递目标。
- 新增第三方代码、图片、字体、音频或文案前，先确认许可证允许再分发，并更新 `THIRD_PARTY_NOTICES.md` 或 `THIRD_PARTY_LICENSES`。
- 不要提交 Apple ID、证书、notary 凭据、GitHub Token、崩溃日志中的个人信息或本地绝对隐私路径。

## 本地构建

需要 Xcode 16 或更新版本、macOS 14 或更新版本。

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project boringNotch.xcodeproj \
  -scheme boringNotch \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  build
```

构建未公证 DMG：

```bash
DEVELOPMENT_TEAM=YOURTEAMID UNNOTARIZED=1 ./scripts/build_release.sh
```

## Pull Request 要求

- 说明改动目的、影响范围和验证命令。
- UI 文案优先使用简体中文；第三方服务名保持其官方常用名称。
- 涉及设置页、首次引导、Release 或安装流程时，同步更新 README 或发布说明脚本。
- 涉及 GPLv3、第三方依赖、签名或分发方式时，同步检查 `RELEASE.md`、`SECURITY.md` 和第三方声明文件。
