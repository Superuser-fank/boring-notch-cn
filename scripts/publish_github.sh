#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="${REPO_NAME:-boring-notch-cn}"
VISIBILITY="${VISIBILITY:-public}"
TAG="${TAG:-v2.7.3-cn.21}"
BRANCH="${BRANCH:-main}"
DMG_PATH="${DMG_PATH:-dist/BoringNotchCN-2.7.3-unnotarized.dmg}"
REMOTE_NAME="${REMOTE_NAME:-publish}"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh is not installed" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "error: gh is not logged in. Run: gh auth login --hostname github.com --git-protocol https --web --scopes repo" >&2
  exit 1
fi

if [ ! -f "$DMG_PATH" ]; then
  echo "error: DMG not found: $DMG_PATH" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree has uncommitted changes" >&2
  exit 1
fi

OWNER="$(gh api user --jq .login)"
REPO_FULL_NAME="$OWNER/$REPO_NAME"

if ! gh repo view "$REPO_FULL_NAME" >/dev/null 2>&1; then
  gh repo create "$REPO_FULL_NAME" "--$VISIBILITY" --source . --remote "$REMOTE_NAME" --description "Boring Notch CN fork with additional media-source support"
elif ! git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  git remote add "$REMOTE_NAME" "https://github.com/$REPO_FULL_NAME.git"
fi

git push -u "$REMOTE_NAME" "$BRANCH"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  git tag -f "$TAG"
else
  git tag "$TAG"
fi
git push -f "$REMOTE_NAME" "$TAG"

RELEASE_NOTES="$(mktemp)"
cat > "$RELEASE_NOTES" <<'NOTES'
## Boring Notch CN

Boring Notch CN 是 Boring Notch 的公开源码 fork，主品牌名不使用任何第三方服务名称。本版本增加了中文设置本地化、首次欢迎页非官方说明、菜单栏和刘海快捷菜单中文化、状态栏下载与安装入口、更新弹窗和提示卡中文化、媒体诊断、诊断信息复制和中文建议处理步骤、权限与安装自检、关于页下载与安装入口、网易云音乐和 QQ 音乐支持，优化音乐来源默认选择和展示顺序，补充中文月份/星期、农历、常见中国节日、2026 年中国法定休假和补班提示，并为文件架快速分享增加微信、QQ、钉钉、飞书快捷投递，补充隔空投送和系统分享菜单的中文显示与操作提示。

本版本继续优化中国用户日常可见界面和合规感知：首次欢迎页不再显示上游团队图片，也移除了残留的 Pro/升级入口代码，改为中文说明“面向中文用户的非官方 fork”，避免用户误认为这是 TheBoredTeam 官方发布或付费 Pro 版本。更新说明弹窗、TipKit 提示卡、刘海右键菜单、刘海快捷菜单、相机权限弹窗、电池弹层、HUD、下载提示和备用状态栏菜单已进一步中文化。关于页保留“下载与安装”，可直接打开 GitHub Release 下载页，也可复制解除 macOS Gatekeeper 拦截的 quarantine 命令。媒体诊断会根据播放器是否运行、macOS 正在播放数据是否来自所选来源、是否拿到歌曲数据，给出中文建议处理步骤；“复制诊断信息”也会带上这些建议，便于反馈 GitHub issue。诊断文本包含 App/系统版本、媒体来源、播放器状态、正在播放数据状态、控制能力和关键权限状态，但不包含歌曲名、歌手名、联系人或文件内容。

状态栏菜单现在增加“打开 Release 下载页”“打开 GitHub 项目”和“复制解除拦截命令”，方便用户从菜单栏直接处理下载、源码查看和首次打开被 Gatekeeper 拦截的问题；设置窗口标题也从英文改为“Boring Notch CN 设置”。

首次选择音乐来源和设置页音乐来源现在按“系统正在播放、网易云音乐、QQ 音乐、Apple Music、Spotify、YouTube Music”的顺序展示。对于系统通用“正在播放”不可用的 macOS 版本，新安装用户会优先使用本机已安装的网易云音乐或 QQ 音乐；如果都未安装，再回退到 Apple Music。音乐来源选择会显示“推荐”“已安装”“未检测到”“通用”等中文状态，方便用户判断本机适合选择哪个播放器。设置页也补充说明：网易云音乐和 QQ 音乐依赖 macOS 正在播放数据，支持基础播放控制。

文件架快速分享中，“隔空投送”会打开系统分享面板并需要用户选择接收设备；“系统分享菜单”会打开 macOS 分享菜单，由用户选择具体服务。微信、QQ、钉钉、飞书快捷投递会复制内容到剪贴板并打开对应应用，需要用户手动选择联系人和发送，不会自动发送消息。

### 安装

1. 下载 `BoringNotchCN-2.7.3-unnotarized.dmg`。
2. 打开 DMG，把 `Boring Notch CN.app` 拖到 `/Applications`。
3. 这个构建已签名但未 notarize，如首次打开被 Gatekeeper 拦截，可执行：

```bash
xattr -dr com.apple.quarantine "/Applications/Boring Notch CN.app"
```

### 开源与合规

- 许可证：GPLv3。完整许可证见 `LICENSE`。
- 对应源码：<https://github.com/Superuser-fank/boring-notch-cn/tree/v2.7.3-cn.21>
- 第三方声明：见 `THIRD_PARTY_NOTICES.md` 和 `THIRD_PARTY_LICENSES`。
- 这是非官方 fork，不是 TheBoredTeam 官方发布。
- 网易云音乐、QQ 音乐、Apple Music、Spotify、YouTube Music、微信、QQ、钉钉、飞书等名称仅用于说明兼容的媒体来源或可投递目标；本项目与这些第三方服务没有从属、授权、背书或赞助关系。
- 当前 DMG 为 Apple Development 签名，未进行 Developer ID notarization。
NOTES

if gh release view "$TAG" --repo "$REPO_FULL_NAME" >/dev/null 2>&1; then
  gh release edit "$TAG" --repo "$REPO_FULL_NAME" --title "Boring Notch CN 2.7.3-cn.21" --notes-file "$RELEASE_NOTES"
  gh release upload "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --clobber
else
  gh release create "$TAG" "$DMG_PATH" --repo "$REPO_FULL_NAME" --title "Boring Notch CN 2.7.3-cn.21" --notes-file "$RELEASE_NOTES"
fi

echo "Published: https://github.com/$REPO_FULL_NAME/releases/tag/$TAG"
